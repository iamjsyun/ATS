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
    private readonly XParameter _param;
    private readonly XpoSqliteService _dbSvc;

    public PipelineSimulationTest()
    {
        XContext.Instance.Reset();
        _testDbPath = $"test_pipeline_{Guid.NewGuid()}.db";
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
        _param.Config.Channels.Add(new XChannelConfig { CNO = 1002, TradingOption = channelConfig.TradingOption });

        _dbSvc = new XpoSqliteService(_param);

        services.AddSingleton(_param);
        services.AddSingleton(_dbSvc);
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
        _param.RegisterChannel(ggInfo);
        _param.RegisterChannel(gmkInfo);
        
        _serviceProvider = services.BuildServiceProvider();
        
        var hostMock = new Mock<IHost>();
        hostMock.Setup(h => h.Services).Returns(_serviceProvider);
        XContext.Instance.Initialize(hostMock.Object, _param);

        _serviceProvider.GetRequiredService<XpoSqliteService>().Start();
        _serviceProvider.GetRequiredService<XGatewayService>().Start();
        
        var gg = new XTA.Channels.GlobalGold.GlobalGold(_param, ggInfo);
        var gmk = new XTA.Channels.GMK.GMK(_param, gmkInfo);
        _param.Add(gg);
        _param.Add(gmk);

        _runner = new ScenarioRunner(_param, _serviceProvider.GetRequiredService<XpoSqliteService>());
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
