using NLog;
using System;
using System.Threading.Tasks;

namespace XTA.Models
{
    public abstract class XChannelObject : XObject
    {
        private XChannelInfo _info = null!;
        public XChannelInfo Info
        {
            get => _info;
            protected set => _info = value;
        }

        public override int CNO => Info?.CNO ?? 0;

        protected XChannelObject(XParameter param, XChannelInfo info) : base(param, info.CID)
        {
            this.Info = info;
        }

        public virtual void ProcessSignal(XDataObject xdo) { }

        protected virtual async Task ProcessDataAsync(XDataObject xdo)
        {
            await Task.CompletedTask;
        }

        protected void LogCNO(int cno, LogLevel level, string message)
        {
            nlog?.Log(level, $"[CNO:{cno:D4}] {message}");
        }
    }
}
