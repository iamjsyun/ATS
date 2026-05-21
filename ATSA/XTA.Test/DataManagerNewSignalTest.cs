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
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Xunit;
using Moq;

namespace XTA.Test
{
    /// <summary>
    /// DataManager의 Entry/Exit 신호 생성 및 DB 주입 통합 테스트
    /// </summary>
    [Collection("Sequential")]
    public class DataManagerNewSignalTest : IDisposable
    {
        private readonly string _testDbPath;
        private readonly IServiceProvider _serviceProvider;
        private readonly XParameter _param;
        private readonly XpoSqliteService _dbSvc;

        public DataManagerNewSignalTest()
        {
            XContext.Instance.Reset();
            _testDbPath = $"test_dm_newsignal_{Guid.NewGuid()}.db";
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
        public async Task Test_NewEntrySignal_FullCycle_Flow()
        {
            var mockDialog = new Mock<ATSA.UI.Services.IDialogService>();
            var vm = new DataManagerViewModel(mockDialog.Object);
            
            // 1. 상태 설정
            vm.SelectedSignal!.cno = 1001;
            vm.SelectedSignal.symbol = "GOLD#";
            vm.SelectedSignal.dir = 1; 
            vm.SelectedSignal.lot = 1.0;
            vm.SelectedSignal.price_signal = 2350.50;
            
            // 2. Draft 생성
            vm.AddNewEntrySignal(); 
            Assert.Contains("GOLD#", vm.SelectedSignal!.GeneratedMessage);
            SetupKeywords(1001);

            // 3. 직접 해석 단계 검증
            var info = _param.GetChannelByCno(1001);
            var interpreter = _serviceProvider.GetServices<XInterpreterBase>().First(i => i.Info.CNO == 1001);
            var xdo = new XDataObject { CID = info.CID, CNO = info.CNO, Text = vm.SelectedSignal!.GeneratedMessage, CMD = "TEST" };
            var interpreted = interpreter.Interpret(xdo);
            Assert.NotEmpty(interpreted);
            
            // 4. SaveChanges 실행
            await vm.SaveChanges();

            // 5. DB 확인
            var repo = XContext.Instance.GetService<ISignalRepository>();
            var signals = await repo.GetSignalsByCnoAsync(1001, 10);
            Assert.NotEmpty(signals);
        }

        [Fact]
        public async Task Test_NewExitSignal_FullCycle_Flow()
        {
            var mockDialog = new Mock<ATSA.UI.Services.IDialogService>();
            var vm = new DataManagerViewModel(mockDialog.Object);
            
            vm.SelectedSignal!.cno = 1001;
            vm.SelectedSignal.symbol = "GOLD#";
            vm.SelectedSignal.dir = 1; 
            vm.SelectedSignal.sno = 1; 
            
            vm.AddNewExitSignal(); 
            Assert.Equal(1, vm.SelectedSignal!.xa_exit); 

            SetupKeywords(1001);

            await vm.SaveChanges();

            var repo = XContext.Instance.GetService<ISignalRepository>();
            var signals = await repo.GetSignalsByCnoAsync(1001, 10);
            Assert.Contains(signals, s => s.xa_exit == 1);
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
        }
    }
}
