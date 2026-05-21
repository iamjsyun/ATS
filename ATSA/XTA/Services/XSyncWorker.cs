using DevExpress.Data.Filtering;
using DevExpress.Xpo;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using XTA.Infrastructure.Data;
using XTA.XData.Interfaces;
using XTA.XData.Models;
using XTA.Models;
using XTA.Core;
using FluentSeq;

namespace XTA.Services
{
    /// <summary>
    /// 누락된 메시지 복구 및 동기화를 담당하는 워커 (FluentSeq 고도화 버전)
    /// </summary>
    public class XSyncWorker : XObject
    {
        private Timer? _syncTimer;
        private readonly int _intervalSeconds = 10;
        private readonly int _lookbackMinutes = 60;
        private readonly int _maxRetryCount = 5;
        private int _isBusyInt = 0;

        private ISequence<string> _syncSeq = null!;
        private SyncContext _ctx = new();

        public XSyncWorker(XParameter param) : base(param) { InitSequence(); }

        private void InitSequence()
        {
            _syncSeq = new FluentSeq<string>()
                .Create("Idle")
                .ActivateDebugLogging(nlog)

                // 1. Idle 상태: 대기
                .ConfigureState("Idle")

                // 2. Prepare 상태: 컨텍스트 초기화 및 대상 채널 확인
                .ConfigureState("Prepare")
                    .OnEntry(() => {
                        _ctx = new SyncContext();
                        var db = param.GetService<XpoSqliteService>();
                        if (db == null) { _syncSeq.SetState("Idle"); return; }
                        
                        _ctx.DbService = db;
                        _ctx.TradeCnos = param.Channels.Values
                            .SelectMany(l => l)
                            .Where(c => c.Type.Equals("TRADE", StringComparison.OrdinalIgnoreCase))
                            .Select(c => c.CNO).ToList();

                        if (_ctx.TradeCnos.Count == 0) _syncSeq.SetState("Idle");
                        else _syncSeq.SetState("Query"); // 자동 전이
                    })

                // 3. Query 상태: DB에서 미처리 메시지 조회
                .ConfigureState("Query")
                    .OnEntry(() => {
                        if (_ctx.DbService == null) { _syncSeq.SetState("Idle"); return; }

                        using var uow = new UnitOfWork(_ctx.DbService.GetLayer());
                        var lookback = DateTime.Now.AddMinutes(-_lookbackMinutes);
                        var criteria = CriteriaOperator.And(
                            new InOperator("CNO", _ctx.TradeCnos),
                            CriteriaOperator.Parse("Status IN (0, 2) AND Time > ? AND RetryCount < ?", lookback, _maxRetryCount)
                        );

                        _ctx.PendingMessages = new XPCollection<XpoTgMessage>(uow, criteria).ToList();
                        
                        if (_ctx.PendingMessages.Count == 0) _syncSeq.SetState("Idle");
                        else _syncSeq.SetState("Recover"); // 자동 전이
                    })

                // 4. Recover 상태: 메시지 복구 실행 (v9.7 SRP 리팩토링)
                .ConfigureState("Recover")
                    .OnEntry(async () => {
                        if (_ctx.DbService == null || _ctx.PendingMessages.Count == 0) { _syncSeq.SetState("MonitorClose"); return; }

                        nlog.Info($"[SyncWorker] Found {_ctx.PendingMessages.Count} unprocessed messages. Recovering...");
                        
                        await ProcessRecoveryAsync();
                        
                        _syncSeq.SetState("MonitorClose"); // 완료 후 MonitorClose로 전이
                    })

                // 5. [v9.8.5] MonitorClose 상태: EA 청산 완료 모니터링 및 TTS 알림
                .ConfigureState("MonitorClose")
                    .OnEntry(async () => {
                        await ProcessCloseMonitoringAsync();
                        _syncSeq.SetState("MonitorError"); // 완료 후 MonitorError로 전이
                    })

                // 6. [v9.9] MonitorError 상태: xe_status=99 에러 신호 자동 복구
                .ConfigureState("MonitorError")
                    .OnEntry(async () => {
                        await ProcessErrorMonitoringAsync();
                        _syncSeq.SetState("Idle");
                    })

                .Builder().DisableValidation().Build();
        }

        private async Task ProcessErrorMonitoringAsync()
        {
            var repo = XContext.Instance.SignalRepo;
            if (repo == null) return;

            var errorSignals = await repo.GetErrorSignalsAsync();
            foreach (var s in errorSignals)
            {
                // [Recovery Rule] 에러 발생 후 5분이 경과한 신호는 자동으로 Ready(0)로 리셋하여 재시도 유도
                if (s.updated < DateTime.Now.AddMinutes(-5))
                {
                    nlog.Warn($"[SyncWorker:ERROR_RECOVERY] SID:{s.sid} found in error state (99) for >5m. Resetting to Ready(0) for retry.");
                    XContext.Instance.Gateway?.Log($"[{s.cno}] 에러 신호 자동 복구 시도 (SID:{s.sid})");
                    
                    await repo.UpdateSignalStatusAsync(s.sid, (int)XCode.EaStatus.Ready, "[AUTO-RECOVERY] Resetting from status 99 after timeout.");
                }
            }
        }

        private async Task ProcessCloseMonitoringAsync()
        {
            var repo = XContext.Instance.SignalRepo;
            if (repo == null) return;
            
            var closedSignals = await repo.GetClosedSignalsAsync();
            foreach (var s in closedSignals)
            {
                if (s.xa_exit == XCode.XA_ACTIVE || s.xa_exit == XCode.XA_RAW)
                {
                    // 1. [v9.0] 1 -> 2 단계 전이: 청산 완료 확인 TTS
                    string soundCmd = (s.sno == 0) ? "GROUP_CLOSE" : "SID_COMPLETED";
                    var domainSignal = s as Models.XSignal ?? Models.XSignal.FromBase(s);
                    XContext.Instance.Sound?.PlaySound(domainSignal, soundCmd);
                    nlog.Debug($"[SyncWorker:TTS] Triggered {soundCmd} for SID:{s.sid} (xa_exit 1->2)");
                    XContext.Instance.Gateway?.Log($"[{s.cno}] {s.sno}회차 청산 완료 확인 (1->2)");
                    
                    // 2. 청산 완료 상태(2)로 마킹
                    await repo.UpdateXaStatusAsync(s.sid, XCode.XA_CLOSED_COMPLETED);
                    nlog.Debug($"[SyncWorker:STATUS] SID:{s.sid} updated to XA_CLOSED_COMPLETED(2)");
                }
                else if (s.xa_exit == XCode.XA_CLOSED_COMPLETED)
                {
                    // 3. [v9.0] 2 -> 3 단계 전이 (TTS 제외, 로그만 기록)
                    nlog.Debug($"[SyncWorker:STATUS] SID:{s.sid} transition to XA_ARCHIVE_READY(3) started.");
                    XContext.Instance.Gateway?.Log($"[{s.cno}] {s.sno}회차 데이터 이관 대기 확인 (2->3)");

                    // 4. 이관 대기 상태(3)로 마킹
                    await repo.UpdateXaStatusAsync(s.sid, XCode.XA_ARCHIVE_READY);
                    nlog.Debug($"[SyncWorker:STATUS] SID:{s.sid} updated to XA_ARCHIVE_READY(3)");
                }
            }
        }

        private async Task ProcessRecoveryAsync()
        {
            if (_ctx.DbService == null) return;

            using var uow = new UnitOfWork(_ctx.DbService.GetLayer());
            foreach (var msgXpo in _ctx.PendingMessages)
            {
                var msg = uow.GetObjectByKey<XpoTgMessage>(msgXpo.Oid);
                if (msg == null) continue;

                // [SRP: Validation] 신호 중복 생성 방지 가드
                if (await IsAlreadyRecoveredAsync(uow, msg.Oid))
                {
                    msg.Status = 1; // 처리 완료로 마킹
                    continue;
                }

                // [SRP: Execution] 게이트웨이 파이프라인으로 재투입
                ReInjectToGateway(msg);

                // [SRP: Persistence] 재시도 횟수 및 상태 업데이트
                UpdateMessageStatus(msg);
            }
            await uow.CommitChangesAsync();
        }

        private async Task<bool> IsAlreadyRecoveredAsync(UnitOfWork uow, int msgOid)
        {
            // 1. 활성 신호 테이블 검색
            var active = await uow.FindObjectAsync<XpoSignal>(CriteriaOperator.Parse("msg_id = ?", msgOid));
            if (active != null) return true;

            // 2. 히스토리 신호 테이블 검색 (이미 청산/아카이브된 경우)
            var history = await uow.FindObjectAsync<XpoSignalHistory>(CriteriaOperator.Parse("msg_id = ?", msgOid));
            return history != null;
        }

        private void ReInjectToGateway(XpoTgMessage msg)
        {
            var xdo = new XDataObject
            {
                CID = msg.CID,
                CNO = msg.CNO,
                Text = msg.Text,
                Timestamp = msg.Time,
                MsgId = msg.Oid,
                CMD = "RECOVERY_SYNC"
            };
            XContext.Instance.Gateway?.EnqueueRawMessage(xdo);
        }

        private void UpdateMessageStatus(XpoTgMessage msg)
        {
            msg.RetryCount++;
            msg.Status = (msg.RetryCount >= _maxRetryCount) ? 3 : 2; // 3: 실패확정, 2: 재시도중
        }

        public override void Start()
        {
            _syncTimer = new Timer(OnSyncTimerCallback, null, TimeSpan.FromSeconds(10), TimeSpan.FromSeconds(_intervalSeconds));
            nlog.Trace($"[SyncWorker] Sequential worker started.");
        }

        public override void Stop() { _syncTimer?.Dispose(); nlog.Trace("[SyncWorker] Sequential worker stopped."); }

        private void OnSyncTimerCallback(object? state)
        {
            if (Interlocked.CompareExchange(ref _isBusyInt, 1, 0) != 0) return;
            try
            {
                // 시퀀스 시작 (Idle -> Prepare)
                _syncSeq.SetState("Prepare");
                
                // 전이 조건이 충족될 때까지 최대 5회 Run (순차 실행 보장)
                int safety = 0;
                while (!_syncSeq.IsInState("Idle") && safety++ < 5)
                {
                    _syncSeq.Run();
                }
            }
            catch (Exception ex) { nlog.Error(ex, "[SyncWorker:SEQ] Execution failed."); }
            finally { Interlocked.Exchange(ref _isBusyInt, 0); }
        }

        private class SyncContext { 
            public XpoSqliteService? DbService { get; set; } 
            public List<int> TradeCnos { get; set; } = new(); 
            public List<XpoTgMessage> PendingMessages { get; set; } = new(); 
        }
    }
}
