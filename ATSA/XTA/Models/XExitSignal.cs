using DevExpress.Xpo;
using System;
using XTA.Infrastructure.Data;

namespace XTA.Models
{
    /// <summary>
    /// XTA 전용 청산 신호 모델 (Pure POCO 버전)
    /// </summary>
    public class XExitSignal
    {
        public string sid { get; set; } = string.Empty;
        public int magic { get; set; }
        public int sno { get; set; }
        public int gno { get; set; }
        public int type { get; set; }
        public int xa_status { get; set; }
        public int xe_status { get; set; }
        public string symbol { get; set; } = string.Empty;
        public int dir { get; set; }
        public double lot { get; set; }
        public long ticket { get; set; }
        public string comment { get; set; } = string.Empty;
        public DateTime created { get; set; }
        public DateTime updated { get; set; }
        public int cno { get; set; }
    }
}
