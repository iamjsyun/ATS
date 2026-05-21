using System;
using XTA.Models;
using XTA.XData.Models;

namespace XTA.Services
{
    public partial class XTradePolicyService
    {
        private void ApplyDirectionPolicy(Models.XSignal s, XDirectionOption policy)
        {
            var strategy = policy.LotStrategy;
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

            if (policy.Entry != null)
            {
                s.te_start = policy.Entry.TeStart;
                s.te_step = policy.Entry.TeStep;
                s.te_limit = policy.Entry.TeLimit;
            }

            if (policy.Exit != null)
            {
                s.ts_start = policy.Exit.TsStart;
                s.ts_step = policy.Exit.TsStep;
                s.tp = policy.Exit.TP;
                s.sl = policy.Exit.SL;
            }
        }
    }
}
