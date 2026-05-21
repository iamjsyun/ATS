using System.Threading.Tasks;
using XTA.Models;

namespace XTA.Interfaces
{
    /// <summary>
    /// 데이터 지속성 및 DB 관련 서비스 인터페이스
    /// </summary>
    public interface IDataService
    {
        /// <summary>
        /// 신호 저장 (구 messenger.SendDbSaveSignal 대체)
        /// </summary>
        Task SaveSignalAsync(XSignal sig);

        /// <summary>
        /// 메시지 원문 저장 (구 messenger.SendDbSaveMsg 대체)
        /// </summary>
        Task SaveMessageAsync(XDataObject xdo);

        /// <summary>
        /// 신호 이관 실행 (구 DB_MANUAL_TRANSFER 대체)
        /// </summary>
        Task ArchiveSignalsAsync();
    }
}
