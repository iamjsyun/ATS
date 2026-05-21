using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using XTA.Core;
using XTA.Infrastructure.Data;
using XTA.Test.Core;
using Xunit;
using Microsoft.Extensions.DependencyInjection;
using XTA.Interfaces;
using XTA.Services;
using XTA.XData.Interfaces;
using XTA.Models;
using Microsoft.Extensions.Hosting;
using Moq;

namespace XTA.Test;

[Collection("Sequential")]
public class PipelineSimulationTest : IDisposable
{
    private readonly string _testDbPath;
    private readonly ScenarioRunner _runner;
    private readonly IServiceProvider _serviceProvider;

    public PipelineSimulationTest()
    {
        XContext.Instance.Reset();
        _testDbPath = $"test_pipeline_{Guid.NewGuid()}.db";
        if (File.Exists(_testDbPath)) File.Delete(_testDbPath);

        var services = new ServiceCollection();
        var param = new XParameter();
        param.Config.System.DatabaseFullPath = _testDbPath;
        
        // [Fix] 정책 초기화 (Null 정책 드랍 방지)
        param.Config.ChannelDefault.TradingOption.Buy = new XDirectionOption { Enabled = true, LotStrategy = new XLotStrategy { Type = "Fixed", Value = 0.01 } };
        param.Config.ChannelDefault.TradingOption.Sell = new XDirectionOption { Enabled = true, LotStrategy = new XLotStrategy { Type = "Fixed", Value = 0.01 } };

        // Core Services
        services.AddSingleton(param);
        services.AddSingleton<XpoSqliteService>();
        services.AddSingleton<ISignalRepository>(sp => sp.GetRequiredService<XpoSqliteService>());
        services.AddSingleton<IGridProfileRepository>(sp => sp.GetRequiredService<XpoSqliteService>());
        
        services.AddSingleton<XGatewayService>();
        services.AddSingleton<IXGatewayService>(sp => sp.GetRequiredService<XGatewayService>());
        
        services.AddSingleton<IXTradePolicyService, XTradePolicyService>();
        services.AddSingleton<IXSignalService, XSignalService>();
        services.AddSingleton<IXLiquidationService, XLiquidationService>();

        // [Mocks] GatewayService dependencies
        services.AddSingleton<IDataService>(new Mock<IDataService>().Object);
        services.AddSingleton<ISoundService>(new Mock<ISoundService>().Object);
        services.AddSingleton<ITtsService>(new Mock<ITtsService>().Object);

        var ggInfo = new XChannelInfo(1001, 1001, "GlobalGold", "TRADE");
        var gmkInfo = new XChannelInfo(1002, 1002, "GMK", "TRADE");
        param.RegisterChannel(ggInfo);
        param.RegisterChannel(gmkInfo);
        
        _serviceProvider = services.BuildServiceProvider();
        
        var hostMock = new Mock<IHost>();
        hostMock.Setup(h => h.Services).Returns(_serviceProvider);
        XContext.Instance.Initialize(hostMock.Object, param);

        _serviceProvider.GetRequiredService<XpoSqliteService>().Start();
        _serviceProvider.GetRequiredService<XGatewayService>().Start();
        
        var gg = new XTA.Channels.GlobalGold.GlobalGold(param, ggInfo);
        var gmk = new XTA.Channels.GMK.GMK(param, gmkInfo);
        param.Add(gg);
        param.Add(gmk);

        _runner = new ScenarioRunner(param, _serviceProvider.GetRequiredService<XpoSqliteService>());
    }

    [Fact]
    public async Task Run_HappyPath_Scenario()
    {
        string csvPath = Path.Combine(AppContext.BaseDirectory, "Scenarios", "SimulationScenario.csv");
        if (!File.Exists(csvPath)) csvPath = "../../../Scenarios/SimulationScenario.csv";
        var scenarios = ScenarioParser.Parse(csvPath);
        var happyPath = scenarios.First(s => s.ScenarioId == "SCEN_NORMAL_HAPPY");
        await _runner.ExecuteAsync(happyPath);
    }

    [Fact]
    public async Task Run_CircuitBreaker_Scenario()
    {
        string csvPath = Path.Combine(AppContext.BaseDirectory, "Scenarios", "SimulationScenario.csv");
        if (!File.Exists(csvPath)) csvPath = "../../../Scenarios/SimulationScenario.csv";
        var scenarios = ScenarioParser.Parse(csvPath);
        var cbScenario = scenarios.First(s => s.ScenarioId == "SCEN_CIRCUIT_BREAKER");
        await _runner.ExecuteAsync(cbScenario);
    }

    [Fact]
    public async Task Run_DuplicateGuard_Scenario()
    {
        string csvPath = Path.Combine(AppContext.BaseDirectory, "Scenarios", "SimulationScenario.csv");
        if (!File.Exists(csvPath)) csvPath = "../../../Scenarios/SimulationScenario.csv";
        var scenarios = ScenarioParser.Parse(csvPath);
        var scenario = scenarios.First(s => s.ScenarioId == "SCEN_DUPLICATE_GUARD");
        await _runner.ExecuteAsync(scenario);
    }

    [Fact]
    public async Task Run_MalformedMsg_Scenario()
    {
        string csvPath = Path.Combine(AppContext.BaseDirectory, "Scenarios", "SimulationScenario.csv");
        if (!File.Exists(csvPath)) csvPath = "../../../Scenarios/SimulationScenario.csv";
        var scenarios = ScenarioParser.Parse(csvPath);
        var scenario = scenarios.First(s => s.ScenarioId == "SCEN_MALFORMED_MSG");
        await _runner.ExecuteAsync(scenario);
    }

    [Fact]
    public async Task Run_ZombieTimeout_Scenario()
    {
        string csvPath = Path.Combine(AppContext.BaseDirectory, "Scenarios", "SimulationScenario.csv");
        if (!File.Exists(csvPath)) csvPath = "../../../Scenarios/SimulationScenario.csv";
        var scenarios = ScenarioParser.Parse(csvPath);
        var scenario = scenarios.First(s => s.ScenarioId == "SCEN_ZOMBIE_TIMEOUT");
        await _runner.ExecuteAsync(scenario);
    }

    [Fact]
    public async Task Run_ManualIntervene_Scenario()
    {
        string csvPath = Path.Combine(AppContext.BaseDirectory, "Scenarios", "SimulationScenario.csv");
        if (!File.Exists(csvPath)) csvPath = "../../../Scenarios/SimulationScenario.csv";
        var scenarios = ScenarioParser.Parse(csvPath);
        var scenario = scenarios.First(s => s.ScenarioId == "SCEN_MANUAL_INTERVENE");
        await _runner.ExecuteAsync(scenario);
    }

    public void Dispose()
    {
        _serviceProvider.GetRequiredService<XGatewayService>().Stop();
        _serviceProvider.GetRequiredService<XpoSqliteService>().Stop();
    }
}
