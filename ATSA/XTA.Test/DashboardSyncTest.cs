using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using ATSA.UI.UCtrls;
using ATSA.UI.Models;
using XTA.Core;
using XTA.Models;
using XTA.Infrastructure.Data;
using XTA.XData.Interfaces;
using XTA.XData.Models;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Moq;
using Xunit;

namespace XTA.Test
{
    [Collection("Sequential")]
    public class DashboardSyncTest : IDisposable
    {
        private readonly string _testDbPath;
        private readonly IServiceProvider _serviceProvider;
        private readonly XParameter _param;
        private readonly XpoSqliteService _dbSvc;

        public DashboardSyncTest()
        {
            XContext.Instance.Reset();
            _testDbPath = $"test_dashboard_sync_{Guid.NewGuid()}.db";
            if (System.IO.File.Exists(_testDbPath)) System.IO.File.Delete(_testDbPath);

            var services = new ServiceCollection();
            _param = new XParameter();
            _param.Config.System.DatabaseFullPath = _testDbPath;

            _dbSvc = new XpoSqliteService(_param);
            services.AddSingleton(_param);
            services.AddSingleton(_dbSvc);
            services.AddSingleton<ISignalRepository>(_dbSvc);

            _serviceProvider = services.BuildServiceProvider();

            var hostMock = new Mock<IHost>();
            hostMock.Setup(h => h.Services).Returns(_serviceProvider);
            XContext.Instance.Initialize(hostMock.Object, _param);

            _dbSvc.Start();
        }

        [Fact]
        public async Task Test_UCXSignalViewModel_LoadSignalsAsync_UpdatesCollection()
        {
            // Arrange: DB에 신호 3개 주입
            var repo = XContext.Instance.GetService<ISignalRepository>();
            for (int i = 1; i <= 3; i++)
            {
                var sig = new XTA.Models.XSignal { 
                    sid = $"SID-{i}", 
                    cno = 1001, 
                    symbol = "GOLD", 
                    updated = DateTime.Now,
                    xe_status = 10 
                };
                await repo.SaveSignalImmediateAsync(sig);
            }

            var vm = new UCXSignalViewModel("Test Channel", 1001);

            // Act: 로드 수행
            await vm.LoadSignalsAsync();

            // Assert: 컬렉션에 3개가 있어야 함
            Assert.Equal(3, vm.Signals.Count);
            Assert.All(vm.Signals, s => Assert.Equal(1001, s.cno));
            Assert.All(vm.Signals, s => Assert.Equal(10, s.xe_status));
        }

        [Fact]
        public async Task Test_BindableXSignal_PropertyChange_UpdatesSid()
        {
            // Arrange
            var sig = new BindableXSignal { cno = 1001, sno = 1, gno = 0, dir = 1, type = 1 };
            string initialSid = sig.sid;
            bool propertyChangedCalled = false;
            sig.PropertyChanged += (s, e) => { if (e.PropertyName == "sid") propertyChangedCalled = true; };

            // Act: 속성 변경
            sig.sno = 5;

            // Assert
            Assert.NotEqual(initialSid, sig.sid);
            Assert.True(propertyChangedCalled);
            Assert.Contains("-05-", sig.sid);
        }

        [Fact]
        public void Test_BindableXSignal_RefreshAll_NotifiesAllProperties()
        {
            // Arrange
            var sig = new BindableXSignal();
            int callCount = 0;
            sig.PropertyChanged += (s, e) => { if (string.IsNullOrEmpty(e.PropertyName)) callCount++; };

            // Act
            sig.RefreshAll();

            // Assert: null 또는 Empty 문자열로 알림이 와야 함 (WPF 표준)
            Assert.Equal(1, callCount);
        }

        public void Dispose()
        {
            _dbSvc.Stop();
        }
    }
}
