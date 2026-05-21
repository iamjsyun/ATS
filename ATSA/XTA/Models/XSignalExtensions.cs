using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using XTA.Interfaces;
using XTA.XData.Interfaces;
using XTA.XData.Models;

namespace XTA.Models
{
    public static class XSignalExtensions
    {
        public static async Task<List<XSignal>> SelectAsync(this List<XSignal>? signals, XParameter param, int cno = 0, int count = 20)
        {
            var db = param.GetService<ISignalRepository>();
            if (db == null) return new List<XSignal>();

            var result = await db.GetSignalsByCnoAsync(cno, count);

            if (signals != null)
            {
                signals.Clear();
                foreach(var s in result) 
                {
                    if (s is XTA.Models.XSignal xtaS) signals.Add(xtaS);
                    else
                    {
                        signals.Add(XTA.Models.XSignal.FromBase(s));
                    }
                }
                return signals;
            }

            return result.Select(XTA.Models.XSignal.FromBase).ToList();
        }

        public static async Task Insert(this List<XSignal> signals, XParameter param)
        {
            if (signals == null || signals.Count == 0) return;
            var db = param.GetService<ISignalRepository>();
            var gateway = param.GetService<IXGatewayService>();

            foreach (var s in signals)
            {
                if (s.Validate())
                {
                    var xdo = new XDataObject
                    {
                        Signal = s,
                        CMD = "INJECT_ADD",
                        CNO = s.cno,
                        Timestamp = DateTime.Now
                    };
                    
                    if (gateway != null) await gateway.ProcessInterpretedSignalAsync(xdo);

                    if (db != null) await VerifyOperation(db, param, s.sid ?? string.Empty, "INSERT");
                }
            }
        }

        public static async Task Update(this List<XSignal> signals, XParameter param)
        {
            if (signals == null || signals.Count == 0) return;
            var db = param.GetService<ISignalRepository>();
            var gateway = param.GetService<IXGatewayService>();

            foreach (var s in signals)
            {
                s.updated = DateTime.Now;
                var xdo = new XDataObject
                {
                    Signal = s,
                    CMD = "INJECT_MODIFY",
                    CNO = s.cno,
                    Timestamp = DateTime.Now
                };
                
                if (db != null) await db.SaveSignalAsync((XTA.XData.Models.XSignal)s);
                if (gateway != null) await gateway.ProcessInterpretedSignalAsync(xdo);
                
                if (db != null) await VerifyOperation(db, param, s.sid ?? string.Empty, "UPDATE");
            }
        }

        private static async Task VerifyOperation(ISignalRepository db, XParameter param, string sid, string opType)
        {
            const int maxRetries = 5;
            const int delayMs = 200;

            for (int i = 1; i <= maxRetries; i++)
            {
                await Task.Delay(delayMs);
                var current = await db.GetSignalBySidAsync(sid);

                bool success = opType switch
                {
                    "INSERT" or "UPDATE" => current != null,
                    "DELETE" => current == null,
                    _ => false
                };

                if (success) return;
            }
        }
    }
}
