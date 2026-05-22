using System;
using System.Collections.Concurrent;
using System.Text.RegularExpressions;

namespace XTA.XData.Models
{
    /// <summary>
    /// [v8.2 Standard] SID 및 GID 생성, 검증, 중복 방지를 담당하는 단일 관리 클래스 (Singleton)
    /// Governance Rules 준수 및 메모리 기반 멱등성 가드 포함. 시스템 내 유일한 ID 권위자.
    /// </summary>
    public class XIdManager
    {
        private static readonly Lazy<XIdManager> _instance = new Lazy<XIdManager>(() => new XIdManager());
        public static XIdManager Instance => _instance.Value;

        private const string SEP = "-";
        
        // 최근 생성된 SID를 일시적으로 보관하여 동일 밀리초 내 중복 생성 방지
        private readonly ConcurrentDictionary<string, byte> _idCache = new ConcurrentDictionary<string, byte>();
        private readonly ConcurrentQueue<string> _evictionQueue = new ConcurrentQueue<string>();
        private readonly int _maxCacheSize = 1000;

        private XIdManager() { }

        /// <summary>
        /// 거버넌스 규칙에 따른 표준 SID 생성 (v8.2)
        /// Format: CNO(4)-YYMMDDHH(8)-SNO(2)-GNO(2)-DIR(1)-TYPE(1)
        /// </summary>
        public string GenerateSid(int cno, DateTime time, int sno, int gno, int dir = 0, int type = 0)
        {
            // 방향 및 타입 기본값 보정
            int vDir = (dir <= 0) ? 1 : dir;
            int vType = (type <= 0) ? 1 : type;

            string dateStr = time.ToString("yyMMddHH");
            string sid = string.Format("{0:D4}{1}{2}{1}{3:D2}{1}{4:D2}{1}{5}{1}{6}",
                cno, SEP, dateStr, sno, gno, vDir, vType);
            
            AddToCache(sid);
            return sid;
        }

        /// <summary>
        /// 거버넌스 규칙에 따른 표준 GID 생성 (v8.2)
        /// Format: CNO(4)-YYMMDDHH(8)-SNO(2)-GNO(2)
        /// </summary>
        public string GenerateGid(int cno, DateTime time, int sno, int gno)
        {
            string dateStr = time.ToString("yyMMddHH");
            return string.Format("{0:D4}{1}{2}{1}{3:D2}{1}{4:D2}", cno, SEP, dateStr, sno, gno);
        }

        /// <summary>
        /// SID/GID 내의 잘못된 구분자(#) 또는 중복 구분자(--)를 정문화된 하이픈(-)으로 정규화
        /// </summary>
        public string Normalize(string id)
        {
            if (string.IsNullOrEmpty(id)) return id;
            return id.Replace("#", SEP).Replace("--", SEP);
        }

        /// <summary>
        /// SID 유효성 검증 (Regex 기반)
        /// </summary>
        public bool IsValidSid(string sid)
        {
            if (string.IsNullOrEmpty(sid)) return false;
            // Format: 0000-00000000-00-00-0-0 (총 23자)
            return Regex.IsMatch(sid, @"^\d{4}-\d{8}-\d{2}-\d{2}-\d{1}-\d{1}$");
        }

        /// <summary>
        /// GID 유효성 검증
        /// </summary>
        public bool IsValidGid(string gid)
        {
            if (string.IsNullOrEmpty(gid)) return false;
            // Format: 0000-00000000-00-00 (총 19자)
            return Regex.IsMatch(gid, @"^\d{4}-\d{8}-\d{2}-\d{2}$");
        }

        /// <summary>
        /// SID에서 GNO(Grid Number) 추출 (DB 스키마 GNO 필드 삭제에 따른 동적 추론)
        /// Format: CNO(4)-YYMMDDHH(8)-SNO(2)-GNO(2)-DIR(1)-TYPE(1)
        /// </summary>
        public int ExtractGnoFromSid(string sid)
        {
            if (IsValidSid(sid))
            {
                var parts = sid.Split(SEP[0]);
                if (parts.Length >= 4 && int.TryParse(parts[3], out int gno))
                {
                    return gno;
                }
            }
            return 0;
        }

        private void AddToCache(string id)
        {
            if (_idCache.TryAdd(id, 0))
            {
                _evictionQueue.Enqueue(id);
                
                if (_evictionQueue.Count > _maxCacheSize)
                {
                    if (_evictionQueue.TryDequeue(out var oldId))
                    {
                        _idCache.TryRemove(oldId, out _);
                    }
                }
            }
        }
    }
}
