using System.Threading.Tasks;
using XTA.Interfaces;
using ATSA.UI.Services;
using XTA.Core;

namespace ATSA.Services
{
    public class TelegramAuthService : ITelegramAuthService
    {
        public Task<string?> RequestVerificationCodeAsync(string phoneNumber)
        {
            var dialog = XContext.Instance.GetOptionalService<IDialogService>();
            if (dialog == null) return Task.FromResult<string?>(null);

            // WPF UI 스레드에서 다이얼로그를 띄워야 함
            if (System.Windows.Application.Current?.Dispatcher != null)
            {
                return System.Windows.Application.Current.Dispatcher.Invoke(() =>
                {
                    return Task.FromResult(dialog.Prompt($"Enter Telegram verification code sent to {phoneNumber}:", "Telegram Auth"));
                });
            }

            return Task.FromResult<string?>(null);
        }

        public Task<string?> RequestPasswordAsync()
        {
            var dialog = XContext.Instance.GetOptionalService<IDialogService>();
            if (dialog == null) return Task.FromResult<string?>(null);

            if (System.Windows.Application.Current?.Dispatcher != null)
            {
                return System.Windows.Application.Current.Dispatcher.Invoke(() =>
                {
                    return Task.FromResult(dialog.Prompt("Enter your Telegram 2FA password:", "Telegram 2FA"));
                });
            }

            return Task.FromResult<string?>(null);
        }
    }
}
