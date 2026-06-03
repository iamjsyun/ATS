using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using System.IO;
using System.Text.Json;
using FluentSeq;
using XTA.Models;
using XTA.XData.Models;
using XSignal = XTA.Models.XSignal;

namespace XTA.Channels
{
    public abstract class XRuleInterpreter : XInterpreterBase
    {
        private ISequence<string> _seq = null!;
        protected ParsingContext? _ctx;
        protected KeywordConfig Keywords { get; private set; } = new();

        protected XRuleInterpreter(XParameter param, XChannelInfo info) : base(param, info)
        {
            LoadKeywords();
            InitSequence();
        }

        protected virtual string[] EntryKeywords => Keywords.EntryKeywords.ToArray();
        protected virtual string[] ExitKeywords => Keywords.ExitKeywords.ToArray();

        protected virtual void LoadKeywords()
        {
            LoadKeywordsForChannel(this.GetType().Name);
        }

        protected void LoadKeywordsForChannel(string channelName)
        {
            try
            {
                var baseDir = AppDomain.CurrentDomain.BaseDirectory;
                
                string[] possiblePaths = {
                    Path.Combine(baseDir, "Channels", channelName),
                    Path.Combine(baseDir, "XTA", "Channels", channelName),
                    Path.Combine(Directory.GetParent(baseDir)?.Parent?.Parent?.FullName ?? "", "ATSA", "XTA", "Channels", channelName)
                };

                foreach (var folder in possiblePaths)
                {
                    if (!Directory.Exists(folder)) continue;

                    string txtPath = Path.Combine(folder, "Keywords.txt");
                    if (File.Exists(txtPath))
                    {
                        LoadFromText(txtPath);
                        nlog.Debug($"[SIGNAL:INFO] Keywords loaded for {channelName} from {txtPath}");
                        return;
                    }

                    string jsonPath = Path.Combine(folder, "Keywords.json");
                    if (File.Exists(jsonPath))
                    {
                        var json = File.ReadAllText(jsonPath);
                        var config = JsonSerializer.Deserialize<KeywordConfigLegacy>(json);
                        if (config != null)
                        {
                            Keywords.EntryKeywords = config.EntryKeywords.ToList();
                            Keywords.ExitKeywords = config.ExitKeywords.ToList();
                            Keywords.BuyKeywords = config.BuyKeywords.ToList();
                            Keywords.SellKeywords = config.SellKeywords.ToList();
                            Keywords.PriceKeywords = config.PriceKeywords.ToList();
                            Keywords.LotKeywords = config.LotKeywords.ToList();
                            Keywords.SnoKeywords = config.SnoKeywords.ToList();
                            nlog.Debug($"[SIGNAL:INFO] Keywords loaded for {channelName} from {jsonPath} (Legacy)");
                            return;
                        }
                    }
                }
                nlog.Warn($"[SIGNAL:WARN] Keywords configuration not found for {channelName}.");
            }
            catch (Exception ex)
            {
                nlog.Error(ex, $"[SIGNAL:ERROR] Failed to load keywords for {channelName}.");
            }
        }

        private void LoadFromText(string path)
        {
            var lines = File.ReadAllLines(path);
            foreach (var line in lines)
            {
                if (string.IsNullOrWhiteSpace(line) || line.StartsWith("Category")) continue;

                var parts = line.Split('\t');
                if (parts.Length < 2) continue;

                var category = parts[0].Trim();
                // [v9.0] 패턴에서도 이모지 제거하여 Plain Text 상태로 저장
                var pattern = StripEmojis(parts[1].Trim());

                switch (category)
                {
                    case "Entry": Keywords.EntryKeywords.Add(pattern); break;
                    case "Exit": Keywords.ExitKeywords.Add(pattern); break;
                    case "Buy": Keywords.BuyKeywords.Add(pattern); break;
                    case "Sell": Keywords.SellKeywords.Add(pattern); break;
                    case "Price": Keywords.PriceKeywords.Add(pattern); break;
                    case "Lot": Keywords.LotKeywords.Add(pattern); break;
                    case "Sno": Keywords.SnoKeywords.Add(pattern); break;
                }
            }
        }

        private string EntryPattern => Keywords.EntryKeywords.Any() ? "(?:" + string.Join("|", Keywords.EntryKeywords.Select(k => Regex.Escape(k))) + ")" : "(?!x)x";
        private string ExitPattern => Keywords.ExitKeywords.Any() ? "(?:" + string.Join("|", Keywords.ExitKeywords.Select(k => Regex.Escape(k))) + ")" : "(?!x)x";
        private string BuyPattern => Keywords.BuyKeywords.Any() ? "(?:" + string.Join("|", Keywords.BuyKeywords.Select(k => Regex.Escape(k))) + ")" : "(?!x)x";
        private string SellPattern => Keywords.SellKeywords.Any() ? "(?:" + string.Join("|", Keywords.SellKeywords.Select(k => Regex.Escape(k))) + ")" : "(?!x)x";
        
        private string PricePattern => Keywords.PriceKeywords.Any() ? string.Join("|", Keywords.PriceKeywords) : "(?!x)x";
        private string LotPattern => Keywords.LotKeywords.Any() ? string.Join("|", Keywords.LotKeywords) : "(?!x)x";
        private string SnoPattern => Keywords.SnoKeywords.Any() ? string.Join("|", Keywords.SnoKeywords) : "(?!x)x";

        private void InitSequence()
        {
            _seq = new FluentSeq<string>()
                .Create("Idle")
                .ConfigureState("Idle")
                .ConfigureState("Normalize")
                    .OnEntry(() => RunStep(() => {
                        _ctx!.CleanText = OnNormalizeText(_ctx.RawText);
                        nlog.Info($"[SIGNAL:DEBUG:PARSE] CleanText: {_ctx.CleanText}");
                    }))
                .ConfigureState("IdentifyCommand")
                    .OnEntry(() => RunStep(OnIdentifyCommand))
                .ConfigureState("ExtractDirection")
                    .OnEntry(() => RunStep(OnExtractDirection, XCode.OPEN))
                .ConfigureState("ExtractPrice")
                    .OnEntry(() => RunStep(OnExtractPrice, XCode.OPEN))
                .ConfigureState("ExtractLot")
                    .OnEntry(() => RunStep(OnExtractLot, XCode.OPEN))
                .ConfigureState("ExtractSno")
                    .OnEntry(() => RunStep(OnExtractSno, "!NONE"))
                .ConfigureState("Finalize")
                    .OnEntry(() => RunStep(OnFinalize, "!NONE"))
                .Builder().DisableValidation().Build();
        }

        private void RunStep(Action action, string? condition = null)
        {
            if (_ctx == null || _ctx.IsAborted) return;
            if (condition == XCode.OPEN && _ctx.Cmd != XCode.OPEN) return;
            if (condition == "!NONE" && _ctx.Cmd == XCode.NONE) return;
            action();
        }

        public override List<XSignal> Interpret(XDataObject xdo)
        {
            lock (_syncRoot)
            {
                _ctx = new ParsingContext(xdo, CreateBaseSignal(xdo));
                string[] states = { "Normalize", "IdentifyCommand", "ExtractDirection", "ExtractPrice", "ExtractLot", "ExtractSno", "Finalize" };
                foreach (var state in states) 
                { 
                    if (_ctx.IsAborted) break;
                    _seq.SetState(state); 
                    _seq.Run(); 
                }
                return _ctx.Results;
            }
        }

        protected virtual string OnNormalizeText(string rawText)
        {
            if (string.IsNullOrEmpty(rawText)) 
            {
                _ctx?.Abort("Raw text is empty.");
                return string.Empty;
            }
            // [v9.0] 소스 텍스트에서 이모지 제거 및 정규화
            string plainText = StripEmojis(rawText);
            return plainText.Replace("\uFF1A", ":").Trim();
        }

        private string StripEmojis(string text)
        {
            if (string.IsNullOrEmpty(text)) return text;
            // 범용 이모지 및 특수 심볼 제거 패턴
            string emojiPattern = @"[\u2600-\u27BF]|[\uD83C-\uDBFF\uDC00-\uDFFF]|[\u2B50-\u2B55]";
            return Regex.Replace(text, emojiPattern, "");
        }

        protected virtual void OnIdentifyCommand()
        {
            // [Manual Hint] XDataObject에 명시적인 CMD 힌트가 있는 경우 우선 적용
            if (_ctx!.Xdo.CMD == "CLOSE")
            {
                _ctx.Cmd = XCode.CLOSE;
                nlog.Debug($"[SIGNAL:DEBUG:PARSE] Forced CLOSE command by Manual Hint (CMD=CLOSE)");
                return;
            }

            // [v9.8.7] Exit 키워드 다중 검증: 반드시 등록된 키워드 중 일정 수 이상 감지되어야 CLOSE 판정 (False Positive 방지)
            int exitThreshold = Math.Min(2, Keywords.ExitKeywords.Count);
            int exitKeywordCount = Keywords.ExitKeywords.Count(k => Regex.IsMatch(_ctx.CleanText, Regex.Escape(k), RegexOptions.IgnoreCase));
            bool isExit = (exitThreshold > 0 && exitKeywordCount >= exitThreshold);
            
            // [v9.8.7] Entry 키워드 다중 검증: 반드시 등록된 키워드 중 일정 수 이상 감지되어야 OPEN 판정 (False Positive 방지)
            int entryThreshold = Math.Min(3, Keywords.EntryKeywords.Count);
            int entryKeywordCount = Keywords.EntryKeywords.Count(k => Regex.IsMatch(_ctx.CleanText, Regex.Escape(k), RegexOptions.IgnoreCase));
            bool isEntry = (entryThreshold > 0 && entryKeywordCount >= entryThreshold);
            
            bool hasBuy = Regex.IsMatch(_ctx.CleanText, BuyPattern, RegexOptions.IgnoreCase);
            bool hasSell = Regex.IsMatch(_ctx.CleanText, SellPattern, RegexOptions.IgnoreCase);
            bool hasSingleDir = hasBuy ^ hasSell;

            nlog.Debug($"[SIGNAL:DEBUG:PARSE] Identify: ExitCount={exitKeywordCount}, isExit={isExit}, EntryCount={entryKeywordCount}, isEntry={isEntry}, Buy={hasBuy}, Sell={hasSell}");

            // [v9.8.7] Exit 우선 순위 적용
            if (isExit)
            {
                _ctx.Cmd = XCode.CLOSE;
                return;
            }

            if (isEntry && hasSingleDir) _ctx.Cmd = XCode.OPEN;
            else if (isEntry) _ctx.Cmd = XCode.OPEN;
            else
            {
                _ctx.Abort("Failed to identify valid command or direction.");
            }
        }

        protected virtual void OnExtractPrice()
        {
            var match = Regex.Match(_ctx!.CleanText, PricePattern, RegexOptions.IgnoreCase);
            if (match.Success)
            {
                for (int i = 1; i < match.Groups.Count; i++)
                {
                    if (match.Groups[i].Success && double.TryParse(match.Groups[i].Value.Replace(",", ""), out double p))
                    {
                        _ctx.BaseSignal.price_signal = p;
                        break;
                    }
                }
            }
        }

        protected virtual void OnExtractDirection()
        {
            if (Regex.IsMatch(_ctx!.CleanText, BuyPattern, RegexOptions.IgnoreCase)) _ctx.BaseSignal.dir = XCode.BUY;
            else if (Regex.IsMatch(_ctx.CleanText, SellPattern, RegexOptions.IgnoreCase)) _ctx.BaseSignal.dir = XCode.SELL;
        }

        protected virtual void OnExtractLot()
        {
            var match = Regex.Match(_ctx!.CleanText, LotPattern, RegexOptions.IgnoreCase);
            if (match.Success)
            {
                for (int i = 1; i < match.Groups.Count; i++)
                {
                    if (match.Groups[i].Success && double.TryParse(match.Groups[i].Value, out double l))
                    {
                        _ctx.BaseSignal.lot = l;
                        break;
                    }
                }
            }
        }

        protected virtual void OnExtractSno()
        {
            // [v9.6] 복수 회차 및 변종 키워드(횟차, 차 정리 등) 인식 강화
            // [v10.1] 소수점 가격 뒤에 키워드가 오는 경우(예: 4482.61\n차) 오인식 방지 위해 Lookbehind 및 공백 제한 추가
            // [v10.3] 점(.) 구분 다중 회차(6.8회차)는 청산(CLOSE)시에만 허용. 진입(OPEN)시는 소수점 오인식 방지를 위해 제외.
            
            bool isClose = _ctx?.Cmd == XCode.CLOSE;
            string pattern1 = isClose ? @"(?<!\.)\b(\d+)[ \t]*(?:회차|차|횟차)" : @"(?<!\.)\b(\d+)[ \t]*(?:회차|차|횟차)"; // 1번은 동일
            string pattern2 = isClose ? @"(?<!\.)\b([\d, \t\.]+)[ \t]*(?:회차|차|횟차)" : @"(?<!\.)\b([\d, \t]+)[ \t]*(?:회차|차|횟차)";
            char[] splitDelims = isClose ? new[] { ',', ' ', '.' } : new[] { ',', ' ' };

            // 1. "N차 정리" 또는 "N회차" 형태 우선 추출 (이모지 제거된 상태: "횟차 : 15차 정리")
            var snoMatches = Regex.Matches(_ctx!.CleanText, pattern1, RegexOptions.IgnoreCase);
            foreach (Match m in snoMatches)
            {
                if (int.TryParse(m.Groups[1].Value, out int s)) _ctx.Snos.Add(s);
            }

            // 2. 콤마나 공백, 점으로 구분된 복수 회차 (예: "1, 2, 3회차" 또는 "6.8회차")
            // 개별 추출 결과가 있더라도 콤보 매치가 더 많은 회차를 포함할 수 있으므로 항상 시도 및 중복 방지
            var comboMatch = Regex.Match(_ctx.CleanText, pattern2, RegexOptions.IgnoreCase);
            if (comboMatch.Success)
            {
                var snoPart = comboMatch.Groups[1].Value;
                var snoStrings = snoPart.Split(splitDelims, StringSplitOptions.RemoveEmptyEntries);
                foreach (var sStr in snoStrings)
                {
                    if (int.TryParse(sStr.Trim(), out int s))
                    {
                        if (!_ctx.Snos.Contains(s)) _ctx.Snos.Add(s);
                    }
                }
            }

            // 3. Keywords.txt에 정의된 패턴 적용 (SnoPattern)
            if (_ctx.Snos.Count == 0)
            {
                var match = Regex.Match(_ctx.CleanText, SnoPattern, RegexOptions.IgnoreCase);
                if (match.Success)
                {
                    for (int i = 1; i < match.Groups.Count; i++)
                    {
                        if (match.Groups[i].Success && int.TryParse(match.Groups[i].Value, out int s))
                        {
                            _ctx.Snos.Add(s);
                            break;
                        }
                    }
                }
            }

            // 4. 숫자만 있는 경우나 기타 패턴 실패 시 기본값
            if (_ctx.Snos.Count == 0) _ctx.Snos.Add(XCode.SNO_DEFAULT);
            
            nlog.Debug($"[SIGNAL:DEBUG:PARSE] Extracted SNOs: {string.Join(", ", _ctx.Snos)}");
        }

        protected virtual void OnFinalize()
        {
            // [SRP: Recognition] 인텐트(Entry/Exit) 확정
            FinalizeIntent();

            // [SRP: Recognition] SID 힌트 추출
            ExtractSidHint();

            // [SRP: Execution] 회차별 신호 복제 및 결과 목록 생성
            GenerateFinalResults();
        }

        private void FinalizeIntent()
        {
            if (_ctx == null) return;
            _ctx.BaseSignal.cmd = _ctx.Cmd;
            if (_ctx.Cmd == XCode.CLOSE)
            {
                _ctx.BaseSignal.xa_exit = XCode.XA_ACTIVE;
            }
            else
            {
                _ctx.BaseSignal.xa_entry = XCode.XA_ACTIVE;
            }
        }

        private void ExtractSidHint()
        {
            if (_ctx == null) return;
            var sidMatch = Regex.Match(_ctx.RawText, @"sid:\s*([\w-]+)", RegexOptions.IgnoreCase);
            if (sidMatch.Success)
            {
                var hint = sidMatch.Groups[1].Value.Trim();
                if (XIdManager.Instance.IsValidSid(hint))
                {
                    _ctx.ManualSid = hint;
                }
            }
        }

        private void GenerateFinalResults()
        {
            if (_ctx == null) return;
            foreach (var sno in _ctx.Snos.Distinct())
            {
                var s = _ctx.BaseSignal.Clone();
                s.sno = sno;
                if (!string.IsNullOrEmpty(_ctx.ManualSid)) s.sid = _ctx.ManualSid;
                _ctx.Results.Add(s);
            }
        }

        public class KeywordConfig
        {
            public List<string> EntryKeywords { get; set; } = new();
            public List<string> ExitKeywords { get; set; } = new();
            public List<string> BuyKeywords { get; set; } = new();
            public List<string> SellKeywords { get; set; } = new();
            public List<string> PriceKeywords { get; set; } = new();
            public List<string> LotKeywords { get; set; } = new();
            public List<string> SnoKeywords { get; set; } = new();
        }

        private class KeywordConfigLegacy
        {
            public string[] EntryKeywords { get; set; } = Array.Empty<string>();
            public string[] ExitKeywords { get; set; } = Array.Empty<string>();
            public string[] BuyKeywords { get; set; } = Array.Empty<string>();
            public string[] SellKeywords { get; set; } = Array.Empty<string>();
            public string[] PriceKeywords { get; set; } = Array.Empty<string>();
            public string[] LotKeywords { get; set; } = Array.Empty<string>();
            public string[] SnoKeywords { get; set; } = Array.Empty<string>();
        }

        protected class ParsingContext
        {
            public XDataObject Xdo { get; }
            public XSignal BaseSignal { get; }
            public string RawText { get; }
            public string CleanText { get; set; } = string.Empty;
            public string Cmd { get; set; } = XCode.NONE;
            public bool IsAborted { get; private set; }
            public string AbortReason { get; private set; } = string.Empty;
            public List<int> Snos { get; } = new();
            public List<XSignal> Results { get; } = new();
            public string? ManualSid { get; set; }
            public ParsingContext(XDataObject xdo, XSignal baseSignal) { Xdo = xdo; BaseSignal = baseSignal; RawText = xdo.Text ?? string.Empty; }
            public void Abort(string reason) { IsAborted = true; AbortReason = reason; }
        }
    }
}
