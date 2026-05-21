using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using NLog;
using XTA.Core;
using XTA.Interfaces;
using XTA.Models;
using XTA.XData.Interfaces;
using XTA.XData.Models;
using FluentSeq;

namespace XTA.Services
{
    public partial class XTradePolicyService : IXTradePolicyService
    {
        private static readonly Logger nlog = LogManager.GetCurrentClassLogger();

        private record PolicyContext(
            XDataObject Xdo,
            Models.XSignal MasterSignal,
            List<Models.XSignal> ResultSignals,
            XChannelConfig? MergedConfig = null,
            XDirectionOption? Policy = null,
            List<XGridProfile>? Profiles = null
        );
    }
}
