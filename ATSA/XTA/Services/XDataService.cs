using System;
using System.Threading;
using System.Threading.Channels;
using System.Threading.Tasks;
using NLog;
using XTA.Core;
using XTA.Interfaces;
using XTA.Models;
using XTA.XData.Interfaces;

namespace XTA.Services
{
    /// <summary>
    /// 데이터 지속성(DB) 전담 서비스. 
    /// 채널 기반의 비동기 파이프라인을 통해 DB I/O 부하가 엔진에 미치는 영향을 최소화함.
    /// </summary>
    public class XDataService : IDataService, IDisposable
    {
        private static readonly Logger nlog = LogManager.GetCurrentClassLogger();
        private readonly Channel<XDataObject> _dbChannel = Channel.CreateUnbounded<XDataObject>();
        private CancellationTokenSource? _cts;
        private readonly XParameter _param;

        public XDataService(XParameter param)
        {
            _param = param;
            _cts = new CancellationTokenSource();
            Task.Run(() => ProcessDbQueueAsync(_cts.Token));
        }

        public async Task SaveSignalAsync(XSignal sig)
        {
            if (sig == null) return;
            var xdo = new XDataObject { Signal = sig, CMD = "SAVE_SIGNAL" };
            if (!_dbChannel.Writer.TryWrite(xdo))
            {
                nlog.Error($"[Data:ERROR] Failed to enqueue signal save: SID={sig.sid}");
            }
            await Task.CompletedTask;
        }

        public async Task SaveMessageAsync(XDataObject xdo)
        {
            if (xdo == null) return;
            xdo.CMD = "SAVE_MSG";
            if (!_dbChannel.Writer.TryWrite(xdo))
            {
                nlog.Error($"[Data:ERROR] Failed to enqueue message save: MsgId={xdo.MsgId}");
            }
            await Task.CompletedTask;
        }

        public async Task ArchiveSignalsAsync()
        {
            var xdo = new XDataObject { CMD = "ARCHIVE_REQ" };
            await _dbChannel.Writer.WriteAsync(xdo);
        }

        private async Task ProcessDbQueueAsync(CancellationToken ct)
        {
            nlog.Info("[Data:PIPELINE] DB Persistence consumer started.");
            var repo = _param.GetService<ISignalRepository>();

            try
            {
                while (await _dbChannel.Reader.WaitToReadAsync(ct))
                {
                    while (_dbChannel.Reader.TryRead(out var xdo))
                    {
                        try
                        {
                            switch (xdo.CMD)
                            {
                                case "SAVE_SIGNAL":
                                    if (xdo.Signal != null && repo != null)
                                    {
                                        await repo.SaveSignalAsync(xdo.Signal);
                                        nlog.Debug($"[Data:DB] Signal saved: {xdo.Signal.sid}");
                                    }
                                    break;

                                case "SAVE_MSG":
                                    if (repo != null)
                                    {
                                        // 기존 SaveRawSignalAsync 호출 (XpoSqliteService에 구현됨)
                                        await repo.SaveRawSignalAsync(xdo.Signal ?? new XSignal(), xdo.Text ?? "");
                                        nlog.Debug($"[Data:DB] Raw message saved: MsgId={xdo.MsgId}");
                                    }
                                    break;

                                case "ARCHIVE_REQ":
                                    nlog.Info("[Data:DB] Archive request received. Starting transfer sequence...");
                                    await XTAStartupV2.ProcessTransferAsync();
                                    break;
                            }
                        }
                        catch (Exception ex)
                        {
                            nlog.Error(ex, $"[Data:DB] Error in persistence loop: CMD={xdo.CMD}");
                        }
                    }
                }
            }
            catch (OperationCanceledException) { }
            catch (Exception ex)
            {
                nlog.Fatal(ex, "[Data:DB] Critical error in persistence loop.");
            }
        }

        public void Dispose()
        {
            _cts?.Cancel();
            _cts?.Dispose();
        }
    }
}
