using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using XTA.Models;
using FluentSeq;

namespace XTA.Services
{
    /// <summary>
    /// [Partial] Sequence: FluentSeq 기반의 청산 워크플로우 정의 (Workflow)
    /// </summary>
    public partial class XLiquidationService
    {
        private async Task ExecuteLiquidationWorkflowAsync(Models.XSignal signal, int msgId)
        {
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
                nlog.Error(ex, $"[Liquidation:ERROR] Workflow execution failed for CNO:{signal.cno} SNO:{signal.sno}");
                throw;
            }
        }
    }
}
