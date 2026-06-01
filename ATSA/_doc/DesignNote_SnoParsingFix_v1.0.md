# Design Note: Multi-Session SNO Extraction Fix v1.0

## Issue Description
When a close message contains multi-session descriptors such as `"9,10회차 정리"`, the system was only processing the last session number (`10`). The previous session number (`9`) remained active in the database (`xe_status = 10`, `xa_exit = 0`) instead of being liquidated.

## Root Cause
In `XRuleInterpreter.OnExtractSno()`, the parser checks if individual matches like `"10회차"` are found first. Because it succeeds, it sets `_ctx.Snos` count to $1$. 
The subsequent check for combo matches (which handles comma-separated sessions like `"9,10"`) was guarded by `if (_ctx.Snos.Count == 0)`. Therefore, the combo parsing logic was skipped.

## Solution Detail
Remove the short-circuiting condition and allow both matching patterns to run in sequence. We then use a duplicate check (`_ctx.Snos.Contains()`) to prevent adding the same SNO multiple times.

### Code Modification (`XTA/Channels/XRuleInterpreter.cs`)
```csharp
        protected virtual void OnExtractSno()
        {
            // 1. "N차 정리" 또는 "N회차" 형태 우선 추출
            var snoMatches = Regex.Matches(_ctx!.CleanText, @"(\d+)\s*(?:회차|차|횟차)");
            foreach (Match m in snoMatches)
            {
                if (int.TryParse(m.Groups[1].Value, out int s)) _ctx.Snos.Add(s);
            }

            // 2. 콤마나 공백으로 구분된 복수 회차 (예: "1, 2, 3회차")
            var comboMatch = Regex.Match(_ctx.CleanText, @"([\d,\s]+)(?:회차|차|횟차)");
            if (comboMatch.Success)
            {
                var snoPart = comboMatch.Groups[1].Value;
                var snoStrings = snoPart.Split(new[] { ',', ' ' }, StringSplitOptions.RemoveEmptyEntries);
                foreach (var sStr in snoStrings)
                {
                    if (int.TryParse(sStr.Trim(), out int s))
                    {
                        if (!_ctx.Snos.Contains(s)) _ctx.Snos.Add(s);
                    }
                }
            }
            // ...
        }
```

This guarantees that both `"9"` and `"10"` are added to `_ctx.Snos`, which triggers distinct cloned signals for both sessions in `GenerateFinalResults()`.
