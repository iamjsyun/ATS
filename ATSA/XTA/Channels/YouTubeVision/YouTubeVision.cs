using System;
using System.Linq;
using XTA.Models;
using XTA.XData.Models;

namespace XTA.Channels.YouTubeVision
{
    /// <summary>
    /// YouTube Vision Channel Interpreter (Generic for YouTube OCR)
    /// </summary>
    public class YouTubeVision : XRuleInterpreter
    {
        public YouTubeVision(XParameter param, XChannelInfo info) : base(param, info) { }

        protected override void OnIdentifyCommand()
        {
            if (_ctx == null) return;

            // [Manual Hint]
            if (_ctx.Xdo.CMD == "CLOSE")
            {
                _ctx.Cmd = XCode.CLOSE;
                return;
            }

            // YouTube OCR 특성상 텍스트가 짧고 명확하므로 1개 이상의 키워드만으로 판정 (v9.8.7 기준 3개는 너무 엄격함)
            int exitKeywordCount = Keywords.ExitKeywords.Count(k => System.Text.RegularExpressions.Regex.IsMatch(_ctx.CleanText, System.Text.RegularExpressions.Regex.Escape(k), System.Text.RegularExpressions.RegexOptions.IgnoreCase));
            bool isExit = (exitKeywordCount >= 1);

            int entryKeywordCount = Keywords.EntryKeywords.Count(k => System.Text.RegularExpressions.Regex.IsMatch(_ctx.CleanText, System.Text.RegularExpressions.Regex.Escape(k), System.Text.RegularExpressions.RegexOptions.IgnoreCase));
            bool isEntry = (entryKeywordCount >= 1);

            bool hasBuy = Keywords.BuyKeywords.Any(k => System.Text.RegularExpressions.Regex.IsMatch(_ctx.CleanText, System.Text.RegularExpressions.Regex.Escape(k), System.Text.RegularExpressions.RegexOptions.IgnoreCase));
            bool hasSell = Keywords.SellKeywords.Any(k => System.Text.RegularExpressions.Regex.IsMatch(_ctx.CleanText, System.Text.RegularExpressions.Regex.Escape(k), System.Text.RegularExpressions.RegexOptions.IgnoreCase));

            if (isExit)
            {
                _ctx.Cmd = XCode.CLOSE;
            }
            else if (isEntry && (hasBuy || hasSell))
            {
                _ctx.Cmd = XCode.OPEN;
            }
            else
            {
                _ctx.Abort("YouTubeVision: Failed to identify command or direction with relaxed rules.");
            }
        }
    }
}
