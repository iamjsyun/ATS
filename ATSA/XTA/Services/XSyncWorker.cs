using System;
using System.Collections.Generic;
using System.Threading;
using XTA.Infrastructure.Data;
using XTA.Core;
using FluentSeq;

namespace XTA.Services
{
    /// <summary>
    /// 누락된 메시지 복구 및 동기화를 담당하는 워커 (FluentSeq 고도화 버전)
    /// [Partial] Core: 필드, 생성자, 생명주기 관리, 컨텍스트 정의
    /// </summary>
    public partial class XSyncWorker : XObject
    {
        private Timer? _syncTimer;
        private readonly int _intervalSeconds = 10;
        private readonly int _lookbackMinutes = 60;
        private readonly int _maxRetryCount = 5;
        private int _isBusyInt = 0;

        private ISequence<string> _syncSeq = null!;
        private SyncContext _ctx = new();

        public XSyncWorker(XParameter param) : base(param) 
        { 
            InitSequence(); 
        }

        public override void Start()
        {
            _syncTimer = new Timer(OnSyncTimerCallback, null, TimeSpan.FromSeconds(10), TimeSpan.FromSeconds(_intervalSeconds));
            nlog.Trace($"[SyncWorker] Sequential worker started.");
        }

        public override void Stop() 
        { 
            _syncTimer?.Dispose(); 
            nlog.Trace("[SyncWorker] Sequential worker stopped."); 
        }

        private class SyncContext 
        { 
            public XpoSqliteService? DbService { get; set; } 
            public List<int> TradeCnos { get; set; } = new(); 
            public List<XpoTgMessage> PendingMessages { get; set; } = new(); 
        }
    }
}
