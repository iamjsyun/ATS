using System;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using NLog.Extensions.Logging;
using XTA.Core;
using XTA.Interfaces;
using XTA.Infrastructure.Data;
using XTA.Infrastructure.Audio;
using XTA.Services;
using XTA.Services.TelegramService;
using XTA.Models;
using XTA.XData.Interfaces;
using XTA.Channels;
using System.IO;

namespace XTA
{
    /// <summary>
    /// .NET IHost 빌드를 담당하는 팩토리 클래스
    /// </summary>
    public static class XTAHostBuilder
    {
        public static IHost Build(XParameter parameter, string? configPath = null, Action<IServiceCollection>? extraServices = null)
        {
            // [v9.0] 설정 폴더 및 기본 파일 보장 (_config/ATSA.json 또는 custom path)
            XConfig.EnsureExists(configPath);
            string finalConfigPath = XConfig.GetConfigPath();

            var host = Host.CreateDefaultBuilder()
                .ConfigureAppConfiguration((hostingContext, config) =>
                {
                    config.SetBasePath(AppContext.BaseDirectory);
                    
                    if (Path.IsPathRooted(finalConfigPath))
                    {
                        config.AddJsonFile(finalConfigPath, optional: false, reloadOnChange: true);
                    }
                    else
                    {
                        config.AddJsonFile(finalConfigPath, optional: false, reloadOnChange: true);
                    }
                })
                .ConfigureLogging((hostContext, logging) =>
                {
                    logging.ClearProviders();
                    
                    // [v9.0] 로깅 정책 일원화: MS Logging은 모든 이벤트를 NLog로 전달(Trace)하고,
                    // 실제 필터링은 NLog.config의 rules 섹션에서만 관리함.
                    logging.SetMinimumLevel(Microsoft.Extensions.Logging.LogLevel.Trace);
                    logging.AddNLog();
                })
                .ConfigureServices((hostContext, services) =>
                {
                    var nlog = NLog.LogManager.GetCurrentClassLogger();
                    var configuration = hostContext.Configuration;
                    
                    // 1. Load XConfig from JSON and merge with existing parameter
                    var xConfig = configuration.Get<XConfig>();
                    if (xConfig != null) 
                    {
                        var dbPath = xConfig.System?.DatabaseFullPath ?? "ATS.db";
                        nlog.Trace($"[XTA:BOOT] Initializing Services with Config: {dbPath}");
                        parameter.Config = xConfig;
                        
                        // Dynamic Channel Registration from Config (Enabled only)
                        if (xConfig.Channels != null)
                        {
                        foreach (var ch in xConfig.Channels.Where(c => c.Enabled))
                        {
                            // Support new combined CInfo format: "CNO, ChannelId, DisplayName"
                            string displayName = string.Empty;
                            int cno = 0;
                            long cid = 0;
                            if (!string.IsNullOrWhiteSpace(ch.CInfo))
                            {
                                var parts = ch.CInfo.Split(',');
                                if (parts.Length >= 1) int.TryParse(parts[0].Trim(), out cno);
                                if (parts.Length >= 2) long.TryParse(parts[1].Trim(), out cid);
                                if (parts.Length >= 3) displayName = string.Join(",", parts.Skip(2)).Trim();
                            }
                            else
                            {
                                // Fallback for legacy fields if present on JSON
                                cno = ch.CNO;
                                cid = ch.ChannelId;
                                displayName = ch.Name ?? string.Empty;
                            }

                            var info = new XChannelInfo(cid, cno, displayName, "TRADE")
                            {
                                IsSoundEnabled = ch.SoundEnabled
                            };
                            parameter.RegisterChannel(info);
                        }
                        }
                    }

                    services.AddSingleton(parameter);

                    // 2. 인프라 서비스 (싱글톤)
                    var dbService = new XpoSqliteService(parameter);
                    parameter.Add(dbService);
                    services.AddSingleton<XpoSqliteService>(dbService);
                    services.AddSingleton<ISignalRepository>(dbService);
                    services.AddSingleton<IChannelOptionRepository>(dbService);
                    services.AddSingleton<IGridProfileRepository>(dbService);
                    nlog.Trace("[XTA:BOOT] Infrastructure Services (DB, Repo) registered.");
                    
                    var dataSvc = new XDataService(parameter);
                    parameter.Add(dataSvc);
                    services.AddSingleton<IDataService>(dataSvc);
                    nlog.Trace("[XTA:BOOT] XDataService registered.");
                    
                    // 3. 도메인 서비스
                    services.AddSingleton<IXTradePolicyService, XTradePolicyService>();
                    services.AddSingleton<IXLiquidationService, XLiquidationService>();
                    services.AddSingleton<IXSignalService, XSignalService>();
                    nlog.Trace("[XTA:BOOT] Domain Services (Policy, Liquidation, Signal) registered.");
                    
                    var gateway = new XGatewayService(parameter);
                    parameter.Add(gateway);
                    services.AddSingleton<IXGatewayService>(gateway);
                    nlog.Trace("[XTA:BOOT] XGatewayService registered.");

                    // 4. 알림 및 유틸리티
                    var sound = new XSoundService(parameter);
                    parameter.Add(sound);
                    services.AddSingleton<ISoundService>(sound);
                    
                    var tts = new XTtsService(parameter);
                    parameter.Add(tts);
                    services.AddSingleton<ITtsService>(tts);
                    nlog.Trace("[XTA:BOOT] Notify Services (Sound, TTS) registered.");

                    // 5. 백그라운드 워커
                    var sync = new XSyncWorker(parameter);
                    parameter.Add(sync);
                    services.AddSingleton(sync);
                    nlog.Trace("[XTA:BOOT] Background Worker registered.");
                    
                    // 6. 추가 서비스 등록 (오버라이드 허용)
                    extraServices?.Invoke(services);
                    
                    // 7. Interpreters (Source of Truth for Channels - Enabled only)
                        foreach (var ch in parameter.Config.Channels.Where(c => c.Enabled))
                    {
                        if (string.IsNullOrEmpty(ch.Interpreter)) continue;

                        var channelInfo = parameter.GetChannels(ch.ChannelId).FirstOrDefault(c => c.CNO == ch.CNO);
                        if (channelInfo == null) continue;

                        XInterpreterBase? interpreter = null;

                        // 명시적 해석기 매핑 (v9.6)
                        if (ch.Interpreter.Equals("GlobalGold", StringComparison.OrdinalIgnoreCase))
                            interpreter = new XTA.Channels.GlobalGold.GlobalGold(parameter, channelInfo);
                        else if (ch.Interpreter.Equals("GMK", StringComparison.OrdinalIgnoreCase))
                            interpreter = new XTA.Channels.GMK.GMK(parameter, channelInfo);
                        else if (ch.Interpreter.Equals("YouTubeVision", StringComparison.OrdinalIgnoreCase))
                            interpreter = new XTA.Channels.YouTubeVision.YouTubeVision(parameter, channelInfo);

                        if (interpreter != null)
                        {
                            parameter.Add(interpreter);
                            services.AddSingleton<XInterpreterBase>(interpreter);
                            nlog.Trace($"[XTA:BOOT] Interpreter for {channelInfo?.Name ?? ch.Name} ({ch.Interpreter}) registered.");
                        }
                    }
                })
                .Build();

            return host;
        }
    }
}
