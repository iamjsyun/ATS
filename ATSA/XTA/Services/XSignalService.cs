using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using NLog;
using XTA.Core;
using XTA.Interfaces;
using XTA.Models;
using XTA.Validation;
using FluentValidation.Results;

namespace XTA.Services
{
    /// <summary>
    /// 신호의 생명주기 관리, 식별자(SID/GID) 생성 및 최종 검증을 담당하는 서비스
    /// [v9.9] FluentSeq를 도입하여 Enrichment 5단계 (ID 생성, 패치, 중복 검사, 검증) 명확화
    /// [Partial] Core: 필드, 생성자, 그룹화 및 기본 검증 로직
    /// </summary>
    public partial class XSignalService : IXSignalService
    {
        private static readonly Logger nlog = LogManager.GetCurrentClassLogger();
        private readonly XSignalValidator _validator = new();

        private record EnrichContext(XDataObject Xdo, Models.XSignal CurrentSignal, bool IsDropped = false);

        public List<XSignalGroup> GroupSignals(List<Models.XSignal> signals)
        {
            if (signals == null || signals.Count == 0) return new List<XSignalGroup>();

            var groups = new Dictionary<string, XSignalGroup>();

            foreach (var s in signals)
            {
                if (string.IsNullOrEmpty(s.gid)) continue;

                if (!groups.ContainsKey(s.gid))
                {
                    var master = signals.FirstOrDefault(x => x.gid == s.gid && x.gno == XCode.GNO_MASTER) ?? s;
                    groups[s.gid] = new XSignalGroup(master);
                }

                var group = groups[s.gid];

                if (s.gno == XCode.GNO_MASTER)
                {
                    group.MasterSignal = s;
                }
                else if (s.type == XCode.TYPE_LIMIT || s.type == XCode.TYPE_STOP || s.type == XCode.TYPE_LIMIT_TRAILING)
                {
                    group.GridSignals.Add(s);
                }
                else if (s.xe_status == (int)XCode.EaStatus.Ready)
                {
                    group.PendingSignals.Add(s);
                }
                else
                {
                    group.HedgeSignals.Add(s);
                }
            }

            return groups.Values.ToList();
        }

        public ValidationResult Validate(Models.XSignal signal) => _validator.Validate(signal);
    }
}
