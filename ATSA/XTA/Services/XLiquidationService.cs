using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using NLog;
using XTA.Infrastructure.Data;
using XTA.Core;
using XTA.Interfaces;
using XTA.Models;
using XTA.XData.Interfaces;
using XTA.XData.Models;
using FluentSeq;

namespace XTA.Services
{
    /// <summary>
    /// 청산 로직(Active Liquidation / Forced Liquidation)을 담당하는 서비스
    /// [v9.9] FluentSeq 기반으로 상태 및 제어 흐름 분리 (Check -> Search -> Execute -> Notify)
    /// </summary>
    public class XLiquidationService : IXLiquidationService
    {
        private static readonly Logger nlog = LogManager.GetCurrentClassLogger();

        private record LiquidationContext(
            Models.XSignal Signal,
            int MsgId,
            bool IsAlreadyProcessed = false,
            List<XTA.XData.Models.XSignal>? Targets = null,
            Models.XSignal? ForcedSignal = null
        );

        public async Task ProcessLiquidationAsync(Models.XSignal signal, int msgId)
        {
            nlog.Info($"[Liquidation] >>> Starting Close Process for CNO:{signal.cno} SNO:{signal.sno} (MsgId:{msgId})");

            var ctx = new LiquidationContext(signal, msgId);
            ISequence<string> seq = null!;

            seq = new FluentSeq<string>().Create("Idle")
                .ConfigureState("Idle")
                .ConfigureState("CheckProcessed")
                    .OnEntry(async () => {
                        var processed = await IsAlreadyProcessedAsync(ctx.Signal);
                        ctx = ctx with { IsAlreadyProcessed = processed };
                        if (ctx.IsAlreadyProcessed) seq.SetState("End");
                        else seq.SetState("SearchTargets");
                    })
                .ConfigureState("SearchTargets")
                    .OnEntry(async () => {
                        var targets = await SearchLiquidationTargetsAsync(ctx.Signal);
                        ctx = ctx with { Targets = targets };
                        if (ctx.Targets.Any()) seq.SetState("ActiveLiquidation");
                        else seq.SetState("ForcedLiquidation");
                    })
                .ConfigureState("ActiveLiquidation")
                    .OnEntry(async () => {
                        await ExecuteActiveLiquidationAsync(ctx.Targets!, ctx.MsgId);
                        seq.SetState("NotifyActive");
                    })
                .ConfigureState("ForcedLiquidation")
                    .OnEntry(async () => {
                        var forced = await ExecuteForcedLiquidationAsync(ctx.Signal, ctx.MsgId);
                        ctx = ctx with { ForcedSignal = forced };
                        seq.SetState("NotifyForced");
                    })
                .ConfigureState("NotifyActive")
                    .OnEntry(() => {
                        NotifyLiquidation(ctx.Signal, ctx.Targets!.Count);
                        seq.SetState("End");
                    })
                .ConfigureState("NotifyForced")
                    .OnEntry(() => {
                        NotifyLiquidation(ctx.ForcedSignal!, 0, isForced: true);
                        seq.SetState("End");
                    })
                .ConfigureState("End")
                .Builder().DisableValidation().Build();

            // [v9.0] 빌드 후 명시적 상태 전이
            seq.SetState("CheckProcessed");

            try
            {
                int safety = 0;
                while (!seq.IsInState("End") && safety++ < 10)
                {
                    await seq.RunAsync();
                }
            }
            catch (Exception ex)
            {
                nlog.Error(ex, $"[Liquidation:ERROR] Process failed for CNO:{signal.cno} SNO:{signal.sno}");
            }
            finally
            {
                nlog.Info($"[Liquidation] <<< Close Process Finished for CNO:{signal.cno} SNO:{signal.sno}");
            }
        }

        private async Task<bool> IsAlreadyProcessedAsync(Models.XSignal signal)
        {
            var dbService = XContext.Instance.Parameter.GetService<XpoSqliteService>();
            if (dbService == null) return false;

            var anySignal = await dbService.FindAnySignalBySnoAsync(signal.cno, signal.sno);
            if (anySignal != null && anySignal.xe_status >= (int)XCode.EaStatus.Closed_Signal)
            {
                nlog.Info($"[Liquidation] CNO:{signal.cno} SNO:{signal.sno} is already closed (Status:{anySignal.xe_status}). Skipping redundant liquidation.");
                return true;
            }
            return false;
        }

        private async Task<List<XTA.XData.Models.XSignal>> SearchLiquidationTargetsAsync(Models.XSignal signal)
        {
            var targets = new List<XTA.XData.Models.XSignal>();
            var ctx = XContext.Instance;
            var gateway = ctx.Gateway as XGatewayService;
            var dbService = ctx.Parameter.GetService<XpoSqliteService>();

            // 메모리 검색
            if (gateway != null)
            {
                var pendingMatches = gateway.PendingSignals.Values
                    .Where(x => x.Signal != null && x.Signal.cno == signal.cno && x.Signal.sno == signal.sno)
                    .Select(x => (XTA.XData.Models.XSignal)x.Signal!)
                    .ToList();
                targets.AddRange(pendingMatches);
            }

            // DB 검색
            if (dbService != null)
            {
                var dbMatches = await dbService.FindActiveSignalsBySnoAsync(signal.cno, signal.sno);
                foreach (var dbm in dbMatches)
                {
                    if (!targets.Any(t => t.sid == dbm.sid)) targets.Add(dbm);
                }
            }
            return targets;
        }

        private async Task ExecuteActiveLiquidationAsync(List<XTA.XData.Models.XSignal> targets, int msgId)
        {
            var ctx = XContext.Instance;
            var gateway = ctx.Gateway as XGatewayService;

            foreach (var targetEntry in targets)
            {
                var finalSignal = targetEntry as Models.XSignal ?? Models.XSignal.FromBase(targetEntry);
                gateway?.PendingSignals.TryRemove(finalSignal.sid, out _);

                finalSignal.msg_id = msgId;
                finalSignal.cmd = XCode.CLOSE;
                finalSignal.xa_exit = (int)XCode.XA_ACTIVE;
                finalSignal.updated = DateTime.Now;

                if (ctx.Data != null) await ctx.Data.SaveSignalAsync(finalSignal);
            }
        }

        private async Task<Models.XSignal> ExecuteForcedLiquidationAsync(Models.XSignal signal, int msgId)
        {
            var ctx = XContext.Instance;
            var dbService = ctx.Parameter.GetService<XpoSqliteService>();
            
            nlog.Warn($"[Liquidation:FORCE] No active or historical signal found for CNO:{signal.cno} SNO:{signal.sno}. Generating forced record.");
            
            var lastActive = await dbService!.FindLastActiveSignalBySnoAsync(signal.cno, signal.sno);
            int validDir = lastActive?.dir ?? (signal.dir > 0 ? signal.dir : 1);

            var finalSignal = signal;
            finalSignal.dir = validDir;
            finalSignal.type = XCode.TYPE_MARKET;
            finalSignal.sid = XIdManager.Instance.GenerateSid(finalSignal.cno, DateTime.Now, finalSignal.sno, 0, finalSignal.dir, finalSignal.type);
            finalSignal.gid = XIdManager.Instance.GenerateGid(finalSignal.cno, DateTime.Now, finalSignal.sno, 0);
            finalSignal.symbol = "GOLD#";
            finalSignal.lot = 0.0;
            finalSignal.msg_id = msgId;
            finalSignal.cmd = XCode.CLOSE;
            finalSignal.xa_exit = XCode.XA_ACTIVE;
            finalSignal.SetXeStatus((int)XCode.EaStatus.Closed_Signal); 
            finalSignal.updated = DateTime.Now;

            if (ctx.Data != null) await ctx.Data.SaveSignalAsync(finalSignal);
            return finalSignal;
        }

        private void NotifyLiquidation(Models.XSignal signal, int count, bool isForced = false)
        {
            var ctx = XContext.Instance;
            if (isForced)
            {
                ctx.Gateway?.Log($"[{signal.cno}] {signal.sno}회차 활성 신호 없음 - 강제 청산 레코드 생성 (SID:{signal.sid})");
            }
            else
            {
                ctx.Gateway?.Log($"[{signal.cno}] {signal.sno}회차 청산 신호 접수 완료 ({count}건)");
            }
            
            // [v9.8.6] 청산 신호 접수 시 즉시 TTS 출력 복구
            string soundCmd = (signal.sno == 0) ? "GROUP_CLOSE" : "SID_CLOSE";
            nlog.Debug($"[Liquidation:TTS] Triggering {soundCmd} for SID:{signal.sid} (xa_exit=1)");
            ctx.Sound?.PlaySound(signal, soundCmd);
        }
    }
}