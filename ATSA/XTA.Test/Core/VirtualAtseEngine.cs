using System;
using System.Threading.Tasks;
using XTA.XData.Models;
using XTA.Infrastructure.Data;
using System.Globalization;

namespace XTA.Test.Core
{
    /// <summary>
    /// 가상의 ATSE (MetaTrader 5 Expert Advisor) 동작을 모사하는 엔진.
    /// ATSA(C#) 환경에서만 독립적으로 연동 시뮬레이션을 수행할 수 있도록 지원합니다.
    /// </summary>
    public class VirtualAtseEngine
    {
        private readonly XpoSqliteService _db;

        public VirtualAtseEngine(XpoSqliteService db)
        {
            _db = db;
        }

        public async Task ProcessActionAsync(XSignal sig, ScenarioModel scenario, ScenarioStep step)
        {
            // 실제 ATSE의 처리 시간 모사 (50ms ~ 200ms 지연)
            await Task.Delay(new Random().Next(50, 200)); 

            foreach (var param in step.Parameters)
            {
                var value = param.Value;
                if (value.StartsWith("{") && value.EndsWith("}"))
                {
                    // 수식 계산 (예: {PRICE+5.0})
                    var expression = value.Substring(1, value.Length - 2).Replace("PRICE", scenario.Price.ToString(CultureInfo.InvariantCulture));
                    value = new System.Data.DataTable().Compute(expression, null).ToString() ?? "0";
                }
                
                // 가상 상태 업데이트 반영
                if (param.Key == "xe_status") 
                {
                    int nextStatus = int.Parse(value);
                    sig.xe_status = nextStatus;
                }
                else if (param.Key == "price_open") sig.price_open = double.Parse(value, CultureInfo.InvariantCulture);
                else if (param.Key == "price_close") sig.price_close = double.Parse(value, CultureInfo.InvariantCulture);
                else if (param.Key == "ticket") sig.ticket = long.Parse(value);
                else if (param.Key == "lot") sig.lot = double.Parse(value, CultureInfo.InvariantCulture);
            }

            sig.updated = DateTime.Now;
            
            // 변경된 상태를 DB에 저장하여 ATSA Watcher가 감지하도록 유도
            await _db.SaveSignalImmediateAsync(sig);
        }
    }
}
