using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using DevExpress.Data.Filtering;
using DevExpress.Xpo;
using XTA.Infrastructure.Data;
using XTA.XData.Models;
using XTA.Models;
using FluentSeq;

namespace XTA.Services
{
    /// <summary>
    /// [Partial] Sequence: FluentSeq 기반의 동기화 시퀀스 정의 (Workflow)
    /// </summary>
    public partial class XSyncWorker
    {
        private void InitSequence()
        {
            _syncSeq = new FluentSeq<string>()
                .Create("Idle")
                .ActivateDebugLogging(nlog)

                .ConfigureState("Idle")

                .ConfigureState("Prepare")
                    .OnEntry(() => {
                        _ctx = new SyncContext();
                        var db = param.GetService<XpoSqliteService>();
                        if (db == null) { _syncSeq.SetState("Idle"); return; }
                        
                        _ctx.DbService = db;
                        _ctx.TradeCnos = param.Channels.Values
                            .SelectMany(l => l)
                            .Where(c => c.Type.Equals("TRADE", StringComparison.OrdinalIgnoreCase))
                            .Select(c => c.CNO).ToList();

                        if (_ctx.TradeCnos.Count == 0) _syncSeq.SetState("Idle");
                        else _syncSeq.SetState("Query");
                    })

                .ConfigureState("Query")
                    .OnEntry(() => {
                        if (_ctx.DbService == null) { _syncSeq.SetState("Idle"); return; }

                        using var uow = new UnitOfWork(_ctx.DbService.GetLayer());
                        var lookback = DateTime.Now.AddMinutes(-_lookbackMinutes);
                        var criteria = CriteriaOperator.And(
                            new InOperator("CNO", _ctx.TradeCnos),
                            CriteriaOperator.Parse("Status IN (0, 2) AND Time > ? AND RetryCount < ?", lookback, _maxRetryCount)
                        );

                        _ctx.PendingMessages = new XPCollection<XpoTgMessage>(uow, criteria).ToList();
                        
                        // [Fix] 메시지가 없어도 모니터링은 수행해야 함
                        if (_ctx.PendingMessages.Count == 0) _syncSeq.SetState("MonitorEntry");
                        else _syncSeq.SetState("Recover");
                    })

                .ConfigureState("Recover")
                    .OnEntry(async () => {
                        if (_ctx.DbService == null || _ctx.PendingMessages.Count == 0) { _syncSeq.SetState("MonitorEntry"); return; }

                        nlog.Info($"[SyncWorker] Found {_ctx.PendingMessages.Count} unprocessed messages. Recovering...");
                        await ProcessRecoveryAsync();
                        _syncSeq.SetState("MonitorEntry");
                    })

                .ConfigureState("MonitorEntry")
                    .OnEntry(async () => {
                        await ProcessEntryMonitoringAsync();
                        _syncSeq.SetState("MonitorClose");
                    })

                .ConfigureState("MonitorClose")
                    .OnEntry(async () => {
                        await ProcessCloseMonitoringAsync();
                        _syncSeq.SetState("MonitorError");
                    })

                .ConfigureState("MonitorError")
                    .OnEntry(async () => {
                        await ProcessErrorMonitoringAsync();
                        _syncSeq.SetState("Idle");
                    })

                .Builder().DisableValidation().Build();
        }

        private async void OnSyncTimerCallback(object? state)
        {
            if (Interlocked.CompareExchange(ref _isBusyInt, 1, 0) != 0) return;
            try
            {
                _syncSeq.SetState("Prepare");
                
                int safety = 0;
                // [v13.5] Async-Aware Loop: 
                // OnEntry가 async void이므로 내부에서 상태가 변경될 때까지 대기할 수 있는 구조 필요
                // 여기서는 우선 safety를 늘리고 RunAsync가 있다면 활용 고려
                while (!_syncSeq.IsInState("Idle") && safety++ < 30)
                {
                    _syncSeq.Run();
                    await Task.Delay(100); // 비동기 OnEntry가 상태를 변경할 시간을 줌
                }
            }
            catch (Exception ex) { nlog.Error(ex, "[SyncWorker:SEQ] Execution failed."); }
            finally { Interlocked.Exchange(ref _isBusyInt, 0); }
        }
    }
}
