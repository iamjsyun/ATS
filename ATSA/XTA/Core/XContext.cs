        using System;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using XTA.Interfaces;
using XTA.Models;
using XTA.XData.Interfaces;

namespace XTA.Core
{
    /// <summary>
    /// XTA 시스템 전역 컨텍스트 및 IHost 기반 서비스 제공자 래퍼.
    /// Singleton 구조를 유지하면서도 내부적으로는 표준 DI 컨테이너를 사용함.
    /// </summary>
    public class XContext
    {
        private static readonly Lazy<XContext> _instance = new Lazy<XContext>(() => new XContext());
        public static XContext Instance => _instance.Value;

        private IHost? _host;
        public IServiceProvider? ServiceProvider => _host?.Services;

        public XParameter Parameter { get; set; } = null!;
        public XConfig? Config => Parameter?.Config;

        /// <summary>
        /// 컨텍스트 초기화 (테스트용)
        /// </summary>
        public void Reset()
        {
            _host = null;
            Parameter = null!;
        }

        private XContext() { }

        /// <summary>
        /// 외부에서 빌드된 IHost를 컨텍스트에 바인딩
        /// </summary>
        public void Initialize(IHost host, XParameter parameter)
        {
            _host = host;
            this.Parameter = parameter;
        }

        public T? GetService<T>() where T : class
        {
            if (ServiceProvider == null)
            {
                // Host가 준비되기 전(디자인 타임 포함)에는 Parameter에서 시도하며, 없어도 예외를 던지지 않음
                return Parameter?.GetService<T>();
            }
            return ServiceProvider.GetService<T>();
        }

        public T? GetOptionalService<T>() where T : class => GetService<T>();

        // --- 핵심 서비스 속성 (null 허용으로 변경하여 안전성 확보) ---
        public ISignalRepository? SignalRepo => GetService<ISignalRepository>();
        public IXGatewayService? Gateway => GetService<IXGatewayService>();
        public ISoundService? Sound => GetService<ISoundService>();
        public IDataService? Data => GetService<IDataService>();
        public IXTradePolicyService? Policy => GetService<IXTradePolicyService>();
        public IXLiquidationService? Liquidation => GetService<IXLiquidationService>();
        public IXSignalService? Signal => GetService<IXSignalService>();

        /// <summary>
        /// 표준 ILogger를 가져옵니다. (서비스가 없으면 null 반환)
        /// </summary>
        public ILogger<T>? GetLogger<T>() => GetService<ILoggerFactory>()?.CreateLogger<T>();
    }
}
