using System;
using XTA.XData.Models;

namespace XTA.Core
{
    /// <summary>
    /// [v13.4 Standard] 유니버설 감사 포맷 (Universal Audit Format) 헬퍼
    /// 모든 핵심 매니저 및 서비스의 로그 출력을 표준화된 단일 구조로 통합합니다.
    /// </summary>
    public static class XAuditFormatter
    {
        /// <summary>
        /// 표준화된 감사 문자열 생성: [ACTION] [META] [BASE] [PRICE] {EXTRA}
        /// </summary>
        public static string ToAuditString(this XSignal s, string action, string extra = "")
        {
            if (s == null) return $"[{action}] Signal is null.";

            string meta = $"[META] SID:{s.sid}, GID:{s.gid}, CNO:{s.cno}";
            string baseInfo = $"[BASE] Sym:{s.symbol}, Dir:{(s.dir == 1 ? "BUY" : "SELL")}, Lot:{s.lot:N2}, Type:{s.type}, SNO:{s.sno}, GNO:{s.gno}";
            string price = $"[PRICE] P:{s.price_signal:N2}, SL:{s.sl:N0}, TP:{s.tp:N0}, TE:{s.te_start:N0}, TS:{s.ts_start:N0}";
            
            string result = $"[{action}] {meta} {baseInfo} {price}";
            if (!string.IsNullOrEmpty(extra))
            {
                result += $" {extra}";
            }

            return result;
        }

        public static string ToMetaString(this XSignal s) => $"[META] SID:{s.sid}, GID:{s.gid}, CNO:{s.cno}";
        public static string ToBaseString(this XSignal s) => $"[BASE] Sym:{s.symbol}, Dir:{(s.dir == 1 ? "BUY" : "SELL")}, Lot:{s.lot:N2}, Type:{s.type}, SNO:{s.sno}, GNO:{s.gno}";
        public static string ToPriceString(this XSignal s) => $"[PRICE] P:{s.price_signal:N2}, SL:{s.sl:N0}, TP:{s.tp:N0}, TE:{s.te_start:N0}, TS:{s.ts_start:N0}";
    }
}
