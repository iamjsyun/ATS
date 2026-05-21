using System.Collections.Generic;
using System.Threading.Tasks;
using XTA.Models;
using FluentValidation.Results;

namespace XTA.Interfaces
{
    /// <summary>
    /// 신호의 확장(Enrichment) 및 검증을 총괄하는 서비스 인터페이스
    /// </summary>
    public interface IXSignalService
    {
        /// <summary>
        /// 해석된 신호 데이터를 채널 정책에 따라 확장하고, SID/GID 생성 및 검증을 완료한 최종 신호 목록을 반환합니다.
        /// </summary>
        Task<List<XSignal>> PrepareSignalsAsync(XDataObject xdo);

        /// <summary>
        /// 평면적인 신호 목록을 GID 기준으로 논리적 그룹(XSignalGroup)으로 묶어 반환합니다.
        /// </summary>
        List<XSignalGroup> GroupSignals(List<XSignal> signals);

        /// <summary>
        /// 개별 신호에 대한 즉각적인 검증을 수행합니다.
        /// </summary>
        ValidationResult Validate(XSignal signal);
    }
}
