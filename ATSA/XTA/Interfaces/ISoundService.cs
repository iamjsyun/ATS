using XTA.Models;

namespace XTA.Interfaces
{
    /// <summary>
    /// 사운드 및 알림 서비스 인터페이스
    /// </summary>
    public interface ISoundService
    {
        /// <summary>
        /// 사운드 재생 요청 (구 messenger.SendSound 대체)
        /// </summary>
        void PlaySound(XSignal? sig, string cmd, string text = "");
    }
}
