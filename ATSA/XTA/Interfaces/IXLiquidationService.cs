using System.Threading.Tasks;
using XTA.Models;

namespace XTA.Interfaces
{
    /// <summary>
    /// 신호 청산 및 종료 로직을 전담하는 도메인 서비스 인터페이스
    /// </summary>
    public interface IXLiquidationService
    {
        /// <summary>
        /// 청산 명령(CLOSE)을 처리하여 대상 신호들을 청산 상태로 전환합니다.
        /// </summary>
        /// <param name="signal">청산 명령 정보</param>
        /// <param name="msgId">텔레그램 메시지 ID</param>
        Task ProcessLiquidationAsync(XSignal signal, int msgId);
    }
}
