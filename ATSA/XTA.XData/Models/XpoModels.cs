using DevExpress.Xpo;
using System;

namespace XTA.XData.Models
{
    [Persistent("signals")]
    public class XpoSignal : XPLiteObject
    {
        public XpoSignal(Session session) : base(session) { }

        [Key(true)]
        public long id { get => GetPropertyValue<long>(nameof(id)); set => SetPropertyValue(nameof(id), value); }

        [Size(50), Indexed(Unique = true)]
        public string sid { get => GetPropertyValue<string>(nameof(sid))!; set => SetPropertyValue(nameof(sid), value); }
        [Size(20)]
        public string gid { get => GetPropertyValue<string>(nameof(gid))!; set => SetPropertyValue(nameof(gid), value); }
        public int cno { get => GetPropertyValue<int>(nameof(cno)); set => SetPropertyValue(nameof(cno), value); }
        public int sno { get => GetPropertyValue<int>(nameof(sno)); set => SetPropertyValue(nameof(sno), value); }
        public int msg_id { get => GetPropertyValue<int>(nameof(msg_id)); set => SetPropertyValue(nameof(msg_id), value); }
        public int raw_id { get => GetPropertyValue<int>(nameof(raw_id)); set => SetPropertyValue(nameof(raw_id), value); }
        public int xa_entry { get => GetPropertyValue<int>(nameof(xa_entry)); set => SetPropertyValue(nameof(xa_entry), value); }
        public int xa_exit { get => GetPropertyValue<int>(nameof(xa_exit)); set => SetPropertyValue(nameof(xa_exit), value); }
        public int xe_status { get => GetPropertyValue<int>(nameof(xe_status)); set => SetPropertyValue(nameof(xe_status), value); }
        public void SetXeStatus(int value) => xe_status = value;
        [Size(SizeAttribute.Unlimited)]
        public string xe_status_msg { get => GetPropertyValue<string>(nameof(xe_status_msg))!; set => SetPropertyValue(nameof(xe_status_msg), value); }
        [Size(30)]
        public string time { get => GetPropertyValue<string>(nameof(time))!; set => SetPropertyValue(nameof(time), value); }
        [Size(20)]
        public string symbol { get => GetPropertyValue<string>(nameof(symbol))!; set => SetPropertyValue(nameof(symbol), value); }
        public int dir { get => GetPropertyValue<int>(nameof(dir)); set => SetPropertyValue(nameof(dir), value); }
        public int type { get => GetPropertyValue<int>(nameof(type)); set => SetPropertyValue(nameof(type), value); }
        public double price_signal { get => GetPropertyValue<double>(nameof(price_signal)); set => SetPropertyValue(nameof(price_signal), value); }
        public double te_start { get => GetPropertyValue<double>(nameof(te_start)); set => SetPropertyValue(nameof(te_start), value); }
        public double te_step { get => GetPropertyValue<double>(nameof(te_step)); set => SetPropertyValue(nameof(te_step), value); }
        public double te_limit { get => GetPropertyValue<double>(nameof(te_limit)); set => SetPropertyValue(nameof(te_limit), value); }
        public int te_interval { get => GetPropertyValue<int>(nameof(te_interval)); set => SetPropertyValue(nameof(te_interval), value); }
        public double ikte_start { get => GetPropertyValue<double>(nameof(ikte_start)); set => SetPropertyValue(nameof(ikte_start), value); }
        public double ikte_step { get => GetPropertyValue<double>(nameof(ikte_step)); set => SetPropertyValue(nameof(ikte_step), value); }
        public double tp { get => GetPropertyValue<double>(nameof(tp)); set => SetPropertyValue(nameof(tp), value); }
        public double sl { get => GetPropertyValue<double>(nameof(sl)); set => SetPropertyValue(nameof(sl), value); }
        public int ts_start { get => GetPropertyValue<int>(nameof(ts_start)); set => SetPropertyValue(nameof(ts_start), value); }
        public int ts_step { get => GetPropertyValue<int>(nameof(ts_step)); set => SetPropertyValue(nameof(ts_step), value); }
        public int close_type { get => GetPropertyValue<int>(nameof(close_type)); set => SetPropertyValue(nameof(close_type), value); }
        public double trail_price { get => GetPropertyValue<double>(nameof(trail_price)); set => SetPropertyValue(nameof(trail_price), value); }
        public double price_limit { get => GetPropertyValue<double>(nameof(price_limit)); set => SetPropertyValue(nameof(price_limit), value); }
        public double price { get => GetPropertyValue<double>(nameof(price)); set => SetPropertyValue(nameof(price), value); }
        public double price_open { get => GetPropertyValue<double>(nameof(price_open)); set => SetPropertyValue(nameof(price_open), value); }
        public double price_close { get => GetPropertyValue<double>(nameof(price_close)); set => SetPropertyValue(nameof(price_close), value); }
        public double price_tp { get => GetPropertyValue<double>(nameof(price_tp)); set => SetPropertyValue(nameof(price_tp), value); }
        public double price_sl { get => GetPropertyValue<double>(nameof(price_sl)); set => SetPropertyValue(nameof(price_sl), value); }
        public double lot { get => GetPropertyValue<double>(nameof(lot)); set => SetPropertyValue(nameof(lot), value); }
        public long ticket { get => GetPropertyValue<long>(nameof(ticket)); set => SetPropertyValue(nameof(ticket), value); }
        public long magic { get => GetPropertyValue<long>(nameof(magic)); set => SetPropertyValue(nameof(magic), value); }
        [Size(255)]
        public string comment { get => GetPropertyValue<string>(nameof(comment))!; set => SetPropertyValue(nameof(comment), value); }
        [Size(100)]
        public string tag { get => GetPropertyValue<string>(nameof(tag))!; set => SetPropertyValue(nameof(tag), value); }
        public DateTime created { get => GetPropertyValue<DateTime>(nameof(created)); set => SetPropertyValue(nameof(created), value); }
        public DateTime updated { get => GetPropertyValue<DateTime>(nameof(updated)); set => SetPropertyValue(nameof(updated), value); }
    }

    [Persistent("channel_options")]
    public class XpoChannelOption : XPLiteObject
    {
        public XpoChannelOption(Session session) : base(session) { }
        [Key(false)] public int cno { get => GetPropertyValue<int>(nameof(cno)); set => SetPropertyValue(nameof(cno), value); }
        [Size(100)] public string name { get => GetPropertyValue<string>(nameof(name))!; set => SetPropertyValue(nameof(name), value); }
        public bool is_buy_active { get => GetPropertyValue<bool>(nameof(is_buy_active)); set => SetPropertyValue(nameof(is_buy_active), value); }
        public bool is_sell_active { get => GetPropertyValue<bool>(nameof(is_sell_active)); set => SetPropertyValue(nameof(is_sell_active), value); }
        public double buy_entry_offset { get => GetPropertyValue<double>(nameof(buy_entry_offset)); set => SetPropertyValue(nameof(buy_entry_offset), value); }
        public double sell_entry_offset { get => GetPropertyValue<double>(nameof(sell_entry_offset)); set => SetPropertyValue(nameof(sell_entry_offset), value); }
        public double tp_points { get => GetPropertyValue<double>(nameof(tp_points)); set => SetPropertyValue(nameof(tp_points), value); }
        public double sl_points { get => GetPropertyValue<double>(nameof(sl_points)); set => SetPropertyValue(nameof(sl_points), value); }
        public double default_volume { get => GetPropertyValue<double>(nameof(default_volume)); set => SetPropertyValue(nameof(default_volume), value); }
        public int lot_strategy { get => GetPropertyValue<int>(nameof(lot_strategy)); set => SetPropertyValue(nameof(lot_strategy), value); }
        public double lot_value { get => GetPropertyValue<double>(nameof(lot_value)); set => SetPropertyValue(nameof(lot_value), value); }
        public double lot_rate { get => GetPropertyValue<double>(nameof(lot_rate)); set => SetPropertyValue(nameof(lot_rate), value); }
        public int grid_count { get => GetPropertyValue<int>(nameof(grid_count)); set => SetPropertyValue(nameof(grid_count), value); }
        public double grid_step { get => GetPropertyValue<double>(nameof(grid_step)); set => SetPropertyValue(nameof(grid_step), value); }
        public int ts_trigger { get => GetPropertyValue<int>(nameof(ts_trigger)); set => SetPropertyValue(nameof(ts_trigger), value); }
        public int ts_step { get => GetPropertyValue<int>(nameof(ts_step)); set => SetPropertyValue(nameof(ts_step), value); }
        public double ikte_start { get => GetPropertyValue<double>(nameof(ikte_start)); set => SetPropertyValue(nameof(ikte_start), value); }
        public double ikte_step { get => GetPropertyValue<double>(nameof(ikte_step)); set => SetPropertyValue(nameof(ikte_step), value); }
        public int gap_min { get => GetPropertyValue<int>(nameof(gap_min)); set => SetPropertyValue(nameof(gap_min), value); }
        public int type { get => GetPropertyValue<int>(nameof(type)); set => SetPropertyValue(nameof(type), value); }
        public DateTime at_updated { get => GetPropertyValue<DateTime>(nameof(at_updated)); set => SetPropertyValue(nameof(at_updated), value); }
    }

    [Persistent("grid_profiles")]
    public class XpoGridProfile : XPLiteObject
    {
        public XpoGridProfile(Session session) : base(session) { }
        [Key(true)] public int Oid { get; set; }
        [Indexed("dir", "gno", Unique = true)] public int cno { get; set; }
        public int dir { get; set; }
        public int gno { get; set; }
        public int type { get; set; }
        public int lot_type { get; set; }
        public double lot { get; set; }
        public double offset { get; set; }
        public double te_start { get; set; }
        public double te_step { get; set; }
        public int ts_start { get; set; }
        public int ts_step { get; set; }
        public double tp { get; set; }
        public double sl { get; set; }
        public int gap_min { get; set; }
    }

    [Persistent("signals_history")]
    public class XpoSignalHistory : XPLiteObject
    {
        public XpoSignalHistory(Session session) : base(session) { }
        [Key(true)] public long id { get => GetPropertyValue<long>(nameof(id)); set => SetPropertyValue(nameof(id), value); }
        [Size(50), Indexed(Unique = false)] public string sid { get => GetPropertyValue<string>(nameof(sid))!; set => SetPropertyValue(nameof(sid), value); }
        [Size(20)] public string gid { get => GetPropertyValue<string>(nameof(gid))!; set => SetPropertyValue(nameof(gid), value); }
        public int cno { get => GetPropertyValue<int>(nameof(cno)); set => SetPropertyValue(nameof(cno), value); }
        public int sno { get => GetPropertyValue<int>(nameof(sno)); set => SetPropertyValue(nameof(sno), value); }
        public int msg_id { get => GetPropertyValue<int>(nameof(msg_id)); set => SetPropertyValue(nameof(msg_id), value); }
        public int raw_id { get => GetPropertyValue<int>(nameof(raw_id)); set => SetPropertyValue(nameof(raw_id), value); }
        public int xa_entry { get => GetPropertyValue<int>(nameof(xa_entry)); set => SetPropertyValue(nameof(xa_entry), value); }
        public int xa_exit { get => GetPropertyValue<int>(nameof(xa_exit)); set => SetPropertyValue(nameof(xa_exit), value); }
        public int xe_status { get => GetPropertyValue<int>(nameof(xe_status)); set => SetPropertyValue(nameof(xe_status), value); }
        public void SetXeStatus(int value) => xe_status = value;
        [Size(SizeAttribute.Unlimited)] public string xe_status_msg { get => GetPropertyValue<string>(nameof(xe_status_msg))!; set => SetPropertyValue(nameof(xe_status_msg), value); }
        [Size(30)] public string time { get => GetPropertyValue<string>(nameof(time))!; set => SetPropertyValue(nameof(time), value); }
        [Size(20)] public string symbol { get => GetPropertyValue<string>(nameof(symbol))!; set => SetPropertyValue(nameof(symbol), value); }
        public int dir { get => GetPropertyValue<int>(nameof(dir)); set => SetPropertyValue(nameof(dir), value); }
        public int type { get => GetPropertyValue<int>(nameof(type)); set => SetPropertyValue(nameof(type), value); }
        public double price_signal { get => GetPropertyValue<double>(nameof(price_signal)); set => SetPropertyValue(nameof(price_signal), value); }
        public double te_start { get => GetPropertyValue<double>(nameof(te_start)); set => SetPropertyValue(nameof(te_start), value); }
        public double te_step { get => GetPropertyValue<double>(nameof(te_step)); set => SetPropertyValue(nameof(te_step), value); }
        public double te_limit { get => GetPropertyValue<double>(nameof(te_limit)); set => SetPropertyValue(nameof(te_limit), value); }
        public int te_interval { get => GetPropertyValue<int>(nameof(te_interval)); set => SetPropertyValue(nameof(te_interval), value); }
        public double ikte_start { get => GetPropertyValue<double>(nameof(ikte_start)); set => SetPropertyValue(nameof(ikte_start), value); }
        public double ikte_step { get => GetPropertyValue<double>(nameof(ikte_step)); set => SetPropertyValue(nameof(ikte_step), value); }
        public double tp { get => GetPropertyValue<double>(nameof(tp)); set => SetPropertyValue(nameof(tp), value); }
        public double sl { get => GetPropertyValue<double>(nameof(sl)); set => SetPropertyValue(nameof(sl), value); }
        public int ts_start { get => GetPropertyValue<int>(nameof(ts_start)); set => SetPropertyValue(nameof(ts_start), value); }
        public int ts_step { get => GetPropertyValue<int>(nameof(ts_step)); set => SetPropertyValue(nameof(ts_step), value); }
        public int close_type { get => GetPropertyValue<int>(nameof(close_type)); set => SetPropertyValue(nameof(close_type), value); }
        public double trail_price { get => GetPropertyValue<double>(nameof(trail_price)); set => SetPropertyValue(nameof(trail_price), value); }
        public double price_limit { get => GetPropertyValue<double>(nameof(price_limit)); set => SetPropertyValue(nameof(price_limit), value); }
        public double price { get => GetPropertyValue<double>(nameof(price)); set => SetPropertyValue(nameof(price), value); }
        public double price_open { get => GetPropertyValue<double>(nameof(price_open)); set => SetPropertyValue(nameof(price_open), value); }
        public double price_close { get => GetPropertyValue<double>(nameof(price_close)); set => SetPropertyValue(nameof(price_close), value); }
        public double price_tp { get => GetPropertyValue<double>(nameof(price_tp)); set => SetPropertyValue(nameof(price_tp), value); }
        public double price_sl { get => GetPropertyValue<double>(nameof(price_sl)); set => SetPropertyValue(nameof(price_sl), value); }
        public double lot { get => GetPropertyValue<double>(nameof(lot)); set => SetPropertyValue(nameof(lot), value); }
        public long ticket { get => GetPropertyValue<long>(nameof(ticket)); set => SetPropertyValue(nameof(ticket), value); }
        public long magic { get => GetPropertyValue<long>(nameof(magic)); set => SetPropertyValue(nameof(magic), value); }
        [Size(255)] public string comment { get => GetPropertyValue<string>(nameof(comment))!; set => SetPropertyValue(nameof(comment), value); }
        [Size(100)] public string tag { get => GetPropertyValue<string>(nameof(tag))!; set => SetPropertyValue(nameof(tag), value); }
        public DateTime created { get => GetPropertyValue<DateTime>(nameof(created)); set => SetPropertyValue(nameof(created), value); }
        public DateTime updated { get => GetPropertyValue<DateTime>(nameof(updated)); set => SetPropertyValue(nameof(updated), value); }
    }

    [Persistent("server_signals_raw")]
    public class XpoSignalRaw : XPLiteObject
    {
        public XpoSignalRaw(Session session) : base(session) { }
        [Key(true)] public int Oid { get; set; }
        [Persistent("symbol"), Size(20)] public string symbol { get; set; } = null!;
        [Persistent("dir")] public int dir { get; set; }
        [Persistent("type")] public int type { get; set; }
        [Persistent("price")] public double price { get; set; }
        [Persistent("lot")] public double lot { get; set; }
        [Persistent("sno")] public int sno { get; set; }
        [Persistent("raw_text"), Size(SizeAttribute.Unlimited)] public string raw_text { get; set; } = null!;
        [Persistent("created_at")] public DateTime created_at { get; set; } = DateTime.Now;
    }

    [Persistent("tg_message")]
    public class XpoTgMessage : XPObject
    {
        public XpoTgMessage() : base() { }
        public XpoTgMessage(Session session) : base(session) { }
        [Persistent("cid")] public long CID { get; set; }
        [Persistent("time")] public DateTime Time { get; set; }
        [Persistent("cno")] public int CNO { get; set; }
        [Persistent("text"), Size(SizeAttribute.Unlimited)] public string Text { get; set; } = string.Empty;
        [Persistent("status")] public int Status { get; set; }
        [Persistent("retry_count")] public int RetryCount { get; set; }
        [Persistent("created_at")] public DateTime CreatedAt { get; set; } = DateTime.Now;
    }

    [Persistent("signal_status_history")]
    public class XpoSignalStatusHistory : XPLiteObject
    {
        public XpoSignalStatusHistory(Session session) : base(session) { }

        [Key(true)]
        public long id { get => GetPropertyValue<long>(nameof(id)); set => SetPropertyValue(nameof(id), value); }

        [Indexed]
        public long ref_id { get => GetPropertyValue<long>(nameof(ref_id)); set => SetPropertyValue(nameof(ref_id), value); }

        [Size(50), Indexed]
        public string sid { get => GetPropertyValue<string>(nameof(sid))!; set => SetPropertyValue(nameof(sid), value); }

        public int xe_status { get => GetPropertyValue<int>(nameof(xe_status)); set => SetPropertyValue(nameof(xe_status), value); }
        public void SetXeStatus(int value) => xe_status = value;

        public DateTime time { get => GetPropertyValue<DateTime>(nameof(time)); set => SetPropertyValue(nameof(time), value); }

        public double price_signal { get => GetPropertyValue<double>(nameof(price_signal)); set => SetPropertyValue(nameof(price_signal), value); }
        public double price_open { get => GetPropertyValue<double>(nameof(price_open)); set => SetPropertyValue(nameof(price_open), value); }
        public double price_close { get => GetPropertyValue<double>(nameof(price_close)); set => SetPropertyValue(nameof(price_close), value); }
        public double tp { get => GetPropertyValue<double>(nameof(tp)); set => SetPropertyValue(nameof(tp), value); }
        public double sl { get => GetPropertyValue<double>(nameof(sl)); set => SetPropertyValue(nameof(sl), value); }

        public int ts_start { get => GetPropertyValue<int>(nameof(ts_start)); set => SetPropertyValue(nameof(ts_start), value); }
        public int ts_step { get => GetPropertyValue<int>(nameof(ts_step)); set => SetPropertyValue(nameof(ts_step), value); }
        
        public double te_start { get => GetPropertyValue<double>(nameof(te_start)); set => SetPropertyValue(nameof(te_start), value); }
        public double te_step { get => GetPropertyValue<double>(nameof(te_step)); set => SetPropertyValue(nameof(te_step), value); }
        public double lot { get => GetPropertyValue<double>(nameof(lot)); set => SetPropertyValue(nameof(lot), value); }

        [Size(SizeAttribute.Unlimited)]
        public string msg { get => GetPropertyValue<string>(nameof(msg))!; set => SetPropertyValue(nameof(msg), value); }
    }
}
