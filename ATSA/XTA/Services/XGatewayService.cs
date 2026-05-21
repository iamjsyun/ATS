using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using XTA.Channels;
using XTA.Infrastructure.Data;
using XTA.XData.Interfaces;
using XTA.XData.Models;
using static XTA.XData.Models.XCode;
using XTA.Models;
using XTA.Interfaces;
using XTA.Core;
using FluentSeq;
using System.Threading.Tasks;
using System.Threading.Channels;
using System.Threading;

namespace XTA.Services
{
    /// <summary>
    /// 텔레그램 메시지와 인터프리터 사이의 관문 역할을 하는 서비스.
    /// [Thread-Safe] 생산자-소비자 패턴 및 FluentSeq 상태 머신을 적용함.
    /// </summary>
    public class XGatewayService : XChannelObject, IXGatewayService
    {
        public ConcurrentDictionary<string, XDataObject> PendingSignals { get; } = new();

        public event Action<XDataObject>? SignalAddedOrUpdated;
        public event Action<string>? SignalRemoved;

        private ISequence<XHubState> _msgSeq = null!;
        private readonly ConcurrentDictionary<string, TaskCompletionSource<bool>> _saveWaiters = new();
        
        private readonly Channel<XDataObject> _msgChannel = Channel.CreateUnbounded<XDataObject>();
        private readonly Channel<XDataObject> _interpretedChannel = Channel.CreateUnbounded<XDataObject>();
        private CancellationTokenSource? _cts;
        
        // 메시지 소비자 컨텍스트 (msgSeq는 순차 처리가 적합하므로 필드 유지 가능하나, 안전을 위해 로컬 권장)
        private XDataObject? _currentXdo;
        private XChannelInfo? _currentInfo;

        public XGatewayService(XParameter param) : base(param, new XChannelInfo(0, 0, "GATEWAY_HUB", "SYSTEM"))
        {
            InitSequences();
        }

        private void InitSequences()
        {
            // 1. 메시지 라우팅 시퀀스 (순차 처리 유지)
            // [v9.0] Idle 상태로 안전하게 시작 (생성자 크래시 방지)
            _msgSeq = new FluentSeq<XHubState>().Create(XHubState.Idle)
                .ActivateDebugLogging(nlog)
                .ConfigureState(XHubState.Idle)
                .ConfigureState(XHubState.Received)
                    .OnEntry(() => {
                        if (_currentXdo == null) return;
                        if (_currentInfo != null) {
                            _currentXdo.CNO = _currentInfo.CNO;
                            _ = XContext.Instance.Data?.SaveMessageAsync(_currentXdo);
                            this.Log($"[TG] {_currentInfo.Name} 채널 메시지 수신 (MsgId:{_currentXdo.MsgId})");
                        }
                    })
                .ConfigureState(XHubState.Interpreted)
                    .TriggeredBy(() => _currentInfo != null && _currentInfo.Type.ToUpper() == "TRADE" && _currentInfo.CNO != 2001 && _currentInfo.CNO != 2002)
                        .WhenInState(XHubState.Received)
                    .OnEntry(() => {
                        var interpreter = param.GetService<XInterpreterBase>(i => i.Info.CNO == _currentInfo!.CNO);
                        if (interpreter != null) interpreter.EnqueueMessage(_currentXdo!);
                        else nlog.Warn($"[Gateway:FAIL] Interpreter not found for CNO:{_currentInfo!.CNO}");
                    })
                .ConfigureState(XHubState.Failed)
                    .TriggeredBy(() => _currentInfo == null || (_currentInfo.Type.ToUpper() != "TRADE" || _currentInfo.CNO == 2001 || _currentInfo.CNO == 2002))
                        .WhenInState(XHubState.Received)
                .Builder().DisableValidation().Build();

            // [v9.8] XpoSqliteService 이벤트 구독
            var db = param.GetService<XpoSqliteService>();
            if (db != null)
            {
                db.SignalSaved += (s, e) => {
                    if (_saveWaiters.TryRemove(e.Sid, out var tcs))
                    {
                        tcs.TrySetResult(true);
                    }
                };
            }
        }

        /// <summary>
        /// [v9.8] 개별 신호 처리 프로세스 (Parallel & Stateless)
        /// </summary>
        private async Task ProcessSignalAsync(XDataObject xdo)
        {
            if (xdo == null) return;

            // [MDLC] 상관관계 ID 주입 (분산 추적용)
            using (NLog.ScopeContext.PushProperty("TraceId", xdo.MsgId))
            {
                // 로컬 컨텍스트 캡슐화 (Race Condition 원천 차단)
                List<Models.XSignal>? preparedSignals = null;
                var ctx = XContext.Instance;

                ISequence<string> seq = null!;
                seq = new FluentSeq<string>().Create("Idle")
                    .ConfigureState("Idle")
                    .ConfigureState("Enrich")
                        .OnEntry(async () => {
                            preparedSignals = (ctx.Signal != null) ? await ctx.Signal.PrepareSignalsAsync(xdo) : null;
                            if (preparedSignals == null || preparedSignals.Count == 0) {
                                nlog.Warn($"[Gateway:DROP] No valid signals for MsgId:{xdo.MsgId}");
                                seq.SetState("Idle");
                            } else {
                                seq.SetState("Persistence");
                            }
                        })
                    .ConfigureState("Persistence")
                        .OnEntry(async () => {
                            if (preparedSignals == null) { seq.SetState("Idle"); return; }
                            foreach (var s in preparedSignals) {
                                if (s.cmd == XCode.CLOSE) continue;
                                var signalXdo = new XDataObject { Signal = s, MsgId = xdo.MsgId, Text = xdo.Text, CID = xdo.CID, CNO = xdo.CNO };
                                PendingSignals.AddOrUpdate(s.sid, signalXdo, (k, v) => signalXdo);
                                if (ctx.Data != null) await ctx.Data.SaveSignalAsync(s);
                            }
                            seq.SetState("Execution");
                        })
                    .ConfigureState("Execution")
                        .OnEntry(async () => {
                            if (preparedSignals == null) { seq.SetState("Idle"); return; }
                            try {
                                foreach (var s in preparedSignals) {
                                    if (s.cmd == XCode.CLOSE && ctx.Liquidation != null) 
                                        await ctx.Liquidation.ProcessLiquidationAsync(s, xdo.MsgId);
                                }
                                seq.SetState("Notification");
                            } catch (Exception ex) {
                                nlog.Error(ex, $"[Gateway:EXEC-FAIL] Execution failed. Triggering compensation.");
                                seq.SetState("RollbackPersistence");
                            }
                        })
                    .ConfigureState("Notification")
                        .OnEntry(() => {
                            if (preparedSignals == null) { seq.SetState("Idle"); return; }
                            foreach (var s in preparedSignals) {
                                if (s.cmd == XCode.CLOSE) continue;
                                var signalXdo = new XDataObject { Signal = s, MsgId = xdo.MsgId, Text = xdo.Text, CID = xdo.CID, CNO = xdo.CNO };
                                ctx.Sound?.PlaySound(s, "SIGNAL_RECEIVED");
                                SignalAddedOrUpdated?.Invoke(signalXdo);
                            }
                            seq.SetState("Verify");
                        })
                    .ConfigureState("Verify")
                        .OnEntry(async () => {
                            if (preparedSignals == null) { seq.SetState("Idle"); return; }
                            var repo = ctx.SignalRepo;
                            
                            foreach (var s in preparedSignals)
                            {
                                if (s.cmd == XCode.CLOSE) continue;

                                // [v9.8] 이벤트 기반 비동기 검증 (RaW 고도화)
                                var tcs = new TaskCompletionSource<bool>();
                                _saveWaiters[s.sid] = tcs;

                                try 
                                {
                                    // 타임아웃 5초 설정 (DB 부하 고려)
                                    if (await Task.WhenAny(tcs.Task, Task.Delay(5000)) == tcs.Task)
                                    {
                                        nlog.Info($"[Gateway:VERIFY] Persistence Success via Event: {s.sid}");
                                    }
                                    else
                                    {
                                        // 타임아웃 발생 시 직접 DB 확인
                                        var verified = await repo!.GetSignalBySidAsync(s.sid);
                                        if (verified != null) nlog.Info($"[Gateway:VERIFY] Persistence Success via DB Check: {s.sid}");
                                        else {
                                            nlog.Error($"[Gateway:VERIFY] Persistence FAIL (Not found in DB) for {s.sid}. Triggering Rollback.");
                                            seq.SetState("RollbackPersistence");
                                            return;
                                        }
                                    }
                                }
                                finally { _saveWaiters.TryRemove(s.sid, out _); }
                            }
                            seq.SetState("Idle");
                        })
                    .ConfigureState("RollbackPersistence")
                        .OnEntry(async () => {
                            var repo = ctx.SignalRepo;
                            if (preparedSignals != null && repo != null) {
                                foreach (var s in preparedSignals) {
                                    if (s.cmd == XCode.CLOSE) continue;
                                    await repo.DeleteSignalAsync(s.sid);
                                    PendingSignals.TryRemove(s.sid, out _);
                                    nlog.Warn($"[Gateway:ROLLBACK] Signal {s.sid} removed from Memory/DB due to downstream failure.");
                                }
                            }
                            seq.SetState("Idle");
                        })
                    .Builder().DisableValidation().Build();

                // 시퀀스 실행 (Finally 보장)
                try 
                {
                    seq.SetState("Enrich");
                    int safety = 0;
                    while (!seq.IsInState("Idle") && safety++ < 10) await seq.RunAsync();
                }
                catch (Exception ex) 
                { 
                    nlog.Error(ex, $"[Gateway:PROC] Signal processing failed for MsgId:{xdo.MsgId}"); 
                    
                    // [v9.0] 예외 발생 시 해당 신호(존재 시)를 에러 상태로 마킹
                    if (preparedSignals != null && ctx.SignalRepo != null)
                    {
                        foreach (var s in preparedSignals)
                        {
                            await ctx.SignalRepo.UpdateSignalStatusAsync(s.sid, 99, $"[GATEWAY-ERR] {ex.Message}");
                        }
                    }
                }
                finally { seq.SetState("Idle"); }
            }
        }

        public void EnqueueRawMessage(XDataObject xdo) => OnRawMessageReceived(xdo);

        public void Log(string message) => nlog.Info($"[LOG:HUB] {message}");

        private bool _isStarted = false;
        private readonly HashSet<int> _processedMsgIds = new();

        public override void Start()
        {
            lock (_processedMsgIds) { if (_isStarted) return; _isStarted = true; }
            _cts = new CancellationTokenSource();
            Task.Run(() => ProcessMessageQueueAsync(_cts.Token));
            Task.Run(() => ProcessInterpretedQueueAsync(_cts.Token));
        }

        public override void Stop() { _cts?.Cancel(); _isStarted = false; }

        private void OnRawMessageReceived(XDataObject xdo)
        {
            if (xdo == null) return;
            lock (_processedMsgIds) {
                if (_processedMsgIds.Contains(xdo.MsgId)) return;
                _processedMsgIds.Add(xdo.MsgId);
                if (_processedMsgIds.Count > 1000) _processedMsgIds.Remove(_processedMsgIds.First());
            }
            if (!_msgChannel.Writer.TryWrite(xdo)) nlog.Error($"[Gateway:ERROR] Msg queue full: MsgId={xdo.MsgId}");
        }

        private async Task ProcessMessageQueueAsync(CancellationToken ct)
        {
            while (await _msgChannel.Reader.WaitToReadAsync(ct)) {
                while (_msgChannel.Reader.TryRead(out var xdo)) {
                    try {
                        _currentXdo = xdo;
                        _currentInfo = param.GetChannel(xdo.CID);
                        _msgSeq.SetState(XHubState.Received);
                        int safety = 0; while (_msgSeq.IsInState(XHubState.Received) && safety++ < 2) _msgSeq.Run();
                    } catch (Exception ex) { nlog.Error(ex, $"[Gateway:MSG] Error: MsgId={xdo?.MsgId}"); }
                }
            }
        }

        public async Task ProcessInterpretedSignalAsync(XDataObject xdo)
        {
            if (xdo == null) return;
            if (!_interpretedChannel.Writer.TryWrite(xdo)) nlog.Error($"[Gateway:ERROR] Interpreted queue full: SID={xdo.Signal?.sid}");
            await Task.CompletedTask;
        }

        private async Task ProcessInterpretedQueueAsync(CancellationToken ct)
        {
            while (await _interpretedChannel.Reader.WaitToReadAsync(ct)) {
                while (_interpretedChannel.Reader.TryRead(out var xdo)) {
                    // [v9.8] 병렬 비차단 처리 (Parallel Processing)
                    _ = Task.Run(() => ProcessSignalAsync(xdo), ct);
                }
            }
        }

        public XDataObject? GetNextSignal()
        {
            if (PendingSignals.IsEmpty) return null;
            var firstKey = PendingSignals.Keys.FirstOrDefault();
            if (firstKey != null && PendingSignals.TryRemove(firstKey, out var xdo)) { SignalRemoved?.Invoke(firstKey); return xdo; }
            return null;
        }
    }
}
