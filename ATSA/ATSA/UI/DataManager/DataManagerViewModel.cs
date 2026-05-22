using DevExpress.Mvvm;
using DevExpress.Mvvm.DataAnnotations;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading.Tasks;
using System.IO;
using XTA.Models;
using ATSA.UI.Models;
using ATSA.UI.Services;
using XTA.Core;
using XTA.Channels;
using XTA.XData.Interfaces;
using XTA.XData.Models;

namespace ATSA.UI.DataManager
{
    /// <summary>
    /// DataManager UI의 로직을 담당하는 ViewModel
    /// [v9.5] Command 이름과 메서드 이름을 일치시켜 바인딩 안정성 확보
    /// [v9.8.11] Status Transition Matrix 준수 (READY=0, EXECUTED=10, CLOSED=20)
    /// [v8.8] UI/UX Binding Standard 준수 (Lowercase bindings)
    /// </summary>
    public class DataManagerViewModel : ViewModelBase
    {
        private readonly XParameter _param;
        private readonly ATSA.UI.Services.IDialogService _dialogService;

        public ObservableCollection<BindableXSignal> SignalList { get; } = new();

        public List<int> CnoList { get; private set; } = new();
        public List<int> SnoList { get; } = Enumerable.Range(1, 50).ToList();
        public List<int> GnoList { get; } = Enumerable.Range(0, 51).ToList();
        
        public List<string> DirList { get; } = new() { "1:BUY", "2:SELL" };
        public List<string> TypeList { get; } = new() 
        { 
            "1:TRL (추적 진입)", 
            "2:LIMIT (지정가)", 
            "3:STOP (역지정가)",
            "9:MARKET (시장가)"
        };
        public List<string> LotTypeList { get; } = new()
        {
            "1:고정 로트",
            "2:배수 로트"
        };

        public List<string> XAEntryList { get; } = new() { "0:READY", "1:ACTIVE" };
        public List<string> XAExitList { get; } = new() { "0:READY", "1:ACTIVE", "2:COMPLETED", "3:ARCHIVE_READY" };
        public List<string> XEStatusList { get; } = new() 
        { 
            "0:READY", "1:PENDING", "10:EXECUTED", "20:CLOSED_SIG", 
            "21:CLOSED_TP", "23:CLOSED_SL", "24:CLOSED_MANUAL", "99:ERROR" 
        };
        
        private BindableXSignal? _selectedSignal;
        public BindableXSignal? SelectedSignal 
        { 
            get => _selectedSignal; 
            set 
            {
                if (_selectedSignal != null) _selectedSignal.PropertyChanged -= OnSelectedSignalPropertyChanged;
                if (SetProperty(ref _selectedSignal, value, nameof(SelectedSignal)))
                {
                    if (_selectedSignal != null) 
                    {
                        _selectedSignal.PropertyChanged += OnSelectedSignalPropertyChanged;
                        GenerateCurrentMessage();
                    }
                }
            }
        }

        private async void OnSelectedSignalPropertyChanged(object? sender, System.ComponentModel.PropertyChangedEventArgs e)
        {
            if (e.PropertyName == nameof(BindableXSignal.cno) || 
                e.PropertyName == nameof(BindableXSignal.gno) ||
                e.PropertyName == nameof(BindableXSignal.dir))
            {
                await ApplyChannelDefaultsAsync();
            }

            string[] triggerProps = { 
                nameof(BindableXSignal.cno), 
                nameof(BindableXSignal.sno), 
                nameof(BindableXSignal.symbol), 
                nameof(BindableXSignal.lot), 
                nameof(BindableXSignal.dir),
                nameof(BindableXSignal.price_signal),
                nameof(BindableXSignal.xa_exit) 
            };

            if (triggerProps.Contains(e.PropertyName))
            {
                GenerateCurrentMessage();
            }
        }

        private async Task ApplyChannelDefaultsAsync()
        {
            if (SelectedSignal == null) return;
            var gridRepo = XContext.Instance.GetService<IGridProfileRepository>();
            if (gridRepo == null) return;

            try
            {
                var merged = _param.GetMergedConfig(SelectedSignal.cno);
                var policy = (SelectedSignal.dir == XCode.BUY) ? merged.TradingOption.Buy : merged.TradingOption.Sell;
                if (policy != null)
                {
                    SelectedSignal.symbol = "GOLD#";
                    var strategy = policy.LotStrategyObj;
                    if (strategy != null)
                    {
                        if (strategy.Type == "Fixed")
                        {
                            SelectedSignal.SelectedLotType = "1:고정 로트";
                            SelectedSignal.lot = strategy.Value;
                        }
                        else if (strategy.Type == "Rate")
                        {
                            SelectedSignal.SelectedLotType = "2:배수 로트";
                            SelectedSignal.lot = strategy.Rate;
                        }
                    }
                    var entry = policy.EntryObj;
                    if (entry != null)
                    {
                        SelectedSignal.te_start = entry.TeStart;
                        SelectedSignal.te_step = entry.TeStep;
                        SelectedSignal.te_limit = entry.TeLimit;
                    }
                    var exit = policy.ExitObj;
                    if (exit != null)
                    {
                        SelectedSignal.ts_start = exit.TsStart;
                        SelectedSignal.ts_step = exit.TsStep;
                        SelectedSignal.tp = exit.TP;
                        SelectedSignal.sl = exit.SL;
                    }
                }

                var grid = await gridRepo.GetGridProfileAsync(SelectedSignal.cno, SelectedSignal.dir, SelectedSignal.gno);
                if (grid != null)
                {
                    SelectedSignal.lot = grid.lot;
                    SelectedSignal.tp = grid.tp;
                    SelectedSignal.sl = grid.sl;
                    SelectedSignal.te_start = grid.te_start;
                    SelectedSignal.te_step = grid.te_step;
                    SelectedSignal.ts_start = grid.ts_start;
                    SelectedSignal.ts_step = grid.ts_step;
                }
                SelectedSignal.RefreshAll();
            }
            catch (Exception ex)
            {
                _param.nlog.Warn(ex, "[DM] Failed to apply channel defaults via XConfig.");
            }
        }

        public DataManagerViewModel(ATSA.UI.Services.IDialogService? dialogService)
        {
            _param = (XContext.Instance.Parameter ?? new XParameter())!;
            _dialogService = dialogService ?? new DefaultDialogService();
            
            if (_param.Channels != null && _param.Channels.Any())
            {
                CnoList = _param.Channels.Values.SelectMany(l => l).Select(c => c.CNO).Distinct().OrderBy(c => c).ToList();
            }
            
            if (CnoList == null || !CnoList.Any()) CnoList = new List<int> { 3001, 3002 };

            SelectedSignal = new BindableXSignal();
            UpdateToDefaults(SelectedSignal, DateTime.Now.ToString("yyMMddHH"));

            _ = LoadSignals();
        }

        private bool _isForceInject = true;
        public bool IsForceInject
        {
            get => _isForceInject;
            set => SetProperty(ref _isForceInject, value, nameof(IsForceInject));
        }

        [Command]
        public async Task UpdateSignalStatus(object parameter)
        {
            if (SelectedSignal == null || string.IsNullOrEmpty(SelectedSignal.sid)) return;
            
            if (!int.TryParse(parameter?.ToString(), out int newXaExit)) return;

            int newXeStatus = SelectedSignal.xe_status;
            string prompt = "";
            
            switch (newXaExit)
            {
                case XCode.XA_ACTIVE: 
                    prompt = "Exit Request (1)"; 
                    break;
                case XCode.XA_CLOSED_COMPLETED: 
                    prompt = "Completed (2) 및 Closed (20)"; 
                    newXeStatus = (int)XCode.EaStatus.Closed_Signal; 
                    break;
                case XCode.XA_ARCHIVE_READY: 
                    prompt = "Archive Ready (3)"; 
                    break;
                default: return;
            }
            
            if (!_dialogService.Confirm($"신호 [{SelectedSignal.sid}]의 상태를 {prompt}로 변경하시겠습니까?", "상태 변경 확인")) return;

            try
            {
                var repo = XContext.Instance.SignalRepo;
                if (repo == null) return;

                // 1. xa_exit 업데이트
                await repo.UpdateXaStatusAsync(SelectedSignal.sid, newXaExit);
                
                // 2. Completed(2)일 경우 xe_status 강제 설정
                if (newXaExit == XCode.XA_CLOSED_COMPLETED)
                {
                    await repo.UpdateSignalStatusAsync(SelectedSignal.sid, newXeStatus, "Manual Completion");
                    _param.nlog.Debug($"[DM:UPDATE:XE] SID:{SelectedSignal.sid} forced to xe_status={newXeStatus} (Manual Completion)");
                }

                // 3. [v9.0] 수동 상태 변경 시 즉시 TTS 출력 (XSyncWorker 대기 없이 즉각 반응)
                var sound = XContext.Instance.Sound;
                if (sound != null)
                {
                    string soundCmd = newXaExit switch
                    {
                        XCode.XA_ACTIVE => "SID_CLOSE",
                        XCode.XA_CLOSED_COMPLETED => "SID_COMPLETED",
                        _ => ""
                    };
                    if (!string.IsNullOrEmpty(soundCmd)) 
                    {
                        _param.nlog.Debug($"[DM:UPDATE:TTS] Manually triggering {soundCmd} for SID:{SelectedSignal.sid} (CNO:{SelectedSignal.cno} Dir:{SelectedSignal.dir} SNO:{SelectedSignal.sno})");
                        sound.PlaySound(SelectedSignal, soundCmd);
                    }
                }
                
                _param.nlog.Debug($"[DM:UPDATE] Signal {SelectedSignal.sid} transitioned to xa_exit={newXaExit}, xe_status={newXeStatus}");

                // [Verification] DB 리로드하여 결과 확인
                await LoadSignals();
            }
            catch (Exception ex)
            {
                _param.nlog.Error(ex, "[DM:UPDATE] Failed to update signal status.");
                _dialogService.ShowError($"상태 변경 실패: {ex.Message}", "에러");
            }
        }

        [Command]
        public async Task ResetTeSettings()
        {
            if (SelectedSignal == null) return;
            try
            {
                var merged = _param.GetMergedConfig(SelectedSignal.cno);
                var policy = (SelectedSignal.dir == XCode.BUY) ? merged.TradingOption.Buy : merged.TradingOption.Sell;
                var entry = policy?.EntryObj;
                if (entry != null)
                {
                    SelectedSignal.te_start = entry.TeStart;
                    SelectedSignal.te_step = entry.TeStep;
                    SelectedSignal.te_limit = entry.TeLimit;
                    SelectedSignal.RefreshAll();
                    GenerateCurrentMessage();
                }
            }
            catch (Exception ex) { _param.nlog.Error(ex, "[DM] Failed to reset TE settings."); }
        }

        [Command]
        public async Task ResetTsSettings()
        {
            if (SelectedSignal == null) return;
            try
            {
                var merged = _param.GetMergedConfig(SelectedSignal.cno);
                var policy = (SelectedSignal.dir == XCode.BUY) ? merged.TradingOption.Buy : merged.TradingOption.Sell;
                var exit = policy?.ExitObj;
                if (exit != null)
                {
                    SelectedSignal.ts_start = exit.TsStart;
                    SelectedSignal.ts_step = exit.TsStep;
                    SelectedSignal.tp = exit.TP;
                    SelectedSignal.sl = exit.SL;
                    SelectedSignal.RefreshAll();
                    GenerateCurrentMessage();
                }
            }
            catch (Exception ex) { _param.nlog.Error(ex, "[DM] Failed to reset TS settings."); }
        }

        /// <summary>
        /// DB에서 신호 목록을 로드하여 그리드에 바인딩합니다.
        /// </summary>
        [Command]
        public async Task LoadSignals()
        {
            _param.nlog.Info("[DM:LOAD] LoadSignals Command Triggered.");
            var repo = XContext.Instance.SignalRepo;
            if (repo == null) return;

            try
            {
                var signals = await repo.GetSignalsByCnoAsync(0, 1000);
                
                void UpdateAction()
                {
                    SignalList.Clear();
                    foreach (var s in signals)
                    {
                        var bindable = BindableXSignal.FromModel(XTA.Models.XSignal.FromBase(s));
                        SignalList.Add(bindable);
                    }
                    if (SignalList.Any() && SelectedSignal == null) 
                    {
                        SelectedSignal = SignalList.First();
                    }
                    GenerateCurrentMessage();
                }

                if (System.Windows.Application.Current?.Dispatcher != null)
                {
                    if (System.Windows.Application.Current.Dispatcher.CheckAccess()) UpdateAction();
                    else await System.Windows.Application.Current.Dispatcher.InvokeAsync(UpdateAction);
                }
                else
                {
                    UpdateAction();
                }
            }
            catch (Exception ex)
            {
                _param.nlog.Error(ex, "[DM] Failed to load signals from database.");
            }
        }

        /// <summary>
        /// 현재 편집 중인 신호를 메시지 기반으로 DB에 주입합니다.
        /// [v9.8.11] 중복 체크 강화 및 초기 상태값 강제 설정 (EN=1, EX=0, ST=0)
        /// </summary>
        [Command]
        public async Task SaveChanges()
        {
            _param.nlog.Info("[DM:SAVE] SaveChanges Command Triggered.");
            if (SelectedSignal == null) return;
            
            var ctx = XContext.Instance;
            var repo = ctx.SignalRepo;
            var signalSvc = ctx.Signal;
            
            if (repo == null || signalSvc == null) return;

            try
            {
                GenerateCurrentMessage();
                string rawText = SelectedSignal.GeneratedMessage;
                
                if (string.IsNullOrEmpty(rawText))
                    throw new Exception("생성된 메시지가 비어있습니다.");

                var info = _param.GetChannelByCno(SelectedSignal.cno);
                if (info == null) throw new Exception($"CNO {SelectedSignal.cno} 채널 정보 없음.");

                var interpreter = _param.GetServices<XInterpreterBase>().FirstOrDefault(i => i?.Info?.CNO == info.CNO);
                if (interpreter == null) throw new Exception($"{info.Name} 해석기 없음.");

                var xdo = new XDataObject { CID = info.CID, CNO = info.CNO, Text = rawText, MsgId = -1, CMD = "DM_INJECTION" };
                var interpretedSignals = interpreter.Interpret(xdo);

                if (interpretedSignals == null || interpretedSignals.Count == 0)
                    throw new Exception("메시지 해석 실패.");

                var baseSignal = interpretedSignals.First();
                baseSignal.sno = SelectedSignal.sno;
                baseSignal.gno = SelectedSignal.gno;
                
                // [v9.9.1] Manual override from UI (Important for DataManager)
                baseSignal.te_limit = SelectedSignal.te_limit;
                baseSignal.te_start = SelectedSignal.te_start;
                baseSignal.te_step = SelectedSignal.te_step;
                baseSignal.ts_start = SelectedSignal.ts_start;
                baseSignal.ts_step = SelectedSignal.ts_step;
                baseSignal.sl = SelectedSignal.sl;
                baseSignal.tp = SelectedSignal.tp;

                var xdoEnrich = new XDataObject { Signal = baseSignal, Text = rawText, CID = info.CID, CNO = info.CNO, MsgId = -1, CMD = "DM_INJECTION" };
                var finalSignals = await signalSvc.PrepareSignalsAsync(xdoEnrich);

                if (finalSignals == null || finalSignals.Count == 0)
                    throw new Exception("신호 준비 과정에서 차단되었습니다 (정책 위반 등).");

                foreach (var final in finalSignals)
                {
                    // [v9.8.11] DB 중복 체크 (SID)
                    // IsForceInject가 true일 경우, 기존 상태(99 등)에 상관없이 덮어쓰기 위해 중복 체크 생략
                    if (!IsForceInject)
                    {
                        var existing = await repo.GetSignalBySidAsync(final.sid);
                        if (existing != null)
                        {
                            _dialogService.ShowError($"이미 존재하는 신호입니다 (SID: {final.sid})\n강제 주입 옵션을 체크하면 덮어쓰기가 가능합니다.", "중복 주입 방지");
                            return;
                        }
                    }
                    else
                    {
                        _param.nlog.Info($"[DM:SAVE] Force injecting SID: {final.sid}. 기존 데이터가 있으면 덮어씁니다.");
                    }

                    // 초기 상태 강제 설정
                    final.xa_entry = 1;
                    final.xa_exit = 0;
                    final.xe_status = 0;
                    final.xe_status_msg = "Manually Reset by DataManager";
                    
                    await repo.SaveSignalImmediateAsync(final, IsForceInject);
                    _param.nlog.Info(final.ToAuditString("DM-SAVE", $"Force={IsForceInject}, Msg: Manual Injection Success"));

                    // [v9.0] 신규 주입 시 즉시 TTS 출력 (xa_entry 0->1 전이 효과)
                    XContext.Instance.Sound?.PlaySound(final, "SIGNAL_RECEIVED");
                }

                // [Verification] DB 재로드
                await LoadSignals();
            }
            catch (Exception ex)
            {
                _param.nlog.Error(ex, "[DM:SAVE] Failed to save/inject signal.");
                _dialogService.ShowError($"주입 실패: {ex.Message}", "에러");
            }
        }

        [Command]
        public async Task AddNewEntrySignal()
        {
            var draft = CreateDraft();
            draft.xa_entry = 1; // [v10.33] New Entry defaults to ACTIVE (1)
            draft.SelectedXAEntry = "1:ACTIVE";
            draft.xa_exit = 0;
            draft.SelectedXAExit = "0:READY";
            draft.xe_status = 0;
            draft.SelectedXEStatus = "0:READY";
            draft.xe_status_msg = "New Entry Draft";
            SelectedSignal = draft;
            
            await ApplyChannelDefaultsAsync();
            GenerateCurrentMessage();
        }

        [Command]
        public async Task AddNewExitSignal()
        {
            var draft = CreateDraft();
            draft.xa_exit = 1; // [v9.8.9] 1: ACTIVE (청산 접수)
            draft.SelectedXAExit = "1:ACTIVE";
            draft.xe_status = 20; // [v9.8.9] 20: CLOSED_SIG (강제 종료)
            draft.SelectedXEStatus = "20:CLOSED_SIG";
            draft.xe_status_msg = "Manual Exit Injection";
            SelectedSignal = draft;

            await ApplyChannelDefaultsAsync();
            GenerateCurrentMessage();
        }

        private BindableXSignal CreateDraft()
        {
            var current = SelectedSignal;
            DateTime now = DateTime.Now;
            string yy = now.ToString("yyMMddHH");
            var draft = new BindableXSignal();

            if (current != null)
            {
                draft.cno = current.cno;
                draft.sno = current.sno;
                draft.gno = current.gno;
                draft.symbol = current.symbol;
                draft.dir = current.dir;
                draft.type = current.type;
                draft.lot = current.lot;
                draft.price_signal = current.price_signal;
                draft.SelectedDir = current.SelectedDir;
                draft.SelectedType = current.SelectedType;
                draft.SelectedLotType = current.SelectedLotType;
                draft.xa_entry = current.xa_entry;
                draft.SelectedXAEntry = current.SelectedXAEntry;
            }
            else
            {
                UpdateToDefaults(draft, yy);
            }

            draft.yymmddhh = yy;
            draft.updated = now;
            return draft;
        }

        [Command]
        public void GenerateCurrentMessage()
        {
            if (SelectedSignal == null) return;
            try
            {
                var info = _param.GetChannelByCno(SelectedSignal.cno);
                string channelFolder = string.Empty;

                // [v9.6] 명시적 해석기 기반 폴더 매핑
                var interpreter = _param.GetServices<XInterpreterBase>().FirstOrDefault(i => i != null && i.Info != null && i.Info.CNO == SelectedSignal.cno);
                channelFolder = (interpreter != null) ? interpreter.GetType().Name : (info?.Name ?? $"CH_{SelectedSignal.cno}");

                string baseDir = AppDomain.CurrentDomain.BaseDirectory;
                string[] possiblePaths = {
                    Path.Combine(baseDir, "Channels", channelFolder),
                    Path.Combine(baseDir, "XTA", "Channels", channelFolder),
                    Path.Combine(Directory.GetParent(baseDir)?.Parent?.Parent?.FullName ?? "", "ATSA", "XTA", "Channels", channelFolder)
                };
                string folderPath = possiblePaths.FirstOrDefault(Directory.Exists) ?? "";
                bool isExit = SelectedSignal.xa_exit == XCode.XA_ACTIVE;
                string fileName = isExit ? "Template_Exit.txt" : "Template_Entry.txt";
                string fullPath = !string.IsNullOrEmpty(folderPath) ? Path.Combine(folderPath, fileName) : "";
                string templateText = "";
                if (!string.IsNullOrEmpty(fullPath) && File.Exists(fullPath)) templateText = File.ReadAllText(fullPath);
                else templateText = isExit ? "[EXIT] {SYMBOL} {SNO}차 정리" : "[ENTRY] {SYMBOL} {DIR} {LOT} lot (Price: {PRICE})";
                string result = templateText
                    .Replace("{SNO}", SelectedSignal.sno.ToString())
                    .Replace("{SYMBOL}", SelectedSignal.symbol ?? "GOLD#")
                    .Replace("{DIR}", SelectedSignal.dir == 1 ? "BUY" : "SELL")
                    .Replace("{LOT}", SelectedSignal.lot.ToString("N2"))
                    .Replace("{PRICE}", SelectedSignal.price_signal.ToString("N2"))
                    .Replace("{TIME}", DateTime.Now.ToString("yyyy.MM.dd HH:mm:ss"));
                SelectedSignal.GeneratedMessage = result;
            }
            catch (Exception ex)
            {
                _param.nlog.Error(ex, "[DM:TEMPLATE] Failed to generate message.");
                SelectedSignal.GeneratedMessage = $"Error generating message:\n{ex.Message}";
            }
        }

        [Command]
        public async Task DeleteSelectedSignal()
        {
            if (SelectedSignal == null) return;
            if (string.IsNullOrEmpty(SelectedSignal.sid)) return;

            if (!_dialogService.Confirm($"신호 [{SelectedSignal.sid}]를 삭제하시겠습니까?", "신호 삭제 확인")) return;

            try
            {
                var repo = XContext.Instance.GetService<ISignalRepository>();
                if (repo == null) return;

                await repo.DeleteSignalAsync(SelectedSignal.sid);
                _param.nlog.Info($"[DM:DELETE] Signal {SelectedSignal.sid} deleted from DB.");

                await LoadSignals();
                //_dialogService.ShowInfo("신호가 삭제되었습니다.", "완료");
            }
            catch (Exception ex)
            {
                _param.nlog.Error(ex, "[DM:DELETE] Failed to delete signal.");
                _dialogService.ShowError($"삭제 실패: {ex.Message}", "에러");
            }
        }

        [Command]
        public async Task DeleteAllSignals()
        {
            if (!_dialogService.Confirm("모든 신호 레코드를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.", "전체 삭제 확인")) return;

            try
            {
                var repo = XContext.Instance.GetService<ISignalRepository>();
                if (repo == null) return;

                await repo.DeleteAllSignalsAsync();
                _param.nlog.Warn("[DM:DELETE] ALL signals deleted from DB by user.");

                await LoadSignals();
                //_dialogService.ShowInfo("모든 신호가 삭제되었습니다.", "완료");
            }
            catch (Exception ex)
            {
                _param.nlog.Error(ex, "[DM:DELETE] Failed to delete all signals.");
                _dialogService.ShowError($"전체 삭제 실패: {ex.Message}", "에러");
            }
        }

        private void UpdateToDefaults(BindableXSignal sig, string yy)
        {
            sig.yymmddhh = yy;
            if (CnoList.Any()) sig.cno = CnoList[0];
            if (SnoList.Any()) sig.sno = SnoList[0];
            if (GnoList.Any()) sig.gno = GnoList[0];
            sig.SelectedDir = DirList.FirstOrDefault() ?? "1:BUY";
            sig.SelectedType = TypeList.FirstOrDefault() ?? "1:TRL (추적 진입)";
            sig.SelectedLotType = LotTypeList.FirstOrDefault() ?? "1:고정 로트";
            sig.symbol = "GOLD#";
            sig.price_signal = 0.00;
            sig.lot = 0.01;
            sig.te_limit = 1000;
            sig.te_start = 500;
            sig.te_step = 100;
            sig.ts_start = 500;
            sig.ts_step = 100;
            sig.SelectedXAEntry = "1:ACTIVE"; // [v10.33] Default to ACTIVE (1)
            sig.SelectedXAExit = "0:READY";
            sig.SelectedXEStatus = "0:READY";
            sig.xa_entry = 1;
            sig.xa_exit = 0;
            sig.xe_status = 0;
            sig.updated = DateTime.Now;
            sig.RefreshAll();
        }
    }
}
