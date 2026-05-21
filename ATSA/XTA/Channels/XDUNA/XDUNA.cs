using System;
using XTA.Models;
using XTA.Channels.GMK;

namespace XTA.Channels.XDUNA
{
    /// <summary>
    /// XDUNA uses GMK's parsing logic.
    /// </summary>
    public class XDUNA : GMK.GMK
    {
        public XDUNA(XParameter param, XChannelInfo info) : base(param, info) { }

        // Force GMK keyword loading
        protected override void LoadKeywords()
        {
            // We want to load from GMK folder regardless of our class name
            LoadKeywordsForChannel("GMK");
        }
    }
}
