using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using NLog.Extensions.Logging;
using System;
using System.IO;
using XTA.Core;
using XTA.Interfaces;
using XTA.Infrastructure.Data;
using XTA.Services;
using XTA.Models;
using XTA.Channels;
using XTA.XData.Interfaces;
using ATSA.YouTube.Services;

namespace ATSA.YouTube.Infrastructure
{
    public static class YouTubeHostBuilder
    {
        public static IHost Build(XParameter parameter, string? configPath = null, Action<IServiceCollection>? extraServices = null)
        {
            XConfig.EnsureExists(configPath);
            string finalConfigPath = XConfig.GetConfigPath();

            var host = Host.CreateDefaultBuilder()
                .ConfigureAppConfiguration((hostingContext, config) =>
                {
                    config.SetBasePath(AppContext.BaseDirectory);
                    config.AddJsonFile(finalConfigPath, optional: false, reloadOnChange: true);
                })
                .ConfigureLogging(logging =>
                {
                    logging.ClearProviders();
                    logging.AddNLog();
                })
                .ConfigureServices((hostContext, services) =>
                {
                    var nlog = NLog.LogManager.GetCurrentClassLogger();
                    var configuration = hostContext.Configuration;
                    var xConfig = configuration.Get<XConfig>();
                    if (xConfig != null)
                    {
                        nlog.Trace($"[ay:BOOT] Initializing YouTube Services for CNO Count: {xConfig.Channels.Count}");
                        parameter.Config = xConfig;
                    }

                    services.AddSingleton(parameter);

                    // 1. 인프라 서비스 (ATSA 본체와 동일한 DB 공유)
                    var dbService = new XpoSqliteService(parameter);
                    parameter.Add(dbService);
                    services.AddSingleton<XpoSqliteService>(dbService);
                    services.AddSingleton<ISignalRepository>(dbService);
                    nlog.Trace("[ay:BOOT] Infrastructure Services registered.");
                    
                    var dataSvc = new XDataService(parameter);
                    parameter.Add(dataSvc);
                    services.AddSingleton<IDataService>(dataSvc);
                    nlog.Trace("[ay:BOOT] XDataService registered.");

                    // 2. 도메인 서비스 (ATSA 본체 로직 통합)
                    services.AddSingleton<IXTradePolicyService, XTradePolicyService>();
                    services.AddSingleton<IXLiquidationService, XLiquidationService>();
                    services.AddSingleton<IXSignalService, XSignalService>();
                    nlog.Trace("[ay:BOOT] Domain Services registered.");
                    
                    var gateway = new XGatewayService(parameter);
                    parameter.Add(gateway);
                    services.AddSingleton<IXGatewayService>(gateway);
                    nlog.Trace("[ay:BOOT] XGatewayService registered.");

                    // 3. OCR 및 YouTube 전용 서비스
                    services.AddSingleton(xConfig?.System ?? new XEngineSystemSettings()); 
                    services.AddSingleton(new XOcrSettings()); 
                    services.AddSingleton<IOcrEngineService, OcrEngineService>();
                    nlog.Trace("[ay:BOOT] OCR & Engine Services registered.");

                    // 4. Interpreters 등록
                    if (xConfig != null)
                    {
                        foreach (var ch in xConfig.Channels)
                        {
                            if (string.IsNullOrEmpty(ch.Interpreter)) continue;

                            // YouTube 채널 정보 매핑
                            var info = new XChannelInfo(ch.ChannelId, ch.CNO, ch.Name, "TRADE");
                            XInterpreterBase? interpreter = null;

                            if (ch.Interpreter.Equals("GlobalGold", StringComparison.OrdinalIgnoreCase))
                                interpreter = new XTA.Channels.GlobalGold.GlobalGold(parameter, info);
                            else if (ch.Interpreter.Equals("GMK", StringComparison.OrdinalIgnoreCase))
                                interpreter = new XTA.Channels.GMK.GMK(parameter, info);
                            else if (ch.Interpreter.Equals("YouTubeVision", StringComparison.OrdinalIgnoreCase))
                                interpreter = new XTA.Channels.YouTubeVision.YouTubeVision(parameter, info);

                            if (interpreter != null)
                            {
                                parameter.Add(interpreter);
                                services.AddSingleton<XInterpreterBase>(interpreter);
                                nlog.Trace($"[ay:BOOT] Interpreter for {ch.Name} registered.");
                            }
                        }
                    }

                    // 5. 추가 서비스 등록
                    extraServices?.Invoke(services);
                })
                .Build();

            return host;
        }
    }
}
