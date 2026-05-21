using System;
using XTA.Models;
using XTA.Channels.GlobalGold;

namespace XTA.Channels.XHANA
{
    /// <summary>
    /// XHANA uses GlobalGold's parsing logic.
    /// </summary>
    public class XHANA : GlobalGold.GlobalGold
    {
        public XHANA(XParameter param, XChannelInfo info) : base(param, info) { }

        // Force GlobalGold keyword loading
        protected override void LoadKeywords()
        {
            // We want to load from GlobalGold folder regardless of our class name
            LoadKeywordsForChannel("GlobalGold");
        }
    }
}
