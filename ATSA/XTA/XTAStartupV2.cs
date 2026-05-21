using System;
using System.Threading.Tasks;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System.Linq;
using XTA.Core;
using XTA.Models;
using XTA.XData.Models;
using XTA.Infrastructure.Data;
using XTA.XData.Interfaces;

using Microsoft.Extensions.DependencyInjection;

namespace XTA
{
    /// <summary>
    /// .NET IHost 기반으로 고도화된 최종 XTA 스타트업 엔진
    /// </summary>
    public class XTAStartupV2
    {
        private static NLog.Logger nlog = NLog.LogManager.GetCurrentClassLogger();

        public static async Task RunAsync(string? configPath = null, Action<IServiceCollection>? extraServices = null)
        {
            // [v9.0] 로그 설정 최우선 초기화 (첫 로그부터 NLog.config 준수)
            XParameter.InitializeNLog();

            var ctx = XContext.Instance;
            nlog.Trace("[Startup] Starting XTA V2 Host Startup...");

            try
            {
                // 1. 파라미터 초기화
                nlog.Trace("[Startup] Initializing XParameter...");
                var parameter = new XParameter();
                ctx.Parameter = parameter;

                // 2. IHost 빌드 및 XContext 바인딩
                nlog.Trace("[Startup] Building Standard Host...");
                var host = XTAHostBuilder.Build(ctx.Parameter, configPath, extraServices);
                ctx.Initialize(host, ctx.Parameter);

                // 3. Host 실행 (백그라운드 서비스들 시작)
                nlog.Trace("[Startup] Starting IHost...");
                var hostService = ctx.GetService<IHost>();
                if (hostService != null)
                {
                    await hostService.StartAsync();
                }
                else
                {
                    nlog.Warn("[Startup] IHost is null. Cannot start background services.");
                }

                // 4. 기존 XObject 기반 서비스들 시작 (호환성 유지)
                nlog.Trace("[Startup] Starting Legacy Services...");
                ctx.Parameter.StartAll();

                // [Debug] 등록된 채널 목록 로그 기록
                nlog.Trace("--- [Registered TG Channels] ---");
                foreach (var list in ctx.Parameter.Channels.Values)
                {
                    foreach (var info in list)
                    {
                        nlog.Trace($"CID: {info.CID} | CNO: {info.CNO} | Name: {info.Name}");
                    }
                }
                nlog.Trace("--------------------------------");

                nlog.Trace("[Startup] XTA V2 Host Startup completed successfully.");
            }
            catch (Exception ex)
            {
                nlog.Fatal(ex, $"[Startup:FATAL] Host startup failed: {ex.Message}");
                throw;
            }
        }

        /// <summary>
        /// 데이터 이관 작업
        /// </summary>
        public static async Task ProcessTransferAsync()
        {
            var ctx = XContext.Instance;
            nlog.Trace("[Transfer] Starting Data Transfer Protocol (v7.9)...");

            try
            {
                // [v9.8.5] 상태 마킹(XA_CLOSED_COMPLETED -> XA_ARCHIVE_READY)은 
                // XSyncWorker의 MonitorClose 상태에서 전담하므로 여기서는 물리적 이관(Archival)만 호출함.
                var dbSvc = ctx.Parameter.GetService<XpoSqliteService>();
                if (dbSvc != null)
                {
                    await dbSvc.ArchiveSignalsInternal();
                    nlog.Trace("[Transfer] ArchiveSignalsInternal executed.");
                }

                nlog.Trace("[Transfer] Data Transfer Protocol cycle completed.");
            }
            catch (Exception ex)
            {
                nlog.Error(ex, $"[Transfer:ERROR] Data transfer failed: {ex.Message}");
            }
        }
    }
}
