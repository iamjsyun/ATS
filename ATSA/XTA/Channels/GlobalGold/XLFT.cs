using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using XTA.Models;

namespace XTA.Channels.GG
{
    /// <summary>
    /// LFT 채널 해석기 (XRuleInterpreter 기반 리팩토링)
    /// </summary>
    public class XLFT : XRuleInterpreter
    {
        public XLFT(XParameter param, XChannelInfo info) : base(param, info) { }

        protected override string[] EntryKeywords => throw new NotImplementedException();

        protected override string[] ExitKeywords => throw new NotImplementedException();
    }
}
