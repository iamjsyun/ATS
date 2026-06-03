using Microsoft.Extensions.Configuration;
using NLog;
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using XTA.Services.TelegramService;

namespace XTA.Models
{
    /// <summary>
    /// 시스템 전역 파라미터 및 서비스 로케이터.
    /// [Thread-Safe] 모든 서비스 및 채널 관리에 Concurrent 컬렉션을 사용함.
    /// </summary>
    public class XParameter
    {
        public NLog.ILogger nlog { get; set; } = NLog.LogManager.GetCurrentClassLogger();
        public XConfig Config { get; set; } = new();
        
        // [Refactor] ConcurrentDictionary의 키를 string으로 변경하여 동일 타입의 다중 인스턴스(해석기 등) 지원
        private readonly ConcurrentDictionary<string, XObject> _services = new();
        
        public readonly ConcurrentDictionary<long, List<XChannelInfo>> Channels = new ConcurrentDictionary<long, List<XChannelInfo>>();
        public readonly ConcurrentDictionary<int, XChannelOption> ChannelOptions = new ConcurrentDictionary<int, XChannelOption>();

        public XParameter()
        {
            try
            {
                InitializeNLog();
                nlog = LogManager.GetCurrentClassLogger();

                // 2. ATSA.json 설정 로드 (_config 폴더)
                string configPath = XConfig.GetConfigPath();
                if (File.Exists(configPath))
                {
                    var builder = new ConfigurationBuilder()
                        .SetBasePath(Path.GetDirectoryName(configPath)!)
                        .AddJsonFile("ATSA.json", optional: true, reloadOnChange: true);

                    var configuration = builder.Build();
                    Config = configuration.Get<XConfig>() ?? new XConfig();
                    nlog.Trace($"[XParameter] Configuration loaded from ATSA.json. DB Path: {Config.System?.DatabaseFullPath}");
                }
                else
                {
                    nlog.Warn($"[XParameter] ATSA.json not found at {configPath}. Using defaults.");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[FATAL] Initialization failed: {ex.Message}");
            }
        }

        public static void InitializeNLog()
        {
            // [v9.0] 로그 파일 초기화 (시작 시 기존 로그 삭제)
            InitializeLogs();

            string baseDir = AppDomain.CurrentDomain.BaseDirectory;
            string nlogPath = Path.Combine(baseDir, "NLog.config");
            if (File.Exists(nlogPath))
            {
                LogManager.Configuration = new NLog.Config.XmlLoggingConfiguration(nlogPath);
                LogManager.ReconfigExistingLoggers();
                LogManager.GetCurrentClassLogger().Trace($"[NLog] Initialized from {nlogPath}");
            }
        }

        private static void InitializeLogs()
        {
            try
            {
                string baseDir = AppDomain.CurrentDomain.BaseDirectory;
                string logDir = Path.Combine(baseDir, "_log");

                if (Directory.Exists(logDir))
                {
                    var files = Directory.GetFiles(logDir, "*.log");
                    foreach (var file in files)
                    {
                        try { File.Delete(file); } 
                        catch { /* 사용 중인 파일은 건너뜀 */ }
                    }
                }
                else
                {
                    Directory.CreateDirectory(logDir);
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[LogInit:FAIL] {ex.Message}");
            }
        }

        public void Add(XObject service)
        {
            if (service == null) return;
            
            // [v9.6] 타입과 CNO/CID를 조합하여 유니크한 키 생성 (동일 타입 다중 인스턴스 지원)
            string key = service.GetType().FullName + "_" + service.CNO + "_" + service.CID;
            
            // XTelegram 계열은 호환성을 위해 고정 키 사용 (Singleton 보장)
            if (service is XTelegram) key = typeof(XTelegram).FullName!;

            _services.AddOrUpdate(key, service, (k, v) => service);

            nlog?.Trace($"[ServiceRegistered] {service.GetType().Name} (Key: {key})");
        }

        public void Add<T>(T service) where T : class
        {
            if (service is XObject xobj) Add(xobj);
        }

        public void RemoveService<T>() where T : class
        {
            string typeName = typeof(T).FullName!;
            var keysToRemove = _services.Keys.Where(k => k.StartsWith(typeName)).ToList();
            foreach (var key in keysToRemove)
            {
                _services.TryRemove(key, out _);
            }
            nlog?.Trace($"[ServiceRemoved] {typeof(T).Name}");
        }

        public void StartAll()
        {
            nlog?.Trace($"[ServicesStarting] Attempting to start {_services.Count} services...");
            foreach (var service in _services.Values)
            {
                try
                {
                    nlog?.Trace($"[Service:Start:Begin] {service.GetType().Name} (CNO: {service.CNO}, CID: {service.CID})");
                    service.Start();
                    nlog?.Trace($"[Service:Start:End] {service.GetType().Name} - SUCCESS");
                }
                catch (Exception ex)
                {
                    nlog?.Error(ex, $"[Service:Start:Error] {service.GetType().Name} - FAILED");
                }
            }
            nlog?.Trace("[ServicesStarted] All registered services have been processed.");
        }

        public void StopAll()
        {
            foreach (var service in _services.Values)
            {
                service.Stop();
            }
            nlog?.Trace("[ServicesStopped] All registered services have been stopped.");
        }

        public T? GetService<T>() where T : class
        {
            return _services.Values.OfType<T>().FirstOrDefault();
        }

        public T? GetService<T>(Predicate<T> filter) where T : class
        {
            return _services.Values.OfType<T>().FirstOrDefault(t => filter(t));
        }

        public IEnumerable<T> GetServices<T>() where T : class
        {
            return _services.Values.OfType<T>();
        }

        public void RegisterChannel(XChannelInfo info)
        {
            if (info == null) return;
            var list = Channels.GetOrAdd(info.CID, _ => new List<XChannelInfo>());
            lock (list)
            {
                if (!list.Any(c => c.CNO == info.CNO))
                {
                    list.Add(info);
                }
            }
            nlog?.Trace($"[ChannelRegistered] ID:{info.CID} | CNO:{info.CNO} | Name:{info.Name} | Type:{info.Type}");
        }

        public List<XChannelInfo> GetChannels(long channelId)
        {
            return Channels.TryGetValue(channelId, out var list) ? list : new List<XChannelInfo>();
        }

        public XChannelInfo? GetChannel(long channelId)
        {
            return Channels.TryGetValue(channelId, out var list) ? list.FirstOrDefault() : null;
        }



        public XChannelInfo? GetChannelByCno(int cno)
        {
            return Channels.Values.SelectMany(l => l).FirstOrDefault(c => c.CNO == cno);
        }

        public XChannelConfig GetMergedConfig(int cno)
        {
            var channel = Channels.Values.SelectMany(l => l).FirstOrDefault(c => c.CNO == cno);
            var cfg = Config.Channels.FirstOrDefault(c =>
            {
                // Match by CNO parsed from CInfo or legacy CNO property
                if (!string.IsNullOrWhiteSpace(c.CInfo))
                {
                    var parts = c.CInfo.Split(',');
                    if (parts.Length > 0 && int.TryParse(parts[0].Trim(), out var parsedCno)) return parsedCno == cno;
                }
                return c.CNO == cno;
            });

            if (cfg != null) return cfg;

            // Fallback for dynamically registered channels not in JSON
            return new XChannelConfig 
            { 
                CInfo = $"{cno}, {channel?.CID ?? 0}",
                // set Name from channel info when available
                // Name is exposed via the runtime accessor on XChannelConfig
                Symbol = channel?.Name ?? $"CH_{cno}"
            };
        }
    }
}
