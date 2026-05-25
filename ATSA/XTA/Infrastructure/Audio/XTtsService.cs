using System;
using System.Speech.Synthesis;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Concurrent;
using XTA.Models;
using XTA.Interfaces;

namespace XTA.Infrastructure.Audio
{
    public class XTtsService : XChannelObject, ITtsService
    {
        private readonly SpeechSynthesizer _synth = new();
        private readonly BlockingCollection<string> _speechQueue = new();
        private readonly CancellationTokenSource _cts = new();

        public XTtsService(XParameter param) : base(param, new XChannelInfo(0, 0, "TTS_SERVICE", "SYSTEM"))
        {
            try
            {
                var voices = _synth.GetInstalledVoices();
                foreach (var voice in voices)
                {
                    if (voice.VoiceInfo.Culture.Name.Contains("ko")) { _synth.SelectVoice(voice.VoiceInfo.Name); break; }
                }
                _synth.Rate = 1;
                _synth.Volume = Math.Clamp(param.Config.System.TtsVolume, 0, 100);
            }
            catch { }

            Task.Run(() => ProcessQueue(_cts.Token));
        }

        public override void Start() => nlog.Trace("[TTS] XTtsService Started (Interface Enabled).");

        public override void Stop()
        {
            _cts.Cancel();
            _speechQueue.CompleteAdding();
            try { _synth.SpeakAsyncCancelAll(); _synth.Dispose(); } catch { }
            nlog.Trace("[TTS] XTtsService Stopped.");
        }

        public void Speak(string text)
        {
            if (string.IsNullOrEmpty(text) || _speechQueue.IsAddingCompleted) return;
            try
            {
                _speechQueue.Add(text);
                nlog.Trace($"[TTS] Enqueued: {text}");
            }
            catch (Exception ex) { nlog.Error(ex, "[TTS] Enqueue Error."); }
        }

        private void ProcessQueue(CancellationToken token)
        {
            try
            {
                foreach (var text in _speechQueue.GetConsumingEnumerable(token))
                {
                    try { _synth.Speak(text); }
                    catch (OperationCanceledException) { break; }
                    catch (Exception ex) { nlog.Error(ex, $"[TTS:Worker] Speech Error: {text}"); }
                }
            }
            catch (OperationCanceledException) { }
        }
    }
}
