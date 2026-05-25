using System;
using System.Collections.Generic;

namespace XTA.XData.Models
{
    /// <summary>
    /// [v9.8 Standard] 신호 엔티티 도메인 모델.
    /// [v8.2 Governance] ID 생성 및 검증 로직 포함.
    /// </summary>
    public class XSignal
    {
        public int id { get; set; }
        public string sid { get; set; } = string.Empty;
        public string gid { get; set; } = string.Empty;
        public int cno { get; set; }
        public int sno { get; set; }
        public int gno { get; set; }

        public int msg_id { get; set; }
        public int raw_id { get; set; }
        public int xa_entry { get; set; }
        public int xa_exit { get; set; }
        public int xe_status { get; set; }
        public string xe_status_msg { get; set; } = string.Empty;
        public string time { get; set; } = string.Empty;
        public string symbol { get; set; } = "";
        public int dir { get; set; }
        public int type { get; set; }
        public double price_signal { get; set; }
        public double te_start { get; set; }
        public double te_step { get; set; }
        public double te_limit { get; set; }
        public int te_interval { get; set; }
        public double ikte_start { get; set; }
        public double ikte_step { get; set; }
        public double tp { get; set; }
        public double sl { get; set; }
        public int ts_start { get; set; } = 500;
        public int ts_step { get; set; } = 100;
        public int close_type { get; set; }
        public double trail_price { get; set; }
        public double price_limit { get; set; }
        public double price { get; set; }
        public double price_open { get; set; }
        public double price_close { get; set; }
        public double price_tp { get; set; }
        public double price_sl { get; set; }
        public double lot { get; set; }
        public long ticket { get; set; }
        public long magic { get; set; }
        public string comment { get; set; } = string.Empty;
        public string tag { get; set; } = string.Empty;
        public DateTime created { get; set; } = DateTime.Now;
        public DateTime updated { get; set; } = DateTime.Now;

        public bool Validate()
        {
            if (created == DateTime.MinValue) created = DateTime.Now;
            updated = DateTime.Now;

            // 정규화 (Normalization)
            if (!string.IsNullOrEmpty(symbol))
            {
                // '#' 등 기호를 제거하지 않고 대문자화 및 공백 제거만 수행
                symbol = symbol.ToUpper().Trim();
            }

            if (xe_status < (int)XCode.EaStatus.Closed_Signal)
            {
                xe_status = (int)XCode.EaStatus.Ready;    // 0
            }

            int dirVal = (dir == 2) ? 2 : 1; // v7.5 Standard: 1=BUY, 2=SELL
            if (type <= 0) type = 1;

            // ID 생성 및 정규화 (거버넌스 규칙 준수: XIdManager 통합)
            if (string.IsNullOrEmpty(sid) || !XIdManager.Instance.IsValidSid(sid))
            {
                // [v8.2] gno 필드를 직접 사용하여 SID 생성
                sid = XIdManager.Instance.GenerateSid(cno, created, sno, gno, dirVal, type);
            }
            
            sid = XIdManager.Instance.Normalize(sid);

            if (string.IsNullOrEmpty(gid) || !XIdManager.Instance.IsValidGid(gid))
            {
                // [v8.2] gno 필드를 직접 사용하여 GID 생성
                gid = XIdManager.Instance.GenerateGid(cno, created, sno, gno);
            }
            
            gid = XIdManager.Instance.Normalize(gid);

            if (string.IsNullOrEmpty(comment))
            {
                comment = sid;
            }

            return true;
        }
    }

    public class XChannelOption
    {
        public int cno { get; set; }
        public string name { get; set; } = string.Empty;
        public bool is_buy_active { get; set; }
        public bool is_sell_active { get; set; }
        public double buy_entry_offset { get; set; }
        public double sell_entry_offset { get; set; }
        public int tp_points { get; set; }
        public int sl_points { get; set; }
        public double default_volume { get; set; }
        public string lot_strategy { get; set; } = string.Empty;
        public double lot_value { get; set; }
        public double lot_rate { get; set; }
        public int grid_count { get; set; }
        public int grid_step { get; set; }
        public int ts_trigger { get; set; }
        public int ts_step { get; set; }
        public double ikte_start { get; set; }
        public double ikte_step { get; set; }
        public int gap_min { get; set; }
        public string type { get; set; } = string.Empty;
        public DateTime at_updated { get; set; }
    }

    public class XGridProfile
    {
        public int cno { get; set; }
        public int dir { get; set; }
        public int gno { get; set; }
        public int type { get; set; }
        public int lot_type { get; set; }
        public double offset { get; set; }
        public double lot { get; set; }
        public double tp { get; set; }
        public double sl { get; set; }
        public double te_start { get; set; }
        public double te_step { get; set; }
        public int ts_start { get; set; }
        public int ts_step { get; set; }
        public double ikte_start { get; set; }
        public double ikte_step { get; set; }
        public int gap_min { get; set; } = 200;
    }

    public class XTgMessage
    {
        public long Id { get; set; }
        public long CID { get; set; }
        public DateTime Time { get; set; }
        public int CNO { get; set; }
        public string Text { get; set; } = string.Empty;
        public int Status { get; set; }
    }
}
