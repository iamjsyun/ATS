using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using System;
using System.Threading.Tasks;
using XTA.Core;
using XTA.Models;

namespace ATSA.YouTube.Infrastructure
{
    public class YouTubeStartup
    {
        private static NLog.Logger nlog = NLog.LogManager.GetCurrentClassLogger();

        public static async Task RunAsync(string? configPath = null, Action<IServiceCollection>? extraServices = null)
        {
            var ctx = XContext.Instance;
            nlog.Trace("[ay:Startup] Starting ATSA.YouTube (ay) Host Startup...");

            try
            {
                // 1. 파라미터 초기화
                var parameter = new XParameter();
                ctx.Parameter = parameter;

                // 2. IHost 빌드 및 XContext 바인딩
                var host = YouTubeHostBuilder.Build(ctx.Parameter, configPath, extraServices);
                ctx.Initialize(host, ctx.Parameter);

                // 3. Host 실행 (백그라운드 서비스들 시작)
                await ctx.GetService<IHost>().StartAsync();

                // 4. 레거시 서비스 시작 (필요 시)
                ctx.Parameter.StartAll();

                nlog.Trace("[ay:Startup] ATSA.YouTube (ay) Startup completed successfully.");
            }
            catch (Exception ex)
            {
                nlog.Fatal(ex, $"[ay:Startup:FATAL] Host startup failed: {ex.Message}");
                throw;
            }
        }
    }
}
