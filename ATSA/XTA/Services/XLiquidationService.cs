using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using NLog;
using XTA.Core;
using XTA.Interfaces;
using XTA.Models;
using XTA.XData.Interfaces;

namespace XTA.Services
{
    /// <summary>
    /// 청산 로직(Active Liquidation / Forced Liquidation)을 담당하는 서비스
    /// [v9.9] FluentSeq 기반으로 상태 및 제어 흐름 분리 (Check -> Search -> Execute -> Notify)
    /// [Partial] Core: 필드, 컨텍스트 정의, 주 진입점
    /// </summary>
    public partial class XLiquidationService : IXLiquidationService
    {
        private static readonly Logger nlog = LogManager.GetCurrentClassLogger();

        private record LiquidationContext(
            Models.XSignal Signal,
            int MsgId,
            bool IsAlreadyProcessed = false,
            List<XTA.XData.Models.XSignal>? Targets = null,
            Models.XSignal? ForcedSignal = null
        );

        public async Task ProcessLiquidationAsync(Models.XSignal signal, int msgId)
        {
            nlog.Info($"[Liquidation] >>> Starting Close Process for CNO:{signal.cno} SNO:{signal.sno} (MsgId:{msgId})");
            await ExecuteLiquidationWorkflowAsync(signal, msgId);
            nlog.Info($"[Liquidation] <<< Close Process Finished for CNO:{signal.cno} SNO:{signal.sno}");
        }
    }
}
