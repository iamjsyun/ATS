using System;
using XTA.Models;
using XTA.XData.Models;

namespace XTA.Services
{
    public partial class XTradePolicyService
    {
        private void ApplyDirectionPolicy(Models.XSignal s, XDirectionOption policy)
        {
            var strategy = policy.LotStrategyObj;
            if (strategy != null)
            {
                if (strategy.Type == "Fixed")
                {
                    if (s.lot <= 0) s.lot = strategy.Value;
                }
                else if (strategy.Type == "Rate")
                {
                    if (s.lot > 0) s.lot = Math.Round(s.lot * strategy.Rate, 2);
                    else s.lot = Math.Round(0.01 * strategy.Rate, 2);
                    
                    if (s.lot < 0.01) s.lot = 0.01;
                }
            }

            var entry = policy.EntryObj;
            if (entry != null)
            {
                s.te_start = entry.TeStart;
                s.te_step = entry.TeStep;
                s.te_limit = entry.TeLimit;
            }

            var exit = policy.ExitObj;
            if (exit != null)
            {
                s.ts_start = exit.TsStart;
                s.ts_step = exit.TsStep;
                s.tp = exit.TP;
                s.sl = exit.SL;
            }
        }
    }
}
