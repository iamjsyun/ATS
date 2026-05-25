using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using DevExpress.Data.Filtering;
using DevExpress.Xpo;
using XTA.XData.Models;
using XTA.Models;
using XTA.Core;

namespace XTA.Services
{
    /// <summary>
    /// [Partial] Methods: 동기화 세부 처리 로직 (Logic)
    /// </summary>
    public partial class XSyncWorker
    {
        private async Task ProcessErrorMonitoringAsync()
        {
            var repo = XContext.Instance.SignalRepo;
            if (repo == null) return;

            var errorSignals = await repo.GetErrorSignalsAsync();
            foreach (var s in errorSignals)
            {
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
                // [v14.24 Fix] Error 상태(99)인 경우 자동 청산 핸드셰이크(xa_exit=2)에서 제외.
                // 오직 실제 청산 상태(20~25)인 경우에만 완료 처리 진행.
                if (s.xe_status == 99) continue;

                // [v9.8.11] Matrix Alignment:
                // xe_status >= 20 (CLOSED) 인데 xa_exit가 아직 0(READY) 또는 1(ACTIVE)인 경우
                if (s.xa_exit == XCode.XA_RAW || s.xa_exit == XCode.XA_ACTIVE)
                {
                    string soundCmd = (s.sno == 0) ? "GROUP_CLOSE" : "SID_COMPLETED";
                    var domainSignal = s as Models.XSignal ?? Models.XSignal.FromBase(s);
                    XContext.Instance.Sound?.PlaySound(domainSignal, soundCmd);
                    nlog.Debug(s.ToAuditString("SYNC-COMP", $"xa_exit {s.xa_exit}->2, xe_status:{s.xe_status}"));
                    XContext.Instance.Gateway?.Log($"[{s.cno}] {s.sno}회차 청산 완료 확인 ({s.xa_exit}->2)");
                    
                    await repo.UpdateXaStatusAsync(s.sid, XCode.XA_CLOSED_COMPLETED);
                    nlog.Debug($"[SyncWorker:STATUS] SID:{s.sid} updated to XA_CLOSED_COMPLETED(2)");
                }
                else if (s.xa_exit == XCode.XA_CLOSED_COMPLETED)
                {
                    nlog.Debug(s.ToAuditString("SYNC-ARCH", "xa_exit 2->3"));
                    XContext.Instance.Gateway?.Log($"[{s.cno}] {s.sno}회차 데이터 이관 대기 확인 (2->3)");

                    await repo.UpdateXaStatusAsync(s.sid, XCode.XA_ARCHIVE_READY);
                    nlog.Debug($"[SyncWorker:STATUS] SID:{s.sid} updated to XA_ARCHIVE_READY(3)");
                }
            }
        }

        /// <summary>
        /// [v14.40] 진입 상태(xe_status=10) 및 중간 상태 모니터링 및 TTS 출력
        /// </summary>
        private async Task ProcessEntryMonitoringAsync()
        {
            var repo = XContext.Instance.SignalRepo;
            if (repo == null) return;

            var activeSignals = await repo.GetAllActiveSignalsAsync();
            foreach (var s in activeSignals)
            {
                // 1. 주문 접수 (xe_status=5)
                if (s.xe_status == (int)XCode.EaStatus.PendingPlaced)
                {
                    XContext.Instance.Sound?.PlaySound(s as Models.XSignal ?? Models.XSignal.FromBase(s), "ORDER_PLACED");
                }
                // 2. 진입 완료 (xe_status=10) && 아직 알림 안함 (xa_entry=1)
                else if (s.xe_status == (int)XCode.EaStatus.Executed && s.xa_entry == XCode.XA_ACTIVE)
                {
                    var domainSignal = s as Models.XSignal ?? Models.XSignal.FromBase(s);
                    nlog.Info(s.ToAuditString("SYNC-ENTRY", "Position Entry Detected. Triggering TTS."));
                    XContext.Instance.Sound?.PlaySound(domainSignal, "POSITION_ENTERED");
                    XContext.Instance.Gateway?.Log($"[{s.cno}] {s.sno}회차 포지션 진입 확인 (xa_entry 1->2)");

                    // xa_entry를 2(Confirmed)로 업데이트하여 중복 출력 방지
                    await repo.UpdateXaEntryAsync(s.sid, 2);
                }
                // 3. 진입 추적 가동 (xe_status=15)
                else if (s.xe_status == (int)XCode.EaStatus.IkTeStarted)
                {
                    XContext.Instance.Sound?.PlaySound(s as Models.XSignal ?? Models.XSignal.FromBase(s), "TE_TRIGGERED");
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

                if (await IsAlreadyRecoveredAsync(uow, msg.Oid))
                {
                    msg.Status = 1;
                    continue;
                }

                ReInjectToGateway(msg);
                UpdateMessageStatus(msg);
            }
            await uow.CommitChangesAsync();
        }

        private async Task<bool> IsAlreadyRecoveredAsync(UnitOfWork uow, int msgOid)
        {
            var active = await uow.FindObjectAsync<XpoSignal>(CriteriaOperator.Parse("msg_id = ?", msgOid));
            if (active != null) return true;

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
            msg.Status = (msg.RetryCount >= _maxRetryCount) ? 3 : 2;
        }
    }
}
