using System.Collections.Generic;
using System.Linq;

namespace XTA.Models
{
    /// <summary>
    /// 신호들을 논리적으로 그룹핑하기 위한 데이터 구조 (Pure POCO)
    /// </summary>
    public class XSignalGroup
    {
        public XSignal MasterSignal { get; set; } = null!;
        public List<XSignal> GridSignals { get; set; } = new List<XSignal>();
        public List<XSignal> HedgeSignals { get; set; } = new List<XSignal>();
        public List<XSignal> PendingSignals { get; set; } = new List<XSignal>();

        public string GroupGid
        {
            get
            {
                if (MasterSignal != null)
                {
                    if (!string.IsNullOrEmpty(MasterSignal.gid)) return MasterSignal.gid;
                    if (!string.IsNullOrEmpty(MasterSignal.sid) && MasterSignal.sid.Length >= 15)
                    {
                        int plusIdx = MasterSignal.sid.IndexOf('+');
                        if (plusIdx > 0) return MasterSignal.sid.Substring(0, plusIdx);
                        return MasterSignal.sid;
                    }
                }
                return "GROUP";
            }
        }

        public IEnumerable<XSignal> AllSignalsInOrder
        {
            get
            {
                var list = new List<XSignal>();
                if (MasterSignal != null) list.Add(MasterSignal);
                list.AddRange(GridSignals);
                list.AddRange(HedgeSignals);
                list.AddRange(PendingSignals);
                return list.OrderBy(s => s.gno);
            }
        }

        public XSignalGroup(XSignal masterSignal)
        {
            MasterSignal = masterSignal;
        }
    }
}
