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
            // 자신과 CNO가 일치하는 메시지만 처리
            if (xdo == null || xdo.CNO != this.Info.CNO) return;
            if (string.IsNullOrWhiteSpace(xdo.Text)) return;

            try
            {
                // [v1.0 Log Diet] 시작 로그 제거하여 노이즈 감소

                // 구체적인 해석 로직 실행 (하위 클래스에서 구현)
                var signals = Interpret(xdo);

                if (signals != null && signals.Count > 0)
                {
                    // 1. 통합로그에 신호 판정된 raw msg 수신 기록
                    nlog.Info($"[TG] {Info.Name} 채널 트레이딩 신호 메세지 수신 (MsgId:{xdo.MsgId}) | Raw: {xdo.Text}");

                    // 2. CNO별 파일에 해석 성공 정보 기록
                    var parseSuccessLog = new LogEventInfo(LogLevel.Info, nlog.Name, $"[SIGNAL:PARSE_SUCCESS] Extracted {signals.Count} base signals from MsgId:{xdo.MsgId}");
                    parseSuccessLog.Properties["CNO"] = Info.CNO;
                    nlog.Log(parseSuccessLog);

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

                            // 3. CNO별 파일에 추출 결과 기록 (CNO 속성 포함)
                            var resultLog = new LogEventInfo(LogLevel.Info, nlog.Name, $"[SIGNAL:RESULT] Dispatching SID:{signal.sid} | CMD:{resultXdo.CMD} | Price:{signal.price_signal} | Lot:{signal.lot}");
                            resultLog.Properties["CNO"] = Info.CNO;
                            nlog.Log(resultLog);

                            // [v9.0] 청산 신호 조기 판별 및 즉각적인 TTS 출력 (가장 빠른 응답성 확보)
                            if (signal.cmd == XCode.CLOSE)
                            {
                                string soundCmd = (signal.sno == 0) ? "GROUP_CLOSE" : "SID_CLOSE";
                                XContext.Instance.Sound?.PlaySound(signal, soundCmd);
                                
                                var ttsTriggerLog = new LogEventInfo(LogLevel.Debug, nlog.Name, $"[INTERPRETER:TTS] Triggered {soundCmd} for EXIT signal (SID:{signal.sid}) immediately after parsing.");
                                ttsTriggerLog.Properties["CNO"] = Info.CNO;
                                nlog.Log(ttsTriggerLog);
                            }

                            // 1. 게이트웨이 파이프라인으로 전송
                            _ = XContext.Instance.Gateway?.ProcessInterpretedSignalAsync(resultXdo);
                        }
                        else
                        {
                            var failLog = new LogEventInfo(LogLevel.Warn, nlog.Name, $"[SIGNAL:FAIL] Validation failed for SID:{signal.sid} | Reason:{signal.comment}");
                            failLog.Properties["CNO"] = Info.CNO;
                            nlog.Log(failLog);
                        }
                    }
                }
                else
                {
                    // 해석 실패(신호가 아님) 시에는 더 이상 파일 로그를 강제 생성하지 않고 무시
                }
            }
            catch (Exception ex)
            {
                nlog.Error(ex, $"[SIGNAL:ERROR] Exception in {GetType().Name} for MsgId:{xdo.MsgId}");
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

