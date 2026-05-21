using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using XTA.Models;

namespace XTA.Channels.GlobalGold
{
    /// <summary>
    /// GlobalGold Channel Interpreter
    /// </summary>
    public class GlobalGold : XRuleInterpreter
    {
        public GlobalGold(XParameter param, XChannelInfo info) : base(param, info) { }
        protected override string[] EntryKeywords => Keywords.EntryKeywords.ToArray();
        protected override string[] ExitKeywords => Keywords.ExitKeywords.ToArray();

        protected override string OnNormalizeText(string rawText)
        {
            if (string.IsNullOrEmpty(rawText)) return string.Empty;

            // Strip emojis to clean up text before regex matching
            // [Fix] Corrected regex to avoid stripping digits (0-9) and 'F'
            string pattern = @"[\u2600-\u27BF]|[\uD83C-\uDBFF\uDC00-\uDFFF]";
            string result = Regex.Replace(rawText, pattern, "");

            var lines = result.Split(new[] { "\r\n", "\r", "\n" }, StringSplitOptions.None)
                             .Select(line => line.Trim())
                             .Where(line => !string.IsNullOrWhiteSpace(line));

            return string.Join(Environment.NewLine, lines);
        }

        protected override void OnIdentifyCommand()
        {
            base.OnIdentifyCommand();
        }

        protected override void OnExtractDirection()
        {
            base.OnExtractDirection();
        }

        protected override void OnExtractPrice()
        {
            base.OnExtractPrice();
        }

        protected override void OnExtractLot()
        {
            base.OnExtractLot();
        }

        protected override void OnExtractSno()
        {
            base.OnExtractSno();
        }

        protected override void OnFinalize()
        {
            base.OnFinalize();
        }
    }
}
