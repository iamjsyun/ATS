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
                        
                        if (_ctx.PendingMessages.Count == 0) _syncSeq.SetState("Idle");
                        else _syncSeq.SetState("Recover");
                    })

                .ConfigureState("Recover")
                    .OnEntry(async () => {
                        if (_ctx.DbService == null || _ctx.PendingMessages.Count == 0) { _syncSeq.SetState("MonitorClose"); return; }

                        nlog.Info($"[SyncWorker] Found {_ctx.PendingMessages.Count} unprocessed messages. Recovering...");
                        await ProcessRecoveryAsync();
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

        private void OnSyncTimerCallback(object? state)
        {
            if (Interlocked.CompareExchange(ref _isBusyInt, 1, 0) != 0) return;
            try
            {
                _syncSeq.SetState("Prepare");
                
                int safety = 0;
                while (!_syncSeq.IsInState("Idle") && safety++ < 5)
                {
                    _syncSeq.Run();
                }
            }
            catch (Exception ex) { nlog.Error(ex, "[SyncWorker:SEQ] Execution failed."); }
            finally { Interlocked.Exchange(ref _isBusyInt, 0); }
        }
    }
}
