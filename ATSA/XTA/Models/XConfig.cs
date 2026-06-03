using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace XTA.Models
{
    /// <summary>
    /// XTA 시스템 통합 설정 모델 (ATSA.json v9.0 표준 - 중복 통합 버전)
    /// </summary>
    public class XConfig
    {
        public static class XChannelIds
        {
            public const long GlobalGold = -1002204600811;
            public const long GMK = -1002218781954;
            public const long XHANA = -1003778889507;
            public const long XDUNA = -1003697953708;
        }

        /// <summary>
        /// 커스텀 설정 파일 경로 (지정되지 않으면 기본값 사용)
        /// </summary>
        public static string? CustomConfigPath { get; set; }

        /// <summary>
        /// 시스템 및 트레이딩 엔진 통합 설정 (단일 관리 지점)
        /// </summary>
        public XEngineSystemSettings System { get; set; } = new();

        public List<XChannelConfig> Channels { get; set; } = new();

        public static string GetConfigPath() 
        {
            if (!string.IsNullOrEmpty(CustomConfigPath)) return CustomConfigPath;
            return Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "_config", "ATSA.json");
        }

        public static void EnsureExists(string? customPath = null)
        {
            if (!string.IsNullOrEmpty(customPath)) CustomConfigPath = customPath;
            
            string path = GetConfigPath();
            string? dir = Path.GetDirectoryName(path);
            if (dir != null && !Directory.Exists(dir)) Directory.CreateDirectory(dir);

            if (!File.Exists(path))
            {
                // MetaTrader 5 공용 폴더 경로 동적 계산
                string commonPath = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                    @"MetaQuotes\Terminal\Common\Files");
                
                // Default DB path under MetaQuotes Common Files 'db' subfolder
                string dbFullPath = Path.Combine(commonPath, "db", "AGS.db");

                var defaultConfig = new XConfig
                {
                    System = new XEngineSystemSettings 
                    { 
                        Version = "v9.0.0", 
                        DatabaseFullPath = dbFullPath, // 공용 폴더 FullPath 명시
                        LoggingLevel = "Info",
                        RefreshIntervalMs = 1000,
                        ArchiveIntervalSeconds = 1000
                    },
                    Channels = new List<XChannelConfig>
                    {
                        new XChannelConfig { 
                            CNO = 1001, Name = " 1001, -1002204600811 , GlobalGold", Symbol = "GOLD#", ChannelId = XChannelIds.GlobalGold, SourceType = "Telegram",
                            Interpreter = "GlobalGold",
                            TradingOption = new XTradingOption { 
                                ActiveMode = "Live",
                                Buy = new XDirectionOption { Enabled = true, LotStrategy = "F,0.01,1.0", Entry = "500, 100, 1000", Exit = "500, 100, 700, 1500" },
                                Sell = new XDirectionOption { Enabled = true, LotStrategy = "F,0.01,1.0", Entry = "500, 100, 1000", Exit = "500, 100, 700, 1500" }
                            }
                        },
                        new XChannelConfig { 
                            CNO = 1002, Name = " 1002, -1002218781954 , GMK", Symbol = "GOLD#", ChannelId = XChannelIds.GMK, SourceType = "Telegram",
                            Interpreter = "GMK",
                            TradingOption = new XTradingOption { 
                                ActiveMode = "Live",
                                Buy = new XDirectionOption { Enabled = true, LotStrategy = "F,0.01,1.0", Entry = "500, 100, 1000", Exit = "500, 100, 700, 1500" },
                                Sell = new XDirectionOption { Enabled = true, LotStrategy = "F,0.01,1.0", Entry = "500, 100, 1000", Exit = "500, 100, 700, 1500" }
                            }
                        },
                        new XChannelConfig { 
                            CNO = 3001, Name = " 3001, -1003778889507 , XHANA", Symbol = "GOLD#", ChannelId = XChannelIds.XHANA, SourceType = "Telegram",
                            Interpreter = "GlobalGold",
                            TradingOption = new XTradingOption { 
                                ActiveMode = "Simulation",
                                Buy = new XDirectionOption { Enabled = true, LotStrategy = "F,0.01,1.0", Entry = "500, 100, 1000", Exit = "500, 100, 700, 1500" },
                                Sell = new XDirectionOption { Enabled = true, LotStrategy = "F,0.01,1.0", Entry = "500, 100, 1000", Exit = "500, 100, 700, 1500" }
                            }
                        },
                        new XChannelConfig { 
                            CNO = 3002, Name = " 3002, -1003697953708 , XDUNA", Symbol = "GOLD#", ChannelId = XChannelIds.XDUNA, SourceType = "Telegram",
                            Interpreter = "GMK",
                            TradingOption = new XTradingOption { 
                                ActiveMode = "Simulation",
                                Buy = new XDirectionOption { Enabled = true, LotStrategy = "F,0.01,1.0", Entry = "500, 100, 1000", Exit = "500, 100, 700, 1500" },
                                Sell = new XDirectionOption { Enabled = true, LotStrategy = "F,0.01,1.0", Entry = "500, 100, 1000", Exit = "500, 100, 700, 1500" }
                            }
                        },
                        new XChannelConfig {
                            CNO = 2001, Name = " 2001, 0 , YouTube_CH1", SourceType = "YouTube",
                            Interpreter = "YouTubeVision",
                            YouTube = new XYouTubeConfig { Url = "https://youtu.be/-ps7V40GrA4", ROI = "100,100,400,200", IntervalMs = 3000 },
                            TradingOption = new XTradingOption { 
                                ActiveMode = "Simulation",
                                Buy = new XDirectionOption { Enabled = true, LotStrategy = "F,0.01,1.0", Entry = "500, 100, 1000", Exit = "500, 100, 700, 1500" },
                                Sell = new XDirectionOption { Enabled = true, LotStrategy = "F,0.01,1.0", Entry = "500, 100, 1000", Exit = "500, 100, 700, 1500" }
                            }
                        },
                        new XChannelConfig {
                            CNO = 2002, Name = " 2002, 0 , YouTube_CH2", SourceType = "YouTube",
                            Interpreter = "YouTubeVision",
                            YouTube = new XYouTubeConfig { Url = "https://youtu.be/P4V456LsOYk", ROI = "0,0,800,400", IntervalMs = 3000 },
                            TradingOption = new XTradingOption { 
                                ActiveMode = "Simulation",
                                Buy = new XDirectionOption { Enabled = true, LotStrategy = "Fixed, 0.01, 0", Entry = "500, 100, 1000", Exit = "500, 100, 700, 1500" },
                                Sell = new XDirectionOption { Enabled = true, LotStrategy = "Fixed, 0.01, 0", Entry = "500, 100, 1000", Exit = "500, 100, 700, 1500" }
                            }
                        }
                    }
                };

                var options = new JsonSerializerOptions { WriteIndented = true };
                File.WriteAllText(path, JsonSerializer.Serialize(defaultConfig, options));
            }
        }
    }

    public class XEngineSystemSettings
    {
        public string Version { get; set; } = "1.0.0";
        public string DatabaseFullPath { get; set; } = "AGS.db";
        public string LoggingLevel { get; set; } = "Info";
        public int RefreshIntervalMs { get; set; } = 1000;
        public int TtsVolume { get; set; } = 100; // [v14.43] TTS Volume control (0-100)

        /// <summary>
        /// Interval (in seconds) between automatic archive runs executed by the DB service.
        /// Default is 1 second.
        /// </summary>
        public int ArchiveIntervalSeconds { get; set; } = 1;

        /// <summary>
        /// [v10.0] Global Signal Source Type (Telegram, YouTube, Simulator)
        /// </summary>

        public string SourceType { get; set; } = "Telegram";
    }

    public class XChannelConfig
    {
        public bool Enabled { get; set; } = true;
        public bool SoundEnabled { get; set; } = true;
        public int CNO { get; set; }
        public long ChannelId { get; set; }
        public string Name { get; set; } = "";
        public string Symbol { get; set; } = "GOLD#";
        public string SourceType { get; set; } = "Telegram";
        public string Interpreter { get; set; } = ""; 
        public XYouTubeConfig? YouTube { get; set; }
        public XTradingOption TradingOption { get; set; } = new();
    }

    public class XYouTubeConfig
    {
        public string Url { get; set; } = "";
        public string ROI { get; set; } = "0,0,800,400";
        public int IntervalMs { get; set; } = 3000;
        public XOcrFilterConfig Filter { get; set; } = new();
    }

    public class XOcrFilterConfig
    {
        public int BufferSize { get; set; } = 10;
        public double ThresholdPercentage { get; set; } = 0.8;
    }

    public class XTradingOption
    {
        public string? ActiveMode { get; set; } = "Simulation";
        public XDirectionOption Buy { get; set; } = new();
        public XDirectionOption Sell { get; set; } = new();
    }

    public class XDirectionOption
    {
        public bool? Enabled { get; set; }
        public string? LotStrategy { get; set; } = "F,0.01,1.0"; // "Type, Value, Rate" (F/R supported)
        public string? Entry { get; set; } = "500, 100, 1000";       // "TeStart, TeStep, TeLimit"
        public string? Exit { get; set; } = "500, 100, 700, 1500";  // "TsStart, TsStep, SL, TP"

        [JsonIgnore]
        public XLotStrategy LotStrategyObj => ParseLotStrategy(LotStrategy);
        [JsonIgnore]
        public XEntryOption EntryObj => ParseEntry(Entry);
        [JsonIgnore]
        public XExitOption ExitObj => ParseExit(Exit);

        private XLotStrategy ParseLotStrategy(string? s)
        {
            if (string.IsNullOrEmpty(s)) return new XLotStrategy();
            var p = s.Split(',').Select(x => x.Trim()).ToArray();
            string rawType = p.Length > 0 ? p[0] : "Fixed";
            // Normalize short forms: F -> Fixed, R -> Rate
            string typeNorm = rawType switch
            {
                var t when string.Equals(t, "F", StringComparison.OrdinalIgnoreCase) => "Fixed",
                var t when string.Equals(t, "R", StringComparison.OrdinalIgnoreCase) => "Rate",
                _ => rawType
            };

            double value = 0.01;
            double rate = 1.0;
            if (p.Length > 1)
            {
                double.TryParse(p[1], System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out value);
            }
            if (p.Length > 2)
            {
                double.TryParse(p[2], System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out rate);
            }

            return new XLotStrategy
            {
                Type = typeNorm,
                Value = value,
                Rate = rate
            };
        }

        private XEntryOption ParseEntry(string? s)
        {
            if (string.IsNullOrEmpty(s)) return new XEntryOption();
            var p = s.Split(',').Select(x => x.Trim()).ToArray();
            return new XEntryOption { 
                TeStart = p.Length > 0 ? double.Parse(p[0]) : 500, 
                TeStep = p.Length > 1 ? double.Parse(p[1]) : 100, 
                TeLimit = p.Length > 2 ? double.Parse(p[2]) : 1000 
            };
        }

        private XExitOption ParseExit(string? s)
        {
            if (string.IsNullOrEmpty(s)) return new XExitOption();
            var p = s.Split(',').Select(x => x.Trim()).ToArray();
            return new XExitOption { 
                TsStart = p.Length > 0 ? int.Parse(p[0]) : 500, 
                TsStep = p.Length > 1 ? int.Parse(p[1]) : 100, 
                SL = p.Length > 2 ? double.Parse(p[2]) : 700, 
                TP = p.Length > 3 ? double.Parse(p[3]) : 1500 
            };
        }
    }

    public class XLotStrategy
    {
        public string Type { get; set; } = "Fixed";
        public double Value { get; set; }
        public double Rate { get; set; }
    }

    public class XEntryOption
    {
        public double TeStart { get; set; }
        public double TeStep { get; set; }
        public double TeLimit { get; set; }
    }

    public class XExitOption
    {
        public int TsStart { get; set; }
        public int TsStep { get; set; }
        public double SL { get; set; }
        public double TP { get; set; }
    }

    public class XOcrSettings
    {
        public string DataPath { get; set; } = @".\tessdata";
        public string Language { get; set; } = "eng";
        public string Whitelist { get; set; } = "0123456789.BUYSELTPSL";
        public int PageSegMode { get; set; } = 7;
    }
}
