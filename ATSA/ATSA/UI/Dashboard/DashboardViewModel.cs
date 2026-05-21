using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Windows.Input;
using System.Windows.Threading;
using ATSA.UI.UCtrls;
using ATSA.UI.UCtrls.TGMsg;
using ATSA.UI.Models;
using DevExpress.Mvvm;
using XTA.Models;
using XTA.Core;
using XTA.Services.TelegramService;
using XTA.Interfaces;
using XTA.XData.Interfaces;

namespace ATSA.UI.Dashboard
{
    public class DashboardViewModel : ViewModelBase
    {
        private readonly XParameter _param;

        public UCXSignalViewModel Channel1001 { get; } = new UCXSignalViewModel("CNO 1001", 1001);
        public UCXSignalViewModel Channel1002 { get; } = new UCXSignalViewModel("CNO 1002", 1002);
        public UCXSignalViewModel Channel3001 { get; } = new UCXSignalViewModel("CNO 3001", 3001);
        public UCXSignalViewModel Channel3002 { get; } = new UCXSignalViewModel("CNO 3002", 3002);

        public UCXTGMsgViewModel MsgLog1001 { get; } = new UCXTGMsgViewModel(1001);
        public UCXTGMsgViewModel MsgLog1002 { get; } = new UCXTGMsgViewModel(1002);
        public UCXTGMsgViewModel MsgLog3001 { get; } = new UCXTGMsgViewModel(3001);
        public UCXTGMsgViewModel MsgLog3002 { get; } = new UCXTGMsgViewModel(3002);

        public ObservableCollection<XChannelStatus> EngineSummary { get; } = new();

        private int _refreshInterval = 1000;
        public int RefreshInterval 
        { 
            get => _refreshInterval; 
            set 
            {
                if (SetProperty(ref _refreshInterval, value, nameof(RefreshInterval)))
                {
                    if (_refreshTimer != null)
                        _refreshTimer.Interval = TimeSpan.FromMilliseconds(_refreshInterval);
                }
            }
        }

        private bool _isAutoRefresh = true;
        public bool IsAutoRefresh 
        { 
            get => _isAutoRefresh; 
            set 
            {
                if (SetProperty(ref _isAutoRefresh, value, nameof(IsAutoRefresh)))
                {
                    if (_isAutoRefresh) _refreshTimer?.Start();
                    else _refreshTimer?.Stop();
                }
            }
        }

        public ICommand StartServiceCommand { get; }
        public ICommand StopServiceCommand { get; }
        public ICommand ManualRefreshCommand { get; }

        private readonly Dictionary<int, UCXTGMsgViewModel> _msgLogByCno;
        private readonly Dictionary<int, UCXSignalViewModel> _signalChannels;
        private readonly DispatcherTimer _refreshTimer;

        public string DbPath 
        {
            get
            {
                var repo = XContext.Instance.GetService<ISignalRepository>();
                return repo?.DbPath ?? "N/A";
            }
        }

        public DashboardViewModel()
        {
            _param = XContext.Instance.Parameter;

            StartServiceCommand = new DelegateCommand(() => IsAutoRefresh = true);
            StopServiceCommand = new DelegateCommand(() => IsAutoRefresh = false);
            ManualRefreshCommand = new DelegateCommand(() => _ = RefreshAllSignalsAsync());

            _msgLogByCno = new Dictionary<int, UCXTGMsgViewModel>
            {
                { 1001, MsgLog1001 }, { 1002, MsgLog1002 },
                { 3001, MsgLog3001 }, { 3002, MsgLog3002 }
            };

            _signalChannels = new Dictionary<int, UCXSignalViewModel>
            {
                { 1001, Channel1001 }, { 1002, Channel1002 },
                { 3001, Channel3001 }, { 3002, Channel3002 }
            };

            System.Diagnostics.Debug.WriteLine($"[DashboardViewModel:CTOR] Initializing Dashboard ViewModel");

            // 엔진 이벤트 구독
            SubscribeToEngineEvents();

            // 타이머 초기화
            _refreshTimer = new DispatcherTimer();
            _refreshTimer.Interval = TimeSpan.FromMilliseconds(RefreshInterval);
            _refreshTimer.Tick += (s, e) => _ = RefreshAllSignalsAsync();
            if (IsAutoRefresh) _refreshTimer.Start();
        }

        private async System.Threading.Tasks.Task RefreshAllSignalsAsync()
        {
            var ctx = XContext.Instance;
            var repo = ctx.SignalRepo;
            var gateway = ctx.Gateway;

            // 1. 개별 채널 신호 로드
            foreach (var channel in _signalChannels.Values)
            {
                await channel.LoadSignalsAsync();
            }

            // 2. Engine Summary (채널별 요약) 갱신
            if (repo != null)
            {
                var summaryList = new List<XChannelStatus>();
                
                // 등록된 채널들 순회
                foreach (var list in _param.Channels.Values)
                {
                    foreach (var chInfo in list)
                    {
                        // [v9.6] 유튜브 채널(2001, 2002)은 요약 정보에서 제외
                        if (chInfo.CNO == 2001 || chInfo.CNO == 2002) continue;

                        var status = new XChannelStatus { CNO = chInfo.CNO, Name = chInfo.Name };
                        
                        // DB에서 해당 채널의 전체 신호 조회
                        var signals = await repo.GetSignalsByCnoAsync(chInfo.CNO, 5000);
                        
                        // BUY 통계
                        var buys = signals.Where(s => s.dir == 1).ToList();
                        status.BuyOrderCount = buys.Count(s => s.xe_status < 10);
                        status.BuyOrderLot = buys.Where(s => s.xe_status < 10).Sum(s => s.lot);
                        status.BuyPositionCount = buys.Count(s => s.xe_status >= 10 && s.xe_status < 20);
                        status.BuyPositionLot = buys.Where(s => s.xe_status >= 10 && s.xe_status < 20).Sum(s => s.lot);

                        // SELL 통계
                        var sells = signals.Where(s => s.dir == 2).ToList();
                        status.SellOrderCount = sells.Count(s => s.xe_status < 10);
                        status.SellOrderLot = sells.Where(s => s.xe_status < 10).Sum(s => s.lot);
                        status.SellPositionCount = sells.Count(s => s.xe_status >= 10 && s.xe_status < 20);
                        status.SellPositionLot = sells.Where(s => s.xe_status >= 10 && s.xe_status < 20).Sum(s => s.lot);

                        summaryList.Add(status);
                    }
                }

                System.Windows.Application.Current?.Dispatcher.Invoke(() =>
                {
                    EngineSummary.Clear();
                    foreach (var s in summaryList.OrderBy(x => x.CNO)) EngineSummary.Add(s);
                });
            }
        }

        private void SubscribeToEngineEvents()
        {
            var ctx = XContext.Instance;
            
            // 1. 텔레그램 메시지 실시간 수신 이벤트 (XTelegram)
            var tg = ctx.GetService<XTelegram>();
            if (tg != null)
            {
                tg.MessageReceived += xdo => OnTelegramMessageReceived(xdo);
                System.Diagnostics.Debug.WriteLine("[Dashboard] Subscribed to XTelegram.MessageReceived");
            }

            // 2. 신호 주입/업데이트 이벤트 (XGatewayService)
            if (ctx.Gateway != null)
            {
                ctx.Gateway.SignalAddedOrUpdated += xdo => OnSignalUpdated(xdo);
                System.Diagnostics.Debug.WriteLine("[Dashboard] Subscribed to XGateway.SignalAddedOrUpdated");
            }
        }

        private void OnTelegramMessageReceived(XDataObject xdo)
        {
            if (xdo == null || !_msgLogByCno.ContainsKey(xdo.CNO)) return;

            System.Windows.Application.Current?.Dispatcher.Invoke(() =>
            {
                var msgVM = _msgLogByCno[xdo.CNO];
                // [v9.6] 채널명 제외하고 순수 수신 메시지(Raw)만 표시하도록 변경
                msgVM.Messages.Insert(0, BindableXTgMessage.FromModel(new XTA.Models.XTgMessage { 
                    Time = DateTime.Now, 
                    Text = xdo.Text ?? "(Empty Message)"
                }));
                if (msgVM.Messages.Count > 500) msgVM.Messages.RemoveAt(msgVM.Messages.Count - 1);
            });
        }

        private void OnSignalUpdated(XDataObject xdo)
        {
            if (xdo?.Signal == null || !_signalChannels.ContainsKey(xdo.CNO)) return;

            System.Windows.Application.Current?.Dispatcher.Invoke(() =>
            {
                var channel = _signalChannels[xdo.CNO];
                // XTA의 순수 모델을 UI용 Bindable 모델로 변환하여 처리
                var bindable = BindableXSignal.FromModel(xdo.Signal);
                channel.UpdateSignal(bindable);
            });
        }
    }
}
