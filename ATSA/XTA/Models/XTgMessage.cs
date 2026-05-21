using System;

namespace XTA.Models
{
    /// <summary>
    /// 텔레그램 메시지 모델 (Pure POCO 버전)
    /// </summary>
    public class XTgMessage
    {
        public int Oid { get; set; }
        public long CID { get; set; }
        public DateTime Time { get; set; }
        public int CNO { get; set; }
        public string Text { get; set; } = string.Empty;
        public int Status { get; set; }
        public int RetryCount { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
