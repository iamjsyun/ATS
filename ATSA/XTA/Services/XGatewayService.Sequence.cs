using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using XTA.XData.Models;
using XTA.Models;
using XTA.Core;
using FluentSeq;

namespace XTA.Services
{
    /// <summary>
    /// [Partial] Sequence: FluentSeq 설정 및 상태 흐름 정의 (Workflow)
    /// </summary>
    public partial class XGatewayService
    {
        private void InitSequences()
        {
            // 1. 메시지 라우팅 시퀀스 (순차 처리 유지)
            _msgSeq = new FluentSeq<XHubState>().Create(XHubState.Idle)
                .ActivateDebugLogging(nlog)
                .ConfigureState(XHubState.Idle)
                .ConfigureState(XHubState.Received)
                    .OnEntry(() => {
                        if (_currentXdo == null) return;
                        if (_currentInfo != null) {
                            _currentXdo.CNO = _currentInfo.CNO;
                            _ = XContext.Instance.Data?.SaveMessageAsync(_currentXdo);
                            this.Log($"[TG] {_currentInfo.Name} 채널 메시지 수신 (MsgId:{_currentXdo.MsgId})");
                        }
                    })
                .ConfigureState(XHubState.Interpreted)
                    .TriggeredBy(() => _currentInfo != null && _currentInfo.Type.ToUpper() == "TRADE" && _currentInfo.CNO != 2001 && _currentInfo.CNO != 2002)
                        .WhenInState(XHubState.Received)
                    .OnEntry(() => {
                        var interpreter = param.GetService<XInterpreterBase>(i => i.Info.CNO == _currentInfo!.CNO);
                        if (interpreter != null) interpreter.EnqueueMessage(_currentXdo!);
                        else nlog.Warn($"[Gateway:FAIL] Interpreter not found for CNO:{_currentInfo!.CNO}");
                    })
                .ConfigureState(XHubState.Failed)
                    .TriggeredBy(() => _currentInfo == null || (_currentInfo.Type.ToUpper() != "TRADE" || _currentInfo.CNO == 2001 || _currentInfo.CNO == 2002))
                        .WhenInState(XHubState.Received)
                .Builder().DisableValidation().Build();

            // [v9.8] XpoSqliteService 이벤트 구독
            var db = param.GetService<Infrastructure.Data.XpoSqliteService>();
            if (db != null)
            {
                db.SignalSaved += (s, e) => {
                    if (_saveWaiters.TryRemove(e.Sid, out var tcs))
                    {
                        tcs.TrySetResult(true);
                    }
                };
            }
        }

        /// <summary>
        /// [v9.8] 개별 신호 처리 프로세스 (Parallel & Stateless)
        /// </summary>
        private async Task ProcessSignalAsync(XDataObject xdo)
        {
            if (xdo == null) return;

            using (NLog.ScopeContext.PushProperty("TraceId", xdo.MsgId))
            {
                List<Models.XSignal>? preparedSignals = null;
                var ctx = XContext.Instance;

                ISequence<string> seq = null!;
                seq = new FluentSeq<string>().Create("Idle")
                    .ConfigureState("Idle")
                    .ConfigureState("Enrich")
                        .OnEntry(async () => {
                            preparedSignals = (ctx.Signal != null) ? await ctx.Signal.PrepareSignalsAsync(xdo) : null;
                            if (preparedSignals == null || preparedSignals.Count == 0) {
                                nlog.Warn($"[Gateway:DROP] No valid signals for MsgId:{xdo.MsgId}");
                                seq.SetState("Idle");
                            } else {
                                seq.SetState("Persistence");
                            }
                        })
                    .ConfigureState("Persistence")
                        .OnEntry(async () => {
                            if (preparedSignals == null) { seq.SetState("Idle"); return; }
                            foreach (var s in preparedSignals) {
                                if (s.cmd == XCode.CLOSE) continue;
                                var signalXdo = new XDataObject { Signal = s, MsgId = xdo.MsgId, Text = xdo.Text, CID = xdo.CID, CNO = xdo.CNO };
                                PendingSignals.AddOrUpdate(s.sid, signalXdo, (k, v) => signalXdo);
                                if (ctx.Data != null) await ctx.Data.SaveSignalAsync(s);
                            }
                            seq.SetState("Execution");
                        })
                    .ConfigureState("Execution")
                        .OnEntry(async () => {
                            if (preparedSignals == null) { seq.SetState("Idle"); return; }
                            try {
                                foreach (var s in preparedSignals) {
                                    if (s.cmd == XCode.CLOSE && ctx.Liquidation != null) 
                                        await ctx.Liquidation.ProcessLiquidationAsync(s, xdo.MsgId);
                                }
                                seq.SetState("Notification");
                            } catch (Exception ex) {
                                nlog.Error(ex, $"[Gateway:EXEC-FAIL] Execution failed. Triggering compensation.");
                                seq.SetState("RollbackPersistence");
                            }
                        })
                    .ConfigureState("Notification")
                        .OnEntry(() => {
                            if (preparedSignals == null) { seq.SetState("Idle"); return; }
                            foreach (var s in preparedSignals) {
                                if (s.cmd == XCode.CLOSE) continue;
                                var signalXdo = new XDataObject { Signal = s, MsgId = xdo.MsgId, Text = xdo.Text, CID = xdo.CID, CNO = xdo.CNO };
                                ctx.Sound?.PlaySound(s, "SIGNAL_RECEIVED");
                                SignalAddedOrUpdated?.Invoke(signalXdo);
                            }
                            seq.SetState("Verify");
                        })
                    .ConfigureState("Verify")
                        .OnEntry(async () => {
                            if (preparedSignals == null) { seq.SetState("Idle"); return; }
                            var repo = ctx.SignalRepo;
                            
                            foreach (var s in preparedSignals)
                            {
                                if (s.cmd == XCode.CLOSE) continue;

                                var tcs = new TaskCompletionSource<bool>();
                                _saveWaiters[s.sid] = tcs;

                                try 
                                {
                                    if (await Task.WhenAny(tcs.Task, Task.Delay(5000)) == tcs.Task)
                                    {
                                        nlog.Info($"[Gateway:VERIFY] Persistence Success via Event: {s.sid}");
                                    }
                                    else
                                    {
                                        var verified = await repo!.GetSignalBySidAsync(s.sid);
                                        if (verified != null) nlog.Info($"[Gateway:VERIFY] Persistence Success via DB Check: {s.sid}");
                                        else {
                                            nlog.Error($"[Gateway:VERIFY] Persistence FAIL (Not found in DB) for {s.sid}. Triggering Rollback.");
                                            seq.SetState("RollbackPersistence");
                                            return;
                                        }
                                    }
                                }
                                finally { _saveWaiters.TryRemove(s.sid, out _); }
                            }
                            seq.SetState("Idle");
                        })
                    .ConfigureState("RollbackPersistence")
                        .OnEntry(async () => {
                            var repo = ctx.SignalRepo;
                            if (preparedSignals != null && repo != null) {
                                foreach (var s in preparedSignals) {
                                    if (s.cmd == XCode.CLOSE) continue;
                                    await repo.DeleteSignalAsync(s.sid);
                                    PendingSignals.TryRemove(s.sid, out _);
                                    nlog.Warn($"[Gateway:ROLLBACK] Signal {s.sid} removed from Memory/DB due to downstream failure.");
                                }
                            }
                            seq.SetState("Idle");
                        })
                    .Builder().DisableValidation().Build();

                try 
                {
                    seq.SetState("Enrich");
                    int safety = 0;
                    while (!seq.IsInState("Idle") && safety++ < 10) await seq.RunAsync();
                }
                catch (Exception ex) 
                { 
                    nlog.Error(ex, $"[Gateway:PROC] Signal processing failed for MsgId:{xdo.MsgId}"); 
                    if (preparedSignals != null && ctx.SignalRepo != null)
                    {
                        foreach (var s in preparedSignals)
                        {
                            await ctx.SignalRepo.UpdateSignalStatusAsync(s.sid, 99, $"[GATEWAY-ERR] {ex.Message}");
                        }
                    }
                }
                finally { seq.SetState("Idle"); }
            }
        }
    }
}
