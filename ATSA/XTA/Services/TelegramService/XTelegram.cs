using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using TL;
using XTA.Models;
using XTA.Core;

namespace XTA.Services.TelegramService
{
    public class XTelegram : XTelegramBase
    {
        /// <summary>
        /// 텔레그램 메시지 수신 시 발생하는 이벤트 (UI 대시보드 로그용)
        /// </summary>
        public event Action<XDataObject>? MessageReceived;

        public XTelegram(XParameter param) : base(param)
        {
        }

        public override void Start()
        {
            base.Start();
            nlog?.Trace("[XTelegram] Service class specific Start completed.");
        }

        public override void ProcessSignal(XDataObject xdo)
        {
            if (xdo == null || xdo.CID != this.CID) return;
            nlog?.Trace($"[SIGNAL_PROCESS] CID:{CID} Received Signal Context: {xdo.Text}");
        }

        protected override Task HandleUpdate(UpdatesBase updates)
        {
            if (updates == null) return Task.CompletedTask;
            // Temporary detailed diagnostics: dump registered channels and matching decisions
            try
            {
                if (param?.Channels != null)
                {
                    nlog.Trace($"[TG:DIAG] Registered channel groups: {param.Channels.Count}");
                    int shown = 0;
                    foreach (var grp in param.Channels)
                    {
                        foreach (var ch in grp.Value)
                        {
                            nlog.Trace($"[TG:DIAG] RegisteredChannel[{shown}] CID:{ch.CID} CNO:{ch.CNO} Name:{ch.Name} Type:{ch.Type} RunMode:{ch.RunMode} IsSound:{ch.IsSoundEnabled}");
                            if (++shown >= 50) break;
                        }
                        if (shown >= 50) break;
                    }
                }
                else
                {
                    nlog.Trace("[TG:DIAG] No registered channels found in XParameter.Channels");
                }
            }
            catch (Exception ex)
            {
                nlog.Warn(ex, "[TG:DIAG] Failed to dump registered channels");
            }

            foreach (var update in updates.UpdateList)
            {
                TL.Message? msg = null;

                if (update is UpdateNewChannelMessage uncm && uncm.message is TL.Message m1) msg = m1;
                else if (update is UpdateNewMessage unm && unm.message is TL.Message m2) msg = m2;

                if (msg == null) continue;

                long rawId = msg.peer_id?.ID ?? 0;
                if (rawId == 0) continue;
                long peerId = rawId;

                string channelTitle = "Unknown";
                if (updates.Chats.TryGetValue(rawId, out var chat)) channelTitle = chat.Title ?? "Unknown";

                var matchedChannels = param.GetChannels(peerId);
                
                if (matchedChannels.Count == 0)
                {
                    nlog.Trace($"[TG:DIAG] No direct match for rawId:{rawId}. Attempting fuzzy matching across registered channels.");

                    var matchedInfo = param.Channels.Values.SelectMany(l => l).FirstOrDefault(c =>
                        c.CID == rawId ||
                        c.CID == -rawId ||
                        Math.Abs(c.CID % 1000000000000L) == Math.Abs(rawId % 1000000000000L) ||
                        (uint)c.CID == (uint)rawId ||
                        (int)c.CID == (int)rawId
                    );

                    if (matchedInfo != null)
                    {
                        nlog.Trace($"[TG:DIAG] Fuzzy match succeeded. rawId:{rawId} -> matched CID:{matchedInfo.CID} (CNO:{matchedInfo.CNO}, Name:{matchedInfo.Name})");
                        peerId = matchedInfo.CID;
                        matchedChannels = param.GetChannels(peerId);
                    }
                    else
                    {
                        nlog.Trace($"[TG:DIAG] Fuzzy match failed for rawId:{rawId}. No registered channel matched.");
                    }
                }

                // [v9.8.12] 서비스에 등록되지 않은 채널은 로그 기록을 하지 않는다
                if (matchedChannels.Count == 0) continue;

                // [v9.8.12] Incoming Debug Log moved after registration check to suppress unregistered noise
                nlog.Trace($"[TG:DEBUG] Incoming Update: PeerID:{rawId} (Title:\"{channelTitle}\") | MsgId:{msg.id}");

                string summary = msg.message.Replace("\n", " ");
                if (summary.Length > 50) summary = summary.Substring(0, 50) + "...";

                nlog.Trace($"[SIGNAL:STEP-0:RECEIVE] TG Update Detected. MsgId:{msg.id} | RawPeer:{rawId} (\"{channelTitle}\") | Text:{summary}");

                foreach (var info in matchedChannels)
                {
                    using (NLog.ScopeContext.PushProperty("CNO", info.CNO))
                    {
                        nlog.Info($"[SIGNAL:STEP-0:ACCEPT] CID:{peerId} | CNO:{info.CNO} | Name:{info.Name} | MsgId:{msg.id}");

                        XDataObject xdo = new XDataObject()
                        {
                            Sender = this.GetType().Name,
                            CID = peerId,
                            Text = msg.message,
                            CName = channelTitle,
                            CNO = info.CNO,
                            Timestamp = msg.date,
                            MsgId = msg.id
                        };

                        try
                        {
                            // 1. 게이트웨이 서비스로 직접 전송
                            XContext.Instance.Gateway?.EnqueueRawMessage(xdo);
                            nlog.Info($"[SIGNAL:STEP-0:DISPATCH] Dispatched MsgId:{msg.id} to Gateway Service for CNO:{info.CNO}");

                            // 2. 외부(UI 등) 구독자에게 알림 (구 DashboardChannel 대체)
                            MessageReceived?.Invoke(xdo);
                            nlog.Info($"[SIGNAL:STEP-0:DASHBOARD] Broadcasted TG message event for CNO:{info.CNO}");
                        }
                        catch (Exception ex)
                        {
                            nlog.Error(ex, $"[TG:DISPATCH] Dispatch Error. MsgId:{msg.id} for CNO:{info.CNO}");
                        }
                    }
                }
            }

            return Task.CompletedTask;
        }
    }
}
