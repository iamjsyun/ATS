using System.Configuration;
using System.Data;
using System.IO;
using System.Windows;
using XTA;
using XTA.Models;

using Microsoft.Extensions.DependencyInjection;
using ATSA.Services;
using XTA.Services.TelegramService;

namespace ATSA
{
    /// <summary>
    /// Interaction logic for App.xaml
    /// </summary>
    public partial class App : Application
    {
        public static XParameter Param { get; private set; } = null!;

        protected override void OnStartup(StartupEventArgs e)
        {
            base.OnStartup(e);

            string? configPath = null;
            for (int i = 0; i < e.Args.Length; i++)
            {
                if (e.Args[i].Equals("-config", StringComparison.OrdinalIgnoreCase) && i + 1 < e.Args.Length)
                {
                    configPath = e.Args[i + 1];
                    break;
                }
            }

            // [v7.8] Service Assembly Startup (XTAStartupV2)
            Task.Run(async () =>
            {
                try
                {
                    await XTAStartupV2.RunAsync(configPath, services => {
                        // 1. UI 전용 서비스 등록
                        services.AddSingleton<ATSA.UI.Services.IDialogService, ATSA.UI.Services.DefaultDialogService>();
                        services.AddSingleton<XTA.Interfaces.ITelegramAuthService, ATSA.Services.TelegramAuthService>();

                        // 2. XTelegram을 XTelegramUI로 대체하여 UI 연동 기능 활성화
                        var ctx = XTA.Core.XContext.Instance;
                        ctx.Parameter.RemoveService<XTelegram>();

                        var uiTg = new XTelegramUI(ctx.Parameter);
                        ctx.Parameter.Add(uiTg);
                        services.AddSingleton<XTelegram>(uiTg);
                    });
                    
                    Param = XTA.Core.XContext.Instance.Parameter;
                    Param.nlog.Info("XTA Engine (V2) initialized with XTelegramUI.");

                    // 엔진 초기화 완료 후 UI 표시
                    Current.Dispatcher.Invoke(() =>
                    {
                        var mainWindow = new MainWindow();
                        mainWindow.Show();
                    });
                }
                catch (Exception ex)
                {
                    Current.Dispatcher.Invoke(() =>
                    {
                        MessageBox.Show($"XTA Engine (V2) 초기화 오류:\n{ex}", "Fatal Error", MessageBoxButton.OK, MessageBoxImage.Error);
                        Shutdown();
                    });
                }
            });
        }
    }
}
