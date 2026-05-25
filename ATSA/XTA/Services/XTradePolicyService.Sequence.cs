using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using XTA.Core;
using XTA.Models;
using XTA.XData.Models;
using XTA.XData.Interfaces;
using FluentSeq;

namespace XTA.Services
{
    public partial class XTradePolicyService
    {
        public async Task<List<Models.XSignal>> ApplyPolicyAsync(XDataObject xdo)
        {
            if (xdo.Signal == null) return new List<Models.XSignal>();

            var ctx = new PolicyContext(xdo, xdo.Signal, ResultSignals: new List<Models.XSignal>());
            ISequence<string> seq = null!;

            seq = new FluentSeq<string>().Create("Idle")
                .ConfigureState("ResolveConfig")
                    .OnEntry(() => {
                        var param = XContext.Instance.Parameter;
                        var merged = param.GetMergedConfig(ctx.MasterSignal.cno);

                        if (merged == null || merged.TradingOption == null)
                        {
                            nlog.Error($"[Policy] Critical: Merged configuration or TradingOption is null for CNO:{ctx.MasterSignal.cno}. Signal dropped.");
                            seq.SetState("End");
                            return;
                        }

                        var policy = (ctx.MasterSignal.dir == XCode.BUY) ? merged.TradingOption.Buy : merged.TradingOption.Sell;
                        
                        if (policy == null)
                        {
                            nlog.Error($"[Policy] Critical: Directional policy ({(ctx.MasterSignal.dir == XCode.BUY ? "BUY" : "SELL")}) is null for CNO:{ctx.MasterSignal.cno}. Signal dropped.");
                            seq.SetState("End");
                            return;
                        }

                        ctx = ctx with { MergedConfig = merged, Policy = policy };
                        seq.SetState("CheckEnablement");
                    })
                .ConfigureState("CheckEnablement")
                    .OnEntry(() => {
                        bool isManual = ctx.Xdo.CMD == "DM_INJECTION" || ctx.Xdo.CMD == "TEST_INJECTION";
                        if (!isManual && (ctx.Policy == null || ctx.Policy.Enabled == false))
                        {
                            nlog.Warn($"[Policy] Direction {(ctx.MasterSignal.dir == XCode.BUY ? "BUY" : "SELL")} is disabled for CNO:{ctx.MasterSignal.cno}. Signal Ignored.");
                            seq.SetState("End");
                        }
                        else if (ctx.MasterSignal.cmd == XCode.CLOSE)
                        {
                            ctx.MasterSignal.Validate();
                            ctx.ResultSignals.Add(ctx.MasterSignal);
                            seq.SetState("End");
                        }
                        else
                        {
                            seq.SetState("QueryGrid");
                        }
                    })
                .ConfigureState("QueryGrid")
                    .OnEntry(async () => {
                        var profileRepo = XContext.Instance.GetOptionalService<IGridProfileRepository>();
                        var profiles = profileRepo != null ? await profileRepo.GetGridProfilesAsync(ctx.MasterSignal.cno, ctx.MasterSignal.dir) : new List<XGridProfile>();
                        ctx = ctx with { Profiles = profiles };
                        
                        if (ctx.Profiles == null || ctx.Profiles.Count == 0) seq.SetState("ApplySinglePolicy");
                        else seq.SetState("ApplyGridPolicy");
                    })
                .ConfigureState("ApplySinglePolicy")
                    .OnEntry(() => {
                        var s = ctx.MasterSignal.Clone();
                        bool isManual = ctx.Xdo.CMD == "DM_INJECTION" || ctx.Xdo.CMD == "TEST_INJECTION";
                        ApplyDirectionPolicy(s, ctx.Policy!, isManual);
                        s.Validate();
                        ctx.ResultSignals.Add(s);
                        seq.SetState("End");
                    })
                .ConfigureState("ApplyGridPolicy")
                    .OnEntry(() => {
                        if (ctx.Profiles == null) return;
                        bool isManual = ctx.Xdo.CMD == "DM_INJECTION" || ctx.Xdo.CMD == "TEST_INJECTION";
                        foreach (var profile in ctx.Profiles)
                        {
                            var s = ctx.MasterSignal.Clone();
                            s.gno = profile.gno;
                            s.type = profile.type;
                            
                            if (profile.lot_type == 2) s.lot = Math.Round(ctx.MasterSignal.lot * profile.lot, 2);
                            else s.lot = profile.lot;

                            ApplyDirectionPolicy(s, ctx.Policy!, isManual);

                            // [v14.42] Conditional Override Logic: Only overwrite if profile has non-zero value
                            s.te_limit = (profile.offset > 0) ? profile.offset : s.te_limit;
                            s.limit_offset = profile.offset;
                            s.stop_offset = profile.offset;

                            if (profile.te_start > 0) s.te_start = profile.te_start;
                            if (profile.te_step > 0) s.te_step = profile.te_step;
                            if (profile.ts_start > 0) s.ts_start = profile.ts_start;
                            if (profile.ts_step > 0) s.ts_step = profile.ts_step;
                            if (profile.tp > 0) s.tp = profile.tp;
                            if (profile.sl > 0) s.sl = profile.sl;
                            if (profile.ikte_start > 0) s.ikte_start = profile.ikte_start;
                            if (profile.ikte_step > 0) s.ikte_step = profile.ikte_step;

                            if (s.type == XCode.TYPE_MARKET) s.price_signal = 0;
                            else
                            {
                                if (s.dir == XCode.BUY) s.price_signal = Math.Round(ctx.MasterSignal.price_signal - (s.te_limit * 0.01), 2);
                                else if (s.dir == XCode.SELL) s.price_signal = Math.Round(ctx.MasterSignal.price_signal + (s.te_limit * 0.01), 2);
                            }

                            s.Validate();
                            ctx.ResultSignals.Add(s);
                        }
                        seq.SetState("End");
                    })
                .ConfigureState("End")
                .Builder().DisableValidation().Build();

            seq.SetState("ResolveConfig");

            try
            {
                int safety = 0;
                while (!seq.IsInState("End") && safety++ < 20)
                {
                    await seq.RunAsync();
                }
            }
            catch (Exception ex)
            {
                nlog.Error(ex, $"[Policy:ERROR] Failed to apply policy for CNO:{ctx.MasterSignal.cno}");
                ctx.MasterSignal.Validate();
                ctx.ResultSignals.Clear();
                ctx.ResultSignals.Add(ctx.MasterSignal);
            }

            return ctx.ResultSignals;
        }
    }
}
