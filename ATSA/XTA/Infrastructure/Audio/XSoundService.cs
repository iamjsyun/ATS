using NLog;
using System;
using System.IO;
using XTA.Models;
using XTA.XData.Models;
using XSignal = XTA.Models.XSignal;
using FluentSeq;
using XTA.Interfaces;
using XTA.Core;

namespace XTA.Infrastructure.Audio
{
    /// <summary>
    /// TTS 출력을 총괄하는 서비스 (Messenger 제거 및 고도화 버전)
    /// </summary>
    public class XSoundService : XChannelObject, ISoundService
    {
        private readonly object _spamLock = new();
        private readonly object _seqLock = new(); // [v9.0] 시퀀스 처리용 락
        private readonly System.Collections.Generic.HashSet<string> _playedCache = new(); // [v14.41] 세션 기반 중복 방지 캐시
        private string _lastSid = string.Empty;
        private string _lastEvent = string.Empty;
        private DateTime _lastPlayTime = DateTime.MinValue;

        private ISequence<XSoundState> _sequence = null!;
        private XDataObject? _currentXdo;
        private string _currentTtsMsg = string.Empty;

        public XSoundService(XParameter param) : base(param, new XChannelInfo(0, 0, "SOUND_SERVICE", "SYSTEM"))
        {
            nlog = LogManager.GetLogger(GetType().FullName ?? "XTA.TTS.XSoundService");
            InitSequence();
        }

        private void InitSequence()
        {
            // [v9.0] Idle 상태로 안전하게 시작 (생성자 크래시 방지)
            _sequence = new FluentSeq<XSoundState>().Create(XSoundState.Idle)
                
                // 1. 초기 상태: 대기
                .ConfigureState(XSoundState.Idle)

                // 2. 요청 수신 상태
                .ConfigureState(XSoundState.RequestReceived)

                // 3. 억제 상태 (필터링 우선 순위: Spam/Channel/Status 체크)
                .ConfigureState(XSoundState.Suppressed)
                    .TriggeredBy(() => _currentXdo?.Signal != null && IsSpam(_currentXdo.Signal.sid, _currentXdo.CMD))
                        .WhenInState(XSoundState.RequestReceived)
                    .TriggeredBy(() => IsAlreadyPlayed(_currentXdo?.Signal?.sid, _currentXdo?.CMD))
                        .WhenInState(XSoundState.RequestReceived)
                    .TriggeredBy(() => _currentXdo?.Signal != null && !IsTargetChannel(_currentXdo.Signal.cno))
                        .WhenInState(XSoundState.RequestReceived)
                    .TriggeredBy(() => _currentXdo?.Signal?.xe_status == (int)XCode.EaStatus.InTransit)
                        .WhenInState(XSoundState.RequestReceived)
                    .OnEntry(() => {
                        if (_currentXdo?.Signal != null) {
                            if (IsSpam(_currentXdo.Signal.sid, _currentXdo.CMD))
                                nlog.Debug($"[Sound:SUPPRESSED] Anti-Spam blocked SID:{_currentXdo.Signal.sid} Cmd:{_currentXdo.CMD}");
                            else if (IsAlreadyPlayed(_currentXdo.Signal.sid, _currentXdo.CMD))
                                nlog.Debug($"[Sound:SUPPRESSED] Already played in this session: SID:{_currentXdo.Signal.sid} Cmd:{_currentXdo.CMD}");
                            else if (!IsTargetChannel(_currentXdo.Signal.cno))
                                nlog.Debug($"[Sound:SUPPRESSED] Channel {_currentXdo.Signal.cno} has Sound Disabled or not registered.");
                            else if (_currentXdo.Signal.xe_status == (int)XCode.EaStatus.InTransit)
                                nlog.Debug($"[Sound:SUPPRESSED] Execution in progress for SID:{_currentXdo.Signal.sid}");
                        }
                    })

                // 4. 완료 상태 (직접 텍스트 요청 처리)
                .ConfigureState(XSoundState.Completed)
                    .TriggeredBy(() => _currentXdo != null && !string.IsNullOrEmpty(_currentXdo.Text))
                        .WhenInState(XSoundState.RequestReceived)
                    .TriggeredBy(() => !string.IsNullOrEmpty(_currentTtsMsg))
                        .WhenInState(XSoundState.Composed)
                    .OnEntry(() => {
                        string msgToSpeak = string.IsNullOrEmpty(_currentTtsMsg) ? (_currentXdo?.Text ?? "") : _currentTtsMsg;
                        if (!string.IsNullOrEmpty(msgToSpeak))
                        {
                            nlog.Debug($"[Sound:EXECUTE] TTS Output: {msgToSpeak}");
                            XContext.Instance.GetService<ITtsService>()?.Speak(msgToSpeak);
                            
                            // [v14.41] 성공적으로 출력 대기열에 추가된 경우 캐시에 기록
                            if (_currentXdo?.Signal != null && !string.IsNullOrEmpty(_currentXdo.CMD))
                                MarkAsPlayed(_currentXdo.Signal.sid, _currentXdo.CMD);
                        }
                    })

                // 5. 메시지 조립 상태 (v9.7 SRP 리팩토링)
                .ConfigureState(XSoundState.Composed)
                    .TriggeredBy(() => _currentXdo?.Signal != null && !string.IsNullOrEmpty(_currentXdo.CMD))
                        .WhenInState(XSoundState.RequestReceived)
                    .OnEntry(() => {
                        if (string.IsNullOrEmpty(_currentXdo!.Text))
                        {
                            _currentTtsMsg = GetTtsMessage(_currentXdo.Signal!, _currentXdo.CMD!);
                            nlog.Debug($"[Sound:COMPOSE] Generated Msg: {_currentTtsMsg} (SID:{_currentXdo.Signal!.sid})");
                        }
                        else
                        {
                            _currentTtsMsg = _currentXdo.Text;
                        }
                        
                        UpdateSpamInfo(_currentXdo.Signal!.sid, _currentXdo.CMD!);
                    })

                .Builder()
                .DisableValidation()
                .Build();
        }

        public void PlaySound(XSignal? sig, string cmd, string text = "", bool force = false)
        {
            // [v9.0] 스레드 안전성 보장
            lock (_seqLock)
            {
                nlog.Debug($"[Sound:REQUEST] SID:{sig?.sid ?? "N/A"} Cmd:{cmd}");
                _currentXdo = new XDataObject { Signal = sig, CMD = cmd, Text = text, Force = force };
                _currentTtsMsg = string.Empty;
                _sequence.SetState(XSoundState.RequestReceived);
                
                int safetyCounter = 0;
                while (!_sequence.IsInState(XSoundState.Completed) && 
                       !_sequence.IsInState(XSoundState.Suppressed) && 
                       safetyCounter++ < 5)
                {
                    _sequence.Run();
                }
                
                if (safetyCounter >= 5) nlog.Warn($"[Sound:TIMEOUT] Sequence failed to reach terminal state for SID:{sig?.sid}");
            }
        }

        public override void Start() => nlog.Trace("[SoundService] Service Started (Interface Enabled).");
        public override void Stop() => nlog.Trace("[SoundService] Service Stopped.");

        private bool IsSpam(string sid, string? cmd)
        {
            lock (_spamLock) { return sid == _lastSid && cmd == _lastEvent && (DateTime.Now - _lastPlayTime).TotalSeconds < 2; }
        }

        private void UpdateSpamInfo(string sid, string cmd)
        {
            lock (_spamLock) { _lastSid = sid; _lastEvent = cmd; _lastPlayTime = DateTime.Now; }
        }

        private string GetTtsMessage(XSignal sig, string eventType)
        {
            string cnoStr = GetDigitString(sig.cno);
            string dirName = (sig.dir == 2) ? "매도" : "매수"; 

            return eventType switch
            {
                "SIGNAL_RECEIVED" => $"{cnoStr} 채널 {sig.sno}회차 {dirName} 신호 발생",
                "ORDER_PLACED" => $"{cnoStr} 채널 {sig.sno}회차 {dirName} 주문 접수 완료",
                "POSITION_ENTERED" => $"{cnoStr} 채널 {sig.sno}회차 {dirName} 진입 완료",
                "POSITION_CLOSED" => $"{cnoStr} 채널 {sig.sno}회차 {dirName} 청산 완료",
                "GROUP_CLOSE" => $"{cnoStr} 채널 그룹 청산 명령 발생",
                "SID_CLOSE" => $"{cnoStr} 채널 {sig.sno}회차 개별 청산 명령 발생",
                "SID_COMPLETED" => $"{cnoStr} 채널 {sig.sno}회차 청산 완료 확인",
                "SID_ARCHIVED" => $"{cnoStr} 채널 {sig.sno}회차 데이터 이관 대기",
                "TE_TRIGGERED" => $"{cnoStr} 채널 {dirName} 진입 추적 가동",
                "CLOSE_STRATEGY_STARTED" => $"{cnoStr} 채널 {sig.sno}회차 청산 전략이 가동되었습니다.",
                _ => string.Empty
            };
        }

        private string GetDigitString(int value)
        {
            string s = value.ToString();
            string result = "";
            foreach (char c in s) { result += c switch { '0' => "영 ", '1' => "일 ", '2' => "이 ", '3' => "삼 ", '4' => "사 ", '5' => "오 ", '6' => "육 ", '7' => "칠 ", '8' => "팔 ", '9' => "구 ", _ => c + " " }; }
            return result.Trim();
        }

        private bool IsTargetChannel(int cno)
        {
            var channel = param.GetChannelByCno(cno);
            return channel != null && channel.IsSoundEnabled;
        }

        private bool IsAlreadyPlayed(string? sid, string? cmd)
        {
            if (string.IsNullOrEmpty(sid) || string.IsNullOrEmpty(cmd)) return false;
            lock (_playedCache) { return _playedCache.Contains($"{sid}:{cmd}"); }
        }

        private void MarkAsPlayed(string sid, string cmd)
        {
            lock (_playedCache) { _playedCache.Add($"{sid}:{cmd}"); }
        }

        // Clear entries for a specific SID (all commands) - used when lifecycle completes and replay should be allowed
        public void ClearPlayedForSid(string sid)
        {
            if (string.IsNullOrEmpty(sid)) return;
            lock (_playedCache)
            {
                var toRemove = new System.Collections.Generic.List<string>();
                foreach (var k in _playedCache)
                {
                    if (k.StartsWith(sid + ":")) toRemove.Add(k);
                }
                foreach (var r in toRemove) _playedCache.Remove(r);
            }
        }

        // Clear entire session cache (not recommended for normal use)
        public void ClearAllPlayed()
        {
            lock (_playedCache) { _playedCache.Clear(); }
        }
    }
}
