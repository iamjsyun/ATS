using ILogger = NLog.ILogger;

namespace XTA.Models
{
    /// <summary>
    /// XTA 엔진 내 모든 서비스 및 채널 객체의 기본 클래스 (Pure POCO)
    /// </summary>
    public abstract class XObject
    {
        public XParameter param { get; private set; }
        public NLog.ILogger nlog { get; set; } = NLog.LogManager.GetCurrentClassLogger();

        public long CID { get; protected set; }
        public virtual int CNO { get; set; } = 0;

        protected XObject(XParameter param)
        {
            this.param = param;
        }

        protected XObject(XParameter param, long cid)
        {
            this.param = param;
            this.CID = cid;
        }

        public virtual void Start() { }
        public virtual void Stop() { }
    }
}
