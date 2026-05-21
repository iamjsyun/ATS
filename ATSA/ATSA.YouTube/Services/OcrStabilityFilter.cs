using System.Collections.Generic;
using System.Linq;

namespace ATSA.YouTube.Services
{
    public class OcrStabilityFilter
    {
        private readonly int _bufferSize;
        private readonly double _thresholdPercentage;
        private readonly Queue<string> _historyBuffer;
        private string _lastValidatedText = string.Empty;

        public OcrStabilityFilter(int bufferSize = 10, double thresholdPercentage = 0.8)
        {
            _bufferSize = bufferSize;
            _thresholdPercentage = thresholdPercentage;
            _historyBuffer = new Queue<string>(bufferSize);
        }

        public string? Process(string rawText, out double confidence)
        {
            confidence = 0.0;
            if (string.IsNullOrWhiteSpace(rawText)) return null;

            if (_historyBuffer.Count >= _bufferSize)
            {
                _historyBuffer.Dequeue();
            }
            _historyBuffer.Enqueue(rawText);

            int matchCount = _historyBuffer.Count(x => x == rawText);
            confidence = (double)matchCount / _historyBuffer.Count;

            if (confidence >= _thresholdPercentage)
            {
                if (rawText != _lastValidatedText)
                {
                    _lastValidatedText = rawText;
                    return rawText;
                }
            }

            return null;
        }

        public void Reset()
        {
            _historyBuffer.Clear();
            _lastValidatedText = string.Empty;
        }
    }
}
