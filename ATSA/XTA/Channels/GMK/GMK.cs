using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using XTA.Models;

namespace XTA.Channels.GMK
{
    /// <summary>
    /// GMK Channel Interpreter
    /// </summary>
    public class GMK : XRuleInterpreter
    {
        public GMK(XParameter param, XChannelInfo info) : base(param, info) { }

        protected override string[] EntryKeywords => Keywords.EntryKeywords.ToArray();
        protected override string[] ExitKeywords => Keywords.ExitKeywords.ToArray();

        protected override string OnNormalizeText(string rawText)
        {
            return base.OnNormalizeText(rawText);
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
