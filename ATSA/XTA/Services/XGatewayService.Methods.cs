using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Threading;
using XTA.XData.Models;
using XTA.Models;
using XTA.Core;

namespace XTA.Services
{
    /// <summary>
    /// [Partial] Methods: 비즈니스 로직 및 큐 처리 메서드 (Logic)
    /// </summary>
    public partial class XGatewayService
    {
        public void EnqueueRawMessage(XDataObject xdo) => OnRawMessageReceived(xdo);

        public void Log(string message) => nlog.Info($"[LOG:HUB] {message}");

        private void OnRawMessageReceived(XDataObject xdo)
        {
            if (xdo == null) return;
            lock (_processedMsgIds) {
                if (_processedMsgIds.Contains(xdo.MsgId)) return;
                _processedMsgIds.Add(xdo.MsgId);
                if (_processedMsgIds.Count > 1000) _processedMsgIds.Remove(_processedMsgIds.First());
            }
            if (!_msgChannel.Writer.TryWrite(xdo)) nlog.Error($"[Gateway:ERROR] Msg queue full: MsgId={xdo.MsgId}");
        }

        private async Task ProcessMessageQueueAsync(CancellationToken ct)
        {
            while (await _msgChannel.Reader.WaitToReadAsync(ct)) {
                while (_msgChannel.Reader.TryRead(out var xdo)) {
                    try {
                        _currentXdo = xdo;
                        _currentInfo = param.GetChannel(xdo.CID);
                        _msgSeq.SetState(XHubState.Received);
                        int safety = 0; while (_msgSeq.IsInState(XHubState.Received) && safety++ < 2) _msgSeq.Run();
                    } catch (Exception ex) { nlog.Error(ex, $"[Gateway:MSG] Error: MsgId={xdo?.MsgId}"); }
                }
            }
        }

        public async Task ProcessInterpretedSignalAsync(XDataObject xdo)
        {
            if (xdo == null) return;
            if (!_interpretedChannel.Writer.TryWrite(xdo)) nlog.Error($"[Gateway:ERROR] Interpreted queue full: SID={xdo.Signal?.sid}");
            await Task.CompletedTask;
        }

        private async Task ProcessInterpretedQueueAsync(CancellationToken ct)
        {
            while (await _interpretedChannel.Reader.WaitToReadAsync(ct)) {
                while (_interpretedChannel.Reader.TryRead(out var xdo)) {
                    _ = Task.Run(() => ProcessSignalAsync(xdo), ct);
                }
            }
        }

        public XDataObject? GetNextSignal()
        {
            if (PendingSignals.IsEmpty) return null;
            var firstKey = PendingSignals.Keys.FirstOrDefault();
            if (firstKey != null && PendingSignals.TryRemove(firstKey, out var xdo)) { SignalRemoved?.Invoke(firstKey); return xdo; }
            return null;
        }
    }
}
