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
            target.id = source.id;
            target.sid = source.sid;
            target.gid = source.gid;
            target.cno = source.cno;
            target.sno = source.sno;
            target.msg_id = source.msg_id;
            target.raw_id = source.raw_id;
            target.xa_entry = source.xa_entry;
            target.xa_exit = source.xa_exit;
            target.SetXeStatus(source.xe_status);
            target.xe_status_msg = source.xe_status_msg;
            target.time = source.time;
            target.symbol = source.symbol;
            target.dir = source.dir;
            target.type = source.type;
            target.price_signal = source.price_signal;
            target.te_start = source.te_start;
            target.te_step = source.te_step;
            target.te_limit = source.te_limit;
            target.te_interval = source.te_interval;
            target.ikte_start = source.ikte_start;
            target.ikte_step = source.ikte_step;
            target.tp = source.tp;
            target.sl = source.sl;
            target.ts_start = source.ts_start;
            target.ts_step = source.ts_step;
            target.close_type = source.close_type;
            target.trail_price = source.trail_price;
            target.price_limit = source.price_limit;
            target.price = source.price;
            target.price_open = source.price_open;
            target.price_close = source.price_close;
            target.price_tp = source.price_tp;
            target.price_sl = source.price_sl;
            target.lot = source.lot;
            target.ticket = source.ticket;
            target.magic = source.magic;
            target.comment = source.comment;
            target.tag = source.tag;
            target.created = source.created;
            target.updated = source.updated;
            target.cmd = source.cmd;
            target.args = source.args;
        }
    }
}
