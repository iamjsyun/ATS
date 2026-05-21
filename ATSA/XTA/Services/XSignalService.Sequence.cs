using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using XTA.Core;
using XTA.Models;
using XTA.XData.Models;
using FluentSeq;

namespace XTA.Services
{
    /// <summary>
    /// [Partial] Sequence: FluentSeq 기반의 신호 Enrichment 워크플로우 정의 (Workflow)
    /// </summary>
    public partial class XSignalService
    {
        public async Task<List<Models.XSignal>> PrepareSignalsAsync(XDataObject xdo)
        {
            var globalCtx = XContext.Instance;
            if (globalCtx.Policy == null) 
            {
                nlog.Error("[SIGNAL:ERROR] Policy service is not initialized.");
                return new List<Models.XSignal>();
            }

            // 1. 정책 서비스 적용 (내부적으로 FluentSeq 구동)
            var enriched = await globalCtx.Policy.ApplyPolicyAsync(xdo);
            if (enriched == null || enriched.Count == 0) return new List<Models.XSignal>();

            var finalResults = new List<Models.XSignal>();

            // 2. 신호 단위로 Enrichment 시퀀스 구동
            foreach (var s in enriched)
            {
                var ctx = new EnrichContext(xdo, s);
                ISequence<string> seq = null!;

                seq = new FluentSeq<string>().Create("Idle")
                    .ActivateDebugLogging(nlog)
                    .ConfigureState("GenerateIDs")
                        .OnEntry(() => {
                            var sig = ctx.CurrentSignal;
                            if (string.IsNullOrEmpty(sig.sid))
                                sig.sid = XIdManager.Instance.GenerateSid(sig.cno, DateTime.Now, sig.sno, sig.gno, sig.dir, sig.type);
                            if (string.IsNullOrEmpty(sig.gid))
                                sig.gid = XIdManager.Instance.GenerateGid(sig.cno, DateTime.Now, sig.sno, sig.gno);
                            seq.SetState("PatchMetadata");
                        })
                    .ConfigureState("PatchMetadata")
                        .OnEntry(() => {
                            var sig = ctx.CurrentSignal;
                            sig.updated = DateTime.Now;
                            if (sig.xe_status == 0) sig.SetXeStatus((int)XCode.EaStatus.Ready);

                            // [v9.0] 모든 주입 신호의 심볼은 GOLD#으로 통일
                            sig.symbol = "GOLD#";

                            if (ctx.Xdo.CMD == "DM_INJECTION")
                            {
                                nlog.Debug($"[Signal:ENRICH:DM] Patching manual signal metadata for CNO:{sig.cno}");
                                if (sig.xa_exit == 0 && sig.xa_entry == 0) sig.xa_entry = 1;
                                if (sig.xa_entry > 0 && sig.price_signal <= 0) sig.price_signal = 1.0;
                            }
                            seq.SetState("CheckDuplicates");
                        })
                    .ConfigureState("CheckDuplicates")
                        .OnEntry(async () => {
                            nlog.Debug($"[Signal:ENRICH] SID:{ctx.CurrentSignal.sid} GID:{ctx.CurrentSignal.gid} CNO:{ctx.CurrentSignal.cno} Dir:{ctx.CurrentSignal.dir} Type:{ctx.CurrentSignal.type}");

                            if (ctx.Xdo.CMD != "DM_INJECTION" && globalCtx.SignalRepo != null)
                            {
                                var existing = await globalCtx.SignalRepo.GetSignalBySidAsync(ctx.CurrentSignal.sid);
                                if (existing != null)
                                {
                                    nlog.Warn($"[Signal:DROP] Duplicate SID detected. Injection aborted for SID:{ctx.CurrentSignal.sid}");
                                    ctx = ctx with { IsDropped = true };
                                    seq.SetState("End");
                                    return;
                                }
                            }
                            seq.SetState("Validate");
                        })
                    .ConfigureState("Validate")
                        .OnEntry(async () => {
                            if (ctx.IsDropped) { seq.SetState("End"); return; }
                            var valResult = _validator.Validate(ctx.CurrentSignal);
                            if (valResult.IsValid)
                            {
                                finalResults.Add(ctx.CurrentSignal);
                            }
                            else
                            {
                                string errors = string.Join(", ", valResult.Errors.Select(e => e.ErrorMessage));
                                string errorMsg = $"[VAL-99] Validation Failed: {errors}";
                                nlog.Warn($"[Signal:VALIDATE-FAIL] SID:{ctx.CurrentSignal.sid} | {errorMsg}");
                                
                                ctx.CurrentSignal.xe_status = 99;
                                ctx.CurrentSignal.xe_status_msg = errorMsg;
                                ctx.CurrentSignal.comment = errors;

                                if (globalCtx.SignalRepo != null)
                                {
                                    await globalCtx.SignalRepo.SaveSignalImmediateAsync(ctx.CurrentSignal, true);
                                }
                            }
                            seq.SetState("End");
                        })
                    .ConfigureState("End")
                    .Builder().DisableValidation().Build();

                seq.SetState("GenerateIDs");

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
                    nlog.Error(ex, $"[Signal:PREPARE-ERROR] Error preparing signal for CNO:{ctx.CurrentSignal.cno}");
                }
            }

            return finalResults;
        }
    }
}
