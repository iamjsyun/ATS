using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Windows;
using XTA.Core;
using XTA.Infrastructure.Data;
using XTA.Interfaces;
using XTA.Services;
using XTA.XData.Interfaces;
using XTA.XData.Models;
using XTA.Models;
using XTA.Channels;
using ATSA.UI.DataManager;
using ATSA.UI.Models;
using ATSA.UI.Services;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Xunit;
using Moq;
using Xunit.Abstractions;

namespace XTA.Test
{
    [Collection("Sequential")]
    public class DataManagerSaveTest : IDisposable
    {
        private readonly string _testDbPath;
        private readonly IServiceProvider _serviceProvider;
        private readonly XParameter _param;
        private readonly XpoSqliteService _dbSvc;
        private readonly ITestOutputHelper _output;

        public DataManagerSaveTest(ITestOutputHelper output)
        {
            _output = output;
            XContext.Instance.Reset();
            
            _testDbPath = Path.GetFullPath($"test_dm_save_{Guid.NewGuid()}.db");
            if (File.Exists(_testDbPath)) File.Delete(_testDbPath);

            var services = new ServiceCollection();
            _param = new XParameter();
            _param.Config.System.DatabaseFullPath = _testDbPath;

            // [Important] 정책 초기화
            var channelConfig = new XChannelConfig 
            { 
                CNO = 1001, 
                TradingOption = new XTradingOption { 
                    Buy = new XDirectionOption { Enabled = true, LotStrategy = "Fixed, 0.01, 0", Entry = "500, 100, 1000", Exit = "500, 100, 1500, 700" },
                    Sell = new XDirectionOption { Enabled = true, LotStrategy = "Fixed, 0.01, 0", Entry = "500, 100, 1000", Exit = "500, 100, 1500, 700" }
                } 
            };
            _param.Config.Channels.Add(channelConfig);

            _dbSvc = new XpoSqliteService(_param);

            services.AddSingleton(_param);
            services.AddSingleton(_dbSvc);
            services.AddSingleton<ISignalRepository>(_dbSvc);
            services.AddSingleton<IGridProfileRepository>(_dbSvc);
            services.AddSingleton<IXTradePolicyService, XTradePolicyService>();
            services.AddSingleton<IXSignalService, XSignalService>();
            services.AddSingleton<IXGatewayService, XGatewayService>();
            services.AddSingleton<IXLiquidationService, XLiquidationService>();

            var info = new XChannelInfo(1001, 1001, "GlobalGold", "TRADE");
            _param.RegisterChannel(info);
            var interpreter = new XTA.Channels.GlobalGold.GlobalGold(_param, info);
            services.AddSingleton<XInterpreterBase>(interpreter);
            _param.Add(interpreter); 

            _serviceProvider = services.BuildServiceProvider();
            var hostMock = new Mock<IHost>();
            hostMock.Setup(h => h.Services).Returns(_serviceProvider);
            XContext.Instance.Initialize(hostMock.Object, _param);

            _dbSvc.Start();
        }

        [Fact]
        public async Task TC_SAVE_01_NewEntry_Injection_Success()
        {
            var mockDialog = new Mock<IDialogService>();
            var vm = new DataManagerViewModel(mockDialog.Object);
            await vm.LoadSignals(); 
            SetupKeywords(1001);

            vm.SelectedSignal!.cno = 1001;
            vm.SelectedSignal!.symbol = "GOLD#";
            vm.SelectedSignal!.dir = 1;
            vm.SelectedSignal!.lot = 0.5;
            vm.SelectedSignal!.price_signal = 2000.0;
            vm.AddNewEntrySignal(); 

            await vm.SaveChanges();

            var repo = XContext.Instance.GetService<ISignalRepository>();
            var signals = await repo.GetSignalsByCnoAsync(1001, 10);
            Assert.Contains(signals, s => s.lot == 0.5 && s.xa_exit == 0);
            mockDialog.Verify(d => d.ShowInfo(It.IsAny<string>(), "완료"), Times.Once);
        }

        [Fact]
        public async Task TC_SAVE_02_NewExit_Injection_Success()
        {
            var mockDialog = new Mock<IDialogService>();
            var vm = new DataManagerViewModel(mockDialog.Object);
            SetupKeywords(1001);

            vm.SelectedSignal!.cno = 1001;
            vm.SelectedSignal!.symbol = "GOLD#";
            vm.SelectedSignal!.dir = 1;
            vm.SelectedSignal!.sno = 3;
            vm.AddNewExitSignal(); 

            await vm.SaveChanges();

            var repo = XContext.Instance.GetService<ISignalRepository>();
            var signals = await repo.GetSignalsByCnoAsync(1001, 10);
            Assert.Contains(signals, s => s.sno == 3 && s.xa_exit == 1 && s.xe_status == 20);
        }

        [Fact]
        public async Task TC_SAVE_03_Policy_Bypass_Verification()
        {
            var mockDialog = new Mock<IDialogService>();
            var vm = new DataManagerViewModel(mockDialog.Object);
            SetupKeywords(1001);

            var config = _param.GetMergedConfig(1001);
            config.TradingOption.Buy.Enabled = false; 

            vm.SelectedSignal!.cno = 1001;
            vm.SelectedSignal!.dir = 1; 
            vm.SelectedSignal!.symbol = "GOLD#";
            vm.SelectedSignal!.lot = 0.1;
            vm.SelectedSignal!.price_signal = 2000.0;
            vm.AddNewEntrySignal();

            await vm.SaveChanges();

            var repo = XContext.Instance.GetService<ISignalRepository>();
            var signals = await repo.GetSignalsByCnoAsync(1001, 10);
            Assert.NotEmpty(signals); 
        }

        [Fact]
        public async Task TC_SAVE_04_Interpretation_Failure_Handling()
        {
            var mockDialog = new Mock<IDialogService>();
            var vm = new DataManagerViewModel(mockDialog.Object);
            
            var interpreter = _serviceProvider.GetServices<XInterpreterBase>().First(i => i.Info.CNO == 1001);
            var kwField = typeof(XRuleInterpreter).GetProperty("Keywords", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            var kw = (kwField?.GetValue(interpreter) as XRuleInterpreter.KeywordConfig)!;
            kw.EntryKeywords.Clear(); 
            kw.BuyKeywords.Clear();

            vm.SelectedSignal!.cno = 1001;
            vm.AddNewEntrySignal();

            await vm.SaveChanges();

            mockDialog.Verify(d => d.ShowError(It.Is<string>(s => s.Contains("실패")), It.IsAny<string>()), Times.Once);
        }

        private void SetupKeywords(int cno)
        {
            var interpreter = _serviceProvider.GetServices<XInterpreterBase>().First(i => i.Info.CNO == cno);
            var kwField = typeof(XRuleInterpreter).GetProperty("Keywords", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            var kw = (kwField?.GetValue(interpreter) as XRuleInterpreter.KeywordConfig)!;
            
            kw.EntryKeywords.Clear(); kw.EntryKeywords.Add("ENTRY"); kw.EntryKeywords.Add("정보공유");
            kw.ExitKeywords.Clear(); kw.ExitKeywords.Add("EXIT"); kw.ExitKeywords.Add("정리");
            kw.BuyKeywords.Clear(); kw.BuyKeywords.Add("BUY"); kw.BuyKeywords.Add("매수");
            kw.SellKeywords.Clear(); kw.SellKeywords.Add("SELL"); kw.SellKeywords.Add("매도");
            kw.LotKeywords.Clear(); kw.LotKeywords.Add(@"(\d+\.\d+)"); kw.LotKeywords.Add(@"([\d\.]+)\s*계약");
            kw.PriceKeywords.Clear(); kw.PriceKeywords.Add(@"Price:\s*([\d,\.]+)"); kw.PriceKeywords.Add(@"참고가격:\s*([\d,\.]+)");
        }

        public void Dispose()
        {
            _dbSvc.Stop();
            GC.Collect();
            GC.WaitForPendingFinalizers();
            if (File.Exists(_testDbPath)) 
            {
                try { File.Delete(_testDbPath); } catch { }
            }
        }
    }
}
