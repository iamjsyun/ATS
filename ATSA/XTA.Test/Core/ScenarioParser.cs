using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using XTA.XData.Models;

namespace XTA.Test.Core
{
    public class ScenarioModel
    {
        public string ScenarioId { get; set; } = "";
        public string ScenType { get; set; } = "";
        public int Cno { get; set; }
        public int Sno { get; set; }
        public string Symbol { get; set; } = "";
        public int Dir { get; set; }
        public double Lot { get; set; }
        public double Price { get; set; }
        public List<ScenarioStep> Steps { get; set; } = new();
    }

    public class ScenarioStep
    {
        public string Actor { get; set; } = "";
        public string Action { get; set; } = "";
        public double DelaySeconds { get; set; }
        public Dictionary<string, string> Parameters { get; set; } = new();
    }

    public static class ScenarioParser
    {
        public static List<ScenarioModel> Parse(string filePath)
        {
            var list = new List<ScenarioModel>();
            var lines = File.ReadAllLines(filePath).Skip(1); // Skip header

            foreach (var line in lines)
            {
                if (string.IsNullOrWhiteSpace(line)) continue;
                var cols = line.Split(',');
                if (cols.Length < 9) continue;

                var model = new ScenarioModel
                {
                    ScenarioId = cols[0].Trim(),
                    ScenType = cols[1].Trim(),
                    Cno = int.Parse(cols[2].Trim()),
                    Sno = int.Parse(cols[3].Trim()),
                    Symbol = cols[4].Trim(),
                    Dir = int.Parse(cols[5].Trim()),
                    Lot = double.Parse(cols[6].Trim()),
                    Price = double.Parse(cols[7].Trim())
                };

                // Sequence: INJECT@0 > MOCK_EA:xe_status=10@2
                var seqParts = cols[8].Split('>');
                foreach (var part in seqParts)
                {
                    var cleanPart = part.Trim();
                    var atIndex = cleanPart.LastIndexOf('@');
                    if (atIndex == -1) continue;

                    var cmdPart = cleanPart.Substring(0, atIndex);
                    var delayStr = cleanPart.Substring(atIndex + 1);

                    var step = new ScenarioStep { DelaySeconds = double.Parse(delayStr) };

                    if (cmdPart.Contains(':'))
                    {
                        var split = cmdPart.Split(':', 2);
                        step.Actor = split[0].Trim();
                        var actions = split[1].Split(',');
                        foreach (var act in actions)
                        {
                            if (act.Contains('='))
                            {
                                var kv = act.Split('=');
                                step.Parameters[kv[0].Trim()] = kv[1].Trim();
                            }
                            else { step.Action = act.Trim(); }
                        }
                    }
                    else
                    {
                        step.Actor = cmdPart.Trim();
                    }
                    model.Steps.Add(step);
                }
                list.Add(model);
            }
            return list;
        }
    }
}
