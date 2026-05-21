using System.Threading.Tasks;

namespace XTA.Interfaces
{
    /// <summary>
    /// 텔레그램 인증 정보를 요청하는 인터페이스
    /// </summary>
    public interface ITelegramAuthService
    {
        Task<string?> RequestVerificationCodeAsync(string phoneNumber);
        Task<string?> RequestPasswordAsync();
    }
}
