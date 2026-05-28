using XTA.XData.Models;

namespace XTA.XData.Models
{
    public static class Mappers
    {
        public static XSignal ToDomainModel(this XpoSignal xpo)
        {
            return new XSignal
            {
                sid = xpo.sid,
                // gid removed from domain model mapping
                cno = xpo.cno,
                sno = xpo.sno,
                gno = XIdManager.Instance.ExtractGnoFromSid(xpo.sid),
                msg_id = xpo.msg_id,
                raw_id = xpo.raw_id,
                xa_entry = xpo.xa_entry,
                xa_exit = xpo.xa_exit,
                xe_status = xpo.xe_status,
                xe_status_msg = xpo.xe_status_msg,
                time = xpo.time,
                symbol = xpo.symbol,
                dir = xpo.dir,
                type = xpo.type,
                price_signal = xpo.price_signal,
                te_start = xpo.te_start,
                te_step = xpo.te_step,
                te_limit = xpo.te_limit,
                te_interval = xpo.te_interval,
                ikte_start = xpo.ikte_start,
                ikte_step = xpo.ikte_step,
                tp = xpo.tp,
                sl = xpo.sl,
                // ts_start/ts_step, trail_price, price_limit removed from domain mapping
                close_type = xpo.close_type,
                price = xpo.price,
                price_open = xpo.price_open,
                price_close = xpo.price_close,
                price_tp = xpo.price_tp,
                price_sl = xpo.price_sl,
                lot = xpo.lot,
                ticket = xpo.ticket,
                magic = xpo.magic,
                comment = xpo.comment,
                tag = xpo.tag,
                created = xpo.created,
                updated = xpo.updated
            };
        }

        public static void ToXpoModel(this XSignal domain, XpoSignal xpo)
        {
            xpo.sid = domain.sid;
            // gid removed - domain gid ignored by XPO
            xpo.cno = domain.cno;
            xpo.sno = domain.sno;
            xpo.msg_id = domain.msg_id;
            xpo.raw_id = domain.raw_id;
            xpo.xa_entry = domain.xa_entry;
            xpo.xa_exit = domain.xa_exit;
            xpo.SetXeStatus(domain.xe_status);
            xpo.xe_status_msg = domain.xe_status_msg;
            xpo.time = domain.time;
            xpo.symbol = domain.symbol;
            xpo.dir = domain.dir;
            xpo.type = domain.type;
            xpo.price_signal = domain.price_signal;
            xpo.te_start = domain.te_start;
            xpo.te_step = domain.te_step;
            xpo.te_limit = domain.te_limit;
            xpo.te_interval = domain.te_interval;
            xpo.ikte_start = domain.ikte_start;
            xpo.ikte_step = domain.ikte_step;
            xpo.tp = domain.tp;
            xpo.sl = domain.sl;
            // ts_start/ts_step, trail_price, price_limit removed from XPO mapping
            xpo.close_type = domain.close_type;
            xpo.price = domain.price;
            xpo.price_open = domain.price_open;
            xpo.price_close = domain.price_close;
            xpo.price_tp = domain.price_tp;
            xpo.price_sl = domain.price_sl;
            xpo.lot = domain.lot;
            xpo.ticket = domain.ticket;
            xpo.magic = domain.magic;
            xpo.comment = domain.comment;
            xpo.tag = domain.tag;
            xpo.created = domain.created;
            xpo.updated = domain.updated;
        }

        public static XChannelOption ToDomainModel(this XpoChannelOption xpo)
        {
            return new XChannelOption
            {
                cno = xpo.cno,
                name = xpo.name,
                is_buy_active = xpo.is_buy_active,
                is_sell_active = xpo.is_sell_active,
                buy_entry_offset = xpo.buy_entry_offset,
                sell_entry_offset = xpo.sell_entry_offset,
                tp_points = (int)xpo.tp_points,
                sl_points = (int)xpo.sl_points,
                default_volume = xpo.default_volume,
                lot_strategy = xpo.lot_strategy.ToString(),
                lot_value = xpo.lot_value,
                lot_rate = xpo.lot_rate,
                grid_count = xpo.grid_count,
                grid_step = (int)xpo.grid_step,
                ts_trigger = xpo.ts_trigger,
                ts_step = xpo.ts_step,
                ikte_start = xpo.ikte_start,
                ikte_step = xpo.ikte_step,
                gap_min = xpo.gap_min,
                type = xpo.type.ToString(),
                at_updated = xpo.at_updated
            };
        }

        public static void ToXpoModel(this XChannelOption domain, XpoChannelOption xpo)
        {
            xpo.name = domain.name;
            xpo.is_buy_active = domain.is_buy_active;
            xpo.is_sell_active = domain.is_sell_active;
            xpo.buy_entry_offset = domain.buy_entry_offset;
            xpo.sell_entry_offset = domain.sell_entry_offset;
            xpo.tp_points = domain.tp_points;
            xpo.sl_points = domain.sl_points;
            xpo.default_volume = domain.default_volume;
            if (int.TryParse(domain.lot_strategy, out int ls)) xpo.lot_strategy = ls;
            xpo.lot_value = domain.lot_value;
            xpo.lot_rate = domain.lot_rate;
            xpo.grid_count = domain.grid_count;
            xpo.grid_step = domain.grid_step;
            xpo.ts_trigger = domain.ts_trigger;
            xpo.ts_step = domain.ts_step;
            xpo.gap_min = domain.gap_min;
            if (int.TryParse(domain.type, out int ty)) xpo.type = ty;
            xpo.at_updated = domain.at_updated;
        }

        public static XGridProfile ToDomainModel(this XpoGridProfile xpo)
        {
            return new XGridProfile
            {
                cno = xpo.cno,
                dir = xpo.dir,
                gno = xpo.gno,
                type = xpo.type,
                lot_type = xpo.lot_type,
                offset = xpo.offset,
                lot = xpo.lot,
                tp = xpo.tp,
                sl = xpo.sl,
                te_start = xpo.te_start,
                te_step = xpo.te_step,
                // ts_start/ts_step deprecated in grid profile mapping
                ts_start = 0,
                ts_step = 0,
                gap_min = xpo.gap_min
            };
        }

        public static void ToXpoModel(this XGridProfile domain, XpoGridProfile xpo)
        {
            xpo.cno = domain.cno;
            xpo.dir = domain.dir;
            xpo.gno = domain.gno;
            xpo.type = domain.type;
            xpo.lot_type = domain.lot_type;
            xpo.offset = domain.offset;
            xpo.lot = domain.lot;
            xpo.tp = domain.tp;
            xpo.sl = domain.sl;
            xpo.te_start = domain.te_start;
            xpo.te_step = domain.te_step;
            xpo.ts_start = domain.ts_start;
            xpo.ts_step = domain.ts_step;
            xpo.gap_min = domain.gap_min;
        }

        public static void ToHistoryModel(this XpoSignal source, XpoSignalHistory target)
        {
            target.sid = source.sid;
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
            target.tp = source.tp;
            target.sl = source.sl;
            // ts_start/ts_step deprecated; trail_price/price_limit removed
            target.close_type = source.close_type;
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
        }

        public static XTgMessage ToDomainModel(this XpoTgMessage xpo)
        {
            return new XTgMessage
            {
                Id = xpo.Oid,
                CID = xpo.CID,
                Time = xpo.Time,
                CNO = xpo.CNO,
                Text = xpo.Text,
                Status = xpo.Status
            };
        }

        public static XSignal ToDomainModel(this XpoSignalHistory xpo)
        {
            return new XSignal
            {
                sid = xpo.sid,
                cno = xpo.cno,
                sno = xpo.sno,
                gno = XIdManager.Instance.ExtractGnoFromSid(xpo.sid),
                msg_id = xpo.msg_id,
                raw_id = xpo.raw_id,
                xa_entry = xpo.xa_entry,
                xa_exit = xpo.xa_exit,
                xe_status = xpo.xe_status,
                xe_status_msg = xpo.xe_status_msg,
                time = xpo.time,
                symbol = xpo.symbol,
                dir = xpo.dir,
                type = xpo.type,
                price_signal = xpo.price_signal,
                te_start = xpo.te_start,
                te_step = xpo.te_step,
                te_limit = xpo.te_limit,
                te_interval = xpo.te_interval,
                ikte_start = xpo.ikte_start,
                ikte_step = xpo.ikte_step,
                tp = xpo.tp,
                sl = xpo.sl,
                // ts_start/ts_step deprecated in history mapping
                close_type = xpo.close_type,
                price = xpo.price,
                price_open = xpo.price_open,
                price_close = xpo.price_close,
                price_tp = xpo.price_tp,
                price_sl = xpo.price_sl,
                lot = xpo.lot,
                ticket = xpo.ticket,
                magic = xpo.magic,
                comment = xpo.comment,
                tag = xpo.tag,
                created = xpo.created,
                updated = xpo.updated
            };
        }
    }
}
