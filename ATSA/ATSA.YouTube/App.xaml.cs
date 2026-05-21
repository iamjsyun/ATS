using System;
using System.Threading.Tasks;
using System.Windows;
using ATSA.YouTube.Infrastructure;
using XTA.Core;
using XTA.Models;
using Microsoft.Extensions.DependencyInjection;

namespace ATSA.YouTube
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

            // [v9.0] ay 전용 Startup 엔진 실행
            Task.Run(async () =>
            {
                try
                {
                    await YouTubeStartup.RunAsync(configPath, services => 
                    {
                        // ay 전용 추가 서비스 등록 가능
                    });

                    Param = XContext.Instance.Parameter;
                    Param.nlog.Info("ATSA.YouTube (ay) Engine initialized.");

                    // UI 스레드에서 메인 윈도우 실행
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
                        MessageBox.Show($"ATSA.YouTube 엔진 초기화 오류:\n{ex}", "Fatal Error", MessageBoxButton.OK, MessageBoxImage.Error);
                        Shutdown();
                    });
                }
            });
        }
    }
}
