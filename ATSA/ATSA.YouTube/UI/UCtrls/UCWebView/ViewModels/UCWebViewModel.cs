using ATSA.YouTube.Models;
using ATSA.YouTube.Services;
using DevExpress.Mvvm;
using System;
using System.Collections.ObjectModel;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Input;
using System.Windows.Threading;
using XTA.Models;
using XTA.Core;
using XTA.Interfaces;
using XTA.Channels;
using XTA.XData.Models;
using System.Linq;

namespace ATSA.YouTube.UI.UCtrls.UCWebView.ViewModels;

public class UCWebViewModel : BindableBase
{
    private ILiveStreamService? _streamService;
    private IOcrEngineService? _ocrService;
    private readonly OcrStabilityFilter _filter;
    private readonly DispatcherTimer _timer;
    private int _isProcessing = 0; // 0: Idle, 1: Processing

    public XChannelConfig? ChannelConfig { get; set; }
    public string ChannelName { get; set; } = "Channel";
    public string Url { get; set; } = "https://www.youtube.com";
    public int CaptureInterval { get; set; } = 3000;

    private bool _isLivePlaying;
    public bool IsLivePlaying
    {
        get => _isLivePlaying;
        private set { _isLivePlaying = value; RaisePropertyChanged(nameof(IsLivePlaying)); }
    }

    private bool _isCaptureRunning;
    public bool IsCaptureRunning
    {
        get => _isCaptureRunning;
        private set { _isCaptureRunning = value; RaisePropertyChanged(nameof(IsCaptureRunning)); }
    }

    public ObservableCollection<string> Logs { get; } = new();

    public ICommand PlayLiveCommand { get; }
    public ICommand StopLiveCommand { get; }
    public ICommand StartCaptureCommand { get; }
    public ICommand StopCaptureCommand { get; }
    public ICommand CaptureCommand { get; }

    public RoiConfig CurrentRoi { get; set; } = new RoiConfig();

    public UCWebViewModel()
    {
        _filter = new OcrStabilityFilter();

        PlayLiveCommand = new DelegateCommand(async () => await OnPlayLive(), () => !IsLivePlaying);
        StopLiveCommand = new DelegateCommand(async () => await OnStopLive(), () => IsLivePlaying);
        StartCaptureCommand = new DelegateCommand(OnStartCapture, () => IsLivePlaying && !IsCaptureRunning);
        StopCaptureCommand = new DelegateCommand(OnStopCapture, () => IsCaptureRunning);
        CaptureCommand = new DelegateCommand(async () => await OnCapture(), () => IsLivePlaying);

        _timer = new DispatcherTimer();
        _timer.Tick += async (s, e) => await ProcessPipeline();
    }

    public void SetServices(ILiveStreamService stream, IOcrEngineService ocr)
    {
        _streamService = stream;
        _ocrService = ocr;
        AddLog("Services Bound.");
    }

    private async Task OnPlayLive()
    {
        if (_streamService == null) return;
        await _streamService.LoadStream(Url);
        IsLivePlaying = true;
        AddLog("Live Stream Started.");
    }

    private async Task OnStopLive()
    {
        if (_streamService == null) return;
        await _streamService.LoadStream("about:blank");
        IsLivePlaying = false;
        if (IsCaptureRunning) OnStopCapture();
        AddLog("Live Stream Stopped.");
    }

    private void OnStartCapture()
    {
        _timer.Interval = TimeSpan.FromMilliseconds(CaptureInterval);
        _timer.Start();
        IsCaptureRunning = true;
        AddLog("OCR Capture Started.");
    }

    private void OnStopCapture()
    {
        _timer.Stop();
        IsCaptureRunning = false;
        AddLog("OCR Capture Stopped.");
    }

    private async Task OnCapture()
    {
        AddLog("Manual Capture Triggered.");
        await ProcessPipeline();
    }

    private async Task ProcessPipeline()
    {
        if (_streamService == null || _ocrService == null) return;

        // [v9.0] 중복 실행 방지 (Drop-Frame 메커니즘)
        if (Interlocked.CompareExchange(ref _isProcessing, 1, 0) != 0)
        {
            AddLog("Pipeline Busy... Frame Skipped.");
            return;
        }

        try
        {
            using (var ms = await _streamService.CaptureSnapshotAsync())
            {
                if (ms == null) return;

                string rawText = await _ocrService.ExtractTextAsync(ms, CurrentRoi);
                if (string.IsNullOrEmpty(rawText)) return;

                string? validatedText = _filter.Process(rawText, out double confidence);
                if (validatedText != null)
                {
                    AddLog($"★ [Validated] {validatedText!} (Conf: {confidence * 100:F0}%)");
                    
                    // [v9.6] 신호 처리 프로세스 브릿징
                    await ProcessValidatedText(validatedText);
                }
                else
                {
                    // AddLog($"[Raw] {rawText} (Conf: {confidence * 100:F0}%)");
                }
            }
        }
        catch (Exception ex)
        {
            AddLog($"Error: {ex.Message}");
        }
        finally
        {
            Interlocked.Exchange(ref _isProcessing, 0);
        }
    }

    private async Task ProcessValidatedText(string text)
    {
        if (ChannelConfig == null) return;

        try
        {
            // 1. XDataObject 생성
            var xdo = new XDataObject
            {
                CNO = ChannelConfig.CNO,
                CID = ChannelConfig.ChannelId,
                Text = text,
                MsgId = (int)(DateTime.Now.Ticks % 1000000), // 순환 MsgId
                Timestamp = DateTime.Now
            };

            // 2. 해당 채널의 인터프리터 획득
            var interpreter = XContext.Instance.Parameter.GetService<XInterpreterBase>(i => i.Info.CNO == ChannelConfig.CNO);
            if (interpreter == null)
            {
                AddLog($"[SIGNAL:WARN] No Interpreter found for CNO:{ChannelConfig.CNO}");
                return;
            }

            // 3. 해석 실행 (List<XSignal> 반환)
            var signals = interpreter.Interpret(xdo);
            if (signals == null || signals.Count == 0)
            {
                // AddLog($"[SIGNAL:SKIP] Interpretation resulted in no signals.");
                return;
            }

            // 4. Gateway를 통해 처리 (Enrich, Persistence, Execution 등 일련의 시퀀스 실행)
            var gateway = XContext.Instance.GetService<IXGatewayService>();
            if (gateway != null)
            {
                foreach (var s in signals)
                {
                    var signalXdo = new XDataObject { 
                        Signal = s, 
                        MsgId = xdo.MsgId, 
                        Text = xdo.Text, 
                        CID = xdo.CID, 
                        CNO = xdo.CNO 
                    };
                    await gateway.ProcessInterpretedSignalAsync(signalXdo);
                    AddLog($"★ [SIGNAL:SENT] {(s.dir == 1 ? "BUY" : "SELL")} @ {s.price_signal} (SNO:{s.sno})");
                }
            }
        }
        catch (Exception ex)
        {
            AddLog($"[SIGNAL:ERROR] {ex.Message}");
        }
    }

    private void AddLog(string message) => Logs.Insert(0, $"[{DateTime.Now:HH:mm:ss}] {message}");
}


