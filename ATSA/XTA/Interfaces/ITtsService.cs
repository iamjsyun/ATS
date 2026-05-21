using System;

namespace XTA.Interfaces
{
    public interface ITtsService
    {
        void Speak(string text);
        void Start();
        void Stop();
    }
}
