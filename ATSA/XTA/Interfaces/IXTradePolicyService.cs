using System.Collections.Generic;
using System.Threading.Tasks;
using XTA.Models;

namespace XTA.Interfaces
{
    /// <summary>
    /// 채널 옵션 및 그리드 프로파일 정책을 적용하는 도메인 서비스 인터페이스
    /// </summary>
    public interface IXTradePolicyService
    {
        /// <summary>
        /// 수신된 기본 신호에 채널별 옵션(TP/SL, 활성여부) 및 그리드 프로파일을 적용하여 실제 실행 신호 목록을 생성합니다.
        /// </summary>
        Task<List<XSignal>> ApplyPolicyAsync(XDataObject xdo);
    }
}
