using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.IO;
using XTA.Core;
using XTA.Interfaces;
using XTA.Models;
using XTA.XData.Models;
using XTA.Infrastructure.Data;
using XTA.Test.Core;
using Xunit;
using FluentAssertions;
using System.Globalization;

namespace XTA.Test.Core
{
    public class ScenarioRunner
    {
        private readonly XParameter _param;
        private readonly XpoSqliteService _db;
        private readonly VirtualAtseEngine _virtualAtse;

        public ScenarioRunner(XParameter param, XpoSqliteService db)
        {
            _param = param;
            _db = db;
            _virtualAtse = new VirtualAtseEngine(db);
        }

        public async Task ExecuteAsync(ScenarioModel scenario)
        {
            Console.WriteLine($"[TEST:RUNNER] Starting Scenario: {scenario.ScenarioId} ({scenario.ScenType})");

            try
            {
                var sortedSteps = scenario.Steps.OrderBy(s => s.DelaySeconds).ToList();
                DateTime startTime = DateTime.Now;

                foreach (var step in sortedSteps)
                {
                    int waitMs = (int)(step.DelaySeconds * 1000) - (int)(DateTime.Now - startTime).TotalMilliseconds;
                    if (waitMs > 0) await Task.Delay(waitMs);

                    Console.WriteLine($"[TEST:STEP] Actor:{step.Actor} Action:{step.Action} @{step.DelaySeconds}s");

                    switch (step.Actor)
                    {
                        case "INJECT":
                            await HandleInject(scenario);
                            break;
                        case "MOCK_EA":
                            await HandleMockEA(scenario, step);
                            break;
                        case "MOCK_APP":
                            await HandleMockApp(scenario, step);
                            break;
                        case "AWAIT":
                            await HandleAwait(scenario, step);
                            break;
                        case "ASSERT":
                            await HandleAssert(scenario, step);
                            break;
                        case "ASSERT_NOT_EXISTS":
                            await HandleAssertNotExists(scenario);
                            break;
                        case "ASSERT_COUNT":
                            await HandleAssertCount(scenario, step);
                            break;
                        case "ASSERT_ARCHIVED":
                            await HandleAssertArchived(scenario);
                            break;
                    }

                    var all = await _db.GetAllActiveSignalsAsync();
                    Console.WriteLine($"[TEST:DB-STATE] Active Signal Count: {all.Count}");
                    foreach (var s in all) Console.WriteLine($"  - SID:{s.sid} CNO:{s.cno} SNO:{s.sno} XE:{s.xe_status} EN:{s.xa_entry} EX:{s.xa_exit}");
                }
                Console.WriteLine($"[TEST:RUNNER] Finished Scenario: {scenario.ScenarioId}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[TEST:FATAL] Scenario {scenario.ScenarioId} failed: {ex.Message}");
                throw;
            }
        }

        private async Task HandleAssertCount(ScenarioModel scenario, ScenarioStep step)
        {
            var expectedCount = int.Parse(step.Action);
            var all = await _db.GetAllActiveSignalsAsync();
            all.Count.Should().Be(expectedCount, $"Database should contain exactly {expectedCount} active signals for scenario {scenario.ScenarioId}.");
            Console.WriteLine($"[TEST:ASSERT-COUNT] Passed. Count: {all.Count}");
        }

        private async Task HandleInject(ScenarioModel scenario)
        {
            var gateway = XContext.Instance.Gateway;
            var info = _param.GetChannelByCno(scenario.Cno);
            if (info == null) { Console.WriteLine($"[TEST:ERROR] Channel not found for CNO:{scenario.Cno}"); return; }

            string channelName = info.Name;
            string baseDir = AppContext.BaseDirectory;
            string[] possiblePaths = {
                Path.Combine(baseDir, "Channels", channelName),
                Path.Combine(baseDir, "XTA", "Channels", channelName),
                Path.Combine(Directory.GetParent(baseDir)?.Parent?.Parent?.Parent?.FullName ?? "", "ATSA", "XTA", "Channels", channelName)
            };

            string folderPath = possiblePaths.FirstOrDefault(Directory.Exists) ?? "";
            string templateText = "[ENTRY] {SYMBOL} {DIR} {LOT} lot (Price: {PRICE}) 싯점 정보공유 시장관점 참고가격"; 

            if (scenario.ScenType == "ENTRY_MALFORMED")
            {
                templateText = "이 메시지는 파싱될 수 없는 잘못된 포맷입니다. {SYMBOL} {DIR}";
            }
            else if (!string.IsNullOrEmpty(folderPath))
            {
                string fullPath = Path.Combine(folderPath, "Template_Entry.txt");
                if (File.Exists(fullPath)) templateText = File.ReadAllText(fullPath);
            }

            string msg = templateText
                .Replace("{SNO}", scenario.Sno.ToString())
                .Replace("{SYMBOL}", scenario.Symbol)
                .Replace("{DIR}", scenario.Dir == 1 ? "매수" : "매도") 
                .Replace("{LOT}", scenario.Lot.ToString("N2", CultureInfo.InvariantCulture))
                .Replace("{PRICE}", scenario.Price.ToString("N2", CultureInfo.InvariantCulture))
                .Replace("{TIME}", DateTime.Now.ToString("yyyy.MM.dd HH:mm:ss"));

            Console.WriteLine($"[TEST:INJECT] CNO:{scenario.Cno} Msg: {msg.Replace("\n", " ").Substring(0, Math.Min(100, msg.Length))}...");

            var testSig = new XTA.Models.XSignal {
                cno = scenario.Cno, sno = scenario.Sno, symbol = scenario.Symbol, dir = scenario.Dir, lot = scenario.Lot, price_signal = scenario.Price,
                xa_entry = 1, xe_status = 0, created = DateTime.Now, updated = DateTime.Now
            };
            testSig.sid = XIdManager.Instance.GenerateSid(testSig.cno, testSig.created, testSig.sno, 0, testSig.dir, 1);
            testSig.gid = XIdManager.Instance.GenerateGid(testSig.cno, testSig.created, testSig.sno, 0);

            Console.WriteLine($"[TEST:DIRECT-SAVE] SID:{testSig.sid}");
            await _db.SaveSignalImmediateAsync(testSig);

            var xdo = new XDataObject { CID = info.CID, CNO = scenario.Cno, Text = msg, MsgId = new Random().Next(10000, 99999), Timestamp = DateTime.Now };
            gateway?.EnqueueRawMessage(xdo);
            await Task.Delay(2000); 
        }

        private async Task HandleMockEA(ScenarioModel scenario, ScenarioStep step)
        {
            var sig = await FindSignal(scenario);
            if (sig == null) { Console.WriteLine($"[TEST:EA-MOCK:FAIL] No signal found to mock for SNO:{scenario.Sno}"); return; }

            await _virtualAtse.ProcessActionAsync(sig, scenario, step);
        }

        private async Task HandleMockApp(ScenarioModel scenario, ScenarioStep step)
        {
            var sig = await FindSignal(scenario);
            if (sig == null) { Console.WriteLine($"[TEST:APP-MOCK:FAIL] No signal found to mock for SNO:{scenario.Sno}"); return; }
            if (step.Parameters.ContainsKey("xa_exit")) sig.xa_exit = int.Parse(step.Parameters["xa_exit"]);
            await _db.SaveSignalImmediateAsync(sig);
        }

        private async Task HandleAssertArchived(ScenarioModel scenario)
        {
            var sig = await FindSignal(scenario, 5);
            sig.Should().BeNull("Signal should be archived and removed from active table.");
        }

        private async Task<XTA.XData.Models.XSignal?> FindSignal(ScenarioModel scenario, int timeoutSec = 10)
        {
            DateTime start = DateTime.Now;
            while ((DateTime.Now - start).TotalSeconds < timeoutSec)
            {
                var signals = await _db.FindActiveSignalsBySnoAsync(scenario.Cno, scenario.Sno);
                var found = signals.FirstOrDefault();
                if (found != null) return found; 
                await Task.Delay(500);
            }
            return null;
        }

        private async Task HandleAwait(ScenarioModel scenario, ScenarioStep step)
        {
            var timeoutStr = step.Parameters.ContainsKey("timeout") ? step.Parameters["timeout"] : "10";
            int timeoutSec = int.Parse(timeoutStr);
            
            DateTime start = DateTime.Now;
            bool conditionMet = false;
            
            while ((DateTime.Now - start).TotalSeconds < timeoutSec)
            {
                var sig = await FindSignal(scenario, 1);
                if (sig != null)
                {
                    bool allMatch = true;
                    foreach (var param in step.Parameters)
                    {
                        if (param.Key == "timeout") continue;
                        if (param.Key == "xe_status" && sig.xe_status != int.Parse(param.Value)) allMatch = false;
                        if (param.Key == "xa_entry" && sig.xa_entry != int.Parse(param.Value)) allMatch = false;
                        if (param.Key == "xa_exit" && sig.xa_exit != int.Parse(param.Value)) allMatch = false;
                        if (param.Key == "lot" && sig.lot != double.Parse(param.Value, CultureInfo.InvariantCulture)) allMatch = false;
                    }
                    if (allMatch) { conditionMet = true; break; }
                }
                await Task.Delay(500);
            }
            
            conditionMet.Should().BeTrue($"AWAIT condition not met within {timeoutSec}s for scenario {scenario.ScenarioId}.");
            Console.WriteLine($"[TEST:AWAIT] Condition met.");
        }

        private async Task HandleAssertNotExists(ScenarioModel scenario)
        {
            var sig = await FindSignal(scenario, 3);
            sig.Should().BeNull($"Signal for scenario {scenario.ScenarioId} should not exist.");
        }

        private async Task HandleAssert(ScenarioModel scenario, ScenarioStep step)
        {
            var sig = await FindSignal(scenario);
            if (sig == null)
            {
                 var all = await _db.GetAllActiveSignalsAsync();
                 Console.WriteLine($"[TEST:FAIL-DIAG] No signal for SNO:{scenario.Sno}. Total active: {all.Count}");
            }
            sig.Should().NotBeNull($"Signal for scenario {scenario.ScenarioId} must exist in DB (SNO:{scenario.Sno}).");
            foreach (var param in step.Parameters)
            {
                if (param.Key == "xe_status") sig!.xe_status.Should().Be(int.Parse(param.Value));
                if (param.Key == "xa_exit") sig!.xa_exit.Should().Be(int.Parse(param.Value));
                if (param.Key == "lot") sig!.lot.Should().Be(double.Parse(param.Value, CultureInfo.InvariantCulture));
            }
        }
    }
}
