using System;

namespace XTA.Models
{
    /// <summary>
    /// XTA 전용 신호 모델 (Pure POCO 버전)
    /// </summary>
    public class XSignal : XTA.XData.Models.XSignal
    {
        // DB 모델의 필드들을 그대로 유지하며, UI 알림 로직은 모두 제거됨.
        
        public void SetXeStatus(int value) => xe_status = value;

        public string? sid_date { get; set; }
        
        // [Refactor] UI 전용 필드는 ATSA 확장 클래스로 이동 예정이나, 
        // 하위 호환성을 위해 우선 남겨두되 바인딩 로직은 제거
        public bool isHighlight { get; set; }

        public XSignal Clone()
        {
            var clone = (XSignal)this.MemberwiseClone();
            return clone;
        }

        public static XSignal FromBase(XTA.XData.Models.XSignal baseSignal)
        {
            var xsignal = new XSignal();
            UpdateFromBase(xsignal, baseSignal);
            return xsignal;
        }

        public static void UpdateFromBase(XSignal target, XTA.XData.Models.XSignal source)
        {
            target.sid = source.sid;
            target.gid = source.gid;
            target.cno = source.cno;
            target.sno = source.sno;
            target.gno = source.gno;
            target.xa_entry = source.xa_entry;
            target.xa_exit = source.xa_exit;
            target.SetXeStatus(source.xe_status);
            target.xe_status_msg = source.xe_status_msg;
            target.symbol = source.symbol;
            target.dir = source.dir;
            target.price_signal = source.price_signal;
            target.price = source.price;
            target.price_open = source.price_open;
            target.price_close = source.price_close;
            target.lot = source.lot;
            target.ticket = source.ticket;
            target.updated = source.updated;
            target.time = source.time;
            target.msg_id = source.msg_id;
            target.type = source.type;
            target.tp = source.tp;
            target.sl = source.sl;
            target.limit_offset = source.limit_offset;
            target.te_start = source.te_start;
            target.te_step = source.te_step;
            target.ikte_start = source.ikte_start;
            target.ikte_step = source.ikte_step;
            target.gap_min = source.gap_min;
            target.ts_start = source.ts_start;
            target.ts_step = source.ts_step;
            target.cmd = source.cmd;
            target.args = source.args;
        }
    }
}
