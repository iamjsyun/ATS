using NLog;
using System;
using System.Collections.Generic;
using XTA.Models;
using XTA.XData.Models;
using XSignal = XTA.Models.XSignal;
using XTA.Core;
using System.Threading.Tasks;

namespace XTA.Channels
{
    /// <summary>
    /// ?붾젅洹몃옩 梨꾨꼸 ?댁꽍湲곕? ?꾪븳 怨듯넻 踰좎씠???대옒??
    /// </summary>
    public abstract class XInterpreterBase : XChannelObject, IDisposable
    {
        protected bool _isInitialized = false;
        protected readonly object _syncRoot = new object();
        protected ulong Magic { get; set; } = 0;

        protected XInterpreterBase(XParameter param, XChannelInfo info) : base(param, info) { Magic = (ulong)info.CNO; }

        public override void Start()
        {
            EnsureInitialized();
            nlog.Trace($"[INTERPRETER:START] {GetType().Name} (CNO:{Info.CNO}, Magic:{Magic})");
        }

        public override void Stop() => Dispose();

        public virtual void Dispose()
        {
            lock (_syncRoot)
            {
                if (_isInitialized)
                {
                    _isInitialized = false;
                }
            }
        }

        private void EnsureInitialized()
        {
            if (_isInitialized) return;
            lock (_syncRoot)
            {
                if (_isInitialized) return;
                _isInitialized = true;
            }
        }

        /// <summary>
        /// 寃뚯씠?몄썾?대줈遺??硫붿떆吏瑜??꾨떖諛쏆븘 ?댁꽍 (援?OnMessageReceived ?泥?
        /// </summary>
        public void EnqueueMessage(XDataObject xdo)
        {
            // ?먯떊??CNO? ?쇱튂?섎뒗 硫붿떆吏留?泥섎━
            if (xdo == null || xdo.CNO != this.Info.CNO) return;
            if (string.IsNullOrWhiteSpace(xdo.Text)) return;

            try
            {
                nlog.Info($"[SIGNAL:STEP-2:PARSE] Interpreter {GetType().Name} started. MsgId:{xdo.MsgId} | CNO:{Info.CNO} | TextLen:{xdo.Text.Length}");

                // 援ъ껜?곸씤 ?댁꽍 濡쒖쭅 ?ㅽ뻾 (?섏쐞 ?대옒?ㅼ뿉??援ы쁽)
                var signals = Interpret(xdo);

                if (signals != null && signals.Count > 0)
                {
                    nlog.Info($"[SIGNAL:STEP-2:PARSE] Success. Extracted {signals.Count} base signals from MsgId:{xdo.MsgId}");
                    foreach (var signal in signals)
                    {
                        if (signal.Validate())
                        {
                            XDataObject resultXdo = new XDataObject
                            {
                                Sender = this.GetType().Name,
                                CID = xdo.CID,
                                CName = xdo.CName,
                                Text = xdo.Text,
                                MsgId = xdo.MsgId,
                                Signal = signal,
                                CNO = Info.CNO,
                                CMD = signal.cmd == XCode.CLOSE ? "CLOSE" : "NEW"
                            };

                            nlog.Info($"[SIGNAL:STEP-2:RESULT] Dispatching SID:{signal.sid} | CMD:{resultXdo.CMD} | Price:{signal.price_signal}");

                            // [v9.0] 泥?궛 ?좏샇 議곌린 ?먮퀎 諛?利됯컖?곸씤 TTS 異쒕젰 (媛??鍮좊Ⅸ ?묐떟???뺣낫)
                            if (signal.cmd == XCode.CLOSE)
                            {
                                string soundCmd = (signal.sno == 0) ? "GROUP_CLOSE" : "SID_CLOSE";
                                XContext.Instance.Sound?.PlaySound(signal, soundCmd);
                                nlog.Debug($"[INTERPRETER:TTS] Triggered {soundCmd} for EXIT signal (SID:{signal.sid}) immediately after parsing.");
                            }

                            // 1. 寃뚯씠?몄썾???뚯씠?꾨씪?몄쑝濡??꾩넚
                            _ = XContext.Instance.Gateway?.ProcessInterpretedSignalAsync(resultXdo);
                        }
                        else
                        {
                            nlog.Warn($"[SIGNAL:STEP-2:FAIL] Validation failed for SID:{signal.sid} | Reason:{signal.comment}");
                        }
                    }
                }
                else
                {
                    nlog.Warn($"[SIGNAL:STEP-2:FAIL] No valid signals extracted from MsgId:{xdo.MsgId}. Check interpreter logic.");
                }
            }
            catch (Exception ex)
            {
                nlog.Error(ex, $"[SIGNAL:STEP-2:ERROR] Exception in {GetType().Name} for MsgId:{xdo.MsgId}");
            }
        }

        /// <summary>
        /// ?섏떊??硫붿떆吏濡쒕????쒓렇??由ъ뒪?몃? 異붿텧?섎뒗 ?듭떖 硫붿꽌??
        /// </summary>
        public abstract List<XSignal> Interpret(XDataObject xdo);

        /// <summary>
        /// 湲곕낯 ?쒓렇??媛앹껜 ?앹꽦 (怨듯넻 ?띿꽦 誘몃━ ?ㅼ젙)
        /// </summary>
        protected XSignal CreateBaseSignal(XDataObject xdo, string symbol = "GOLD")
        {
            return new XSignal
            {
                msg_id = xdo.MsgId,
                symbol = symbol,
                created = xdo.Timestamp,
                magic = (long)Magic,
                cno = Info.CNO,
                cmd = XCode.OPEN
            };
        }
    }
}

