using System;
using XTA.Models;
using XTA.XData.Models;

namespace XTA.Services
{
    public partial class XTradePolicyService
    {
        private void ApplyDirectionPolicy(Models.XSignal s, XDirectionOption policy, bool isManual = false)
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

            // [v16.12] Manual Injection Guard: UI 수동 주입 시, 사용자가 수동 기입한 값을 정책 기본값으로 덮어쓰지 않음
            var entry = policy.EntryObj;
            if (entry != null)
            {
                if (!isManual || s.te_start <= 0) s.te_start = entry.TeStart;
                if (!isManual || s.te_step <= 0)  s.te_step = entry.TeStep;
                if (!isManual || s.te_limit <= 0) s.te_limit = entry.TeLimit;
            }

            var exit = policy.ExitObj;
            if (exit != null)
            {
                if (!isManual || s.ts_start <= 0) s.ts_start = exit.TsStart;
                if (!isManual || s.ts_step <= 0)  s.ts_step = exit.TsStep;
                if (!isManual || s.tp <= 0)       s.tp = exit.TP;
                if (!isManual || s.sl <= 0)       s.sl = exit.SL;
            }
        }
    }
}
