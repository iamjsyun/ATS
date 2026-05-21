using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using XTA.Channels;
using XTA.Infrastructure.Data;
using XTA.XData.Interfaces;
using XTA.XData.Models;
using static XTA.XData.Models.XCode;
using XTA.Models;
using XTA.Interfaces;
using XTA.Core;
using FluentSeq;
using System.Threading.Tasks;
using System.Threading.Channels;
using System.Threading;

namespace XTA.Services
{
    /// <summary>
    /// 텔레그램 메시지와 인터프리터 사이의 관문 역할을 하는 서비스.
    /// [Thread-Safe] 생산자-소비자 패턴 및 FluentSeq 상태 머신을 적용함.
    /// [Partial] Core: 필드, 생성자, 속성, 생명주기 관리
    /// </summary>
    public partial class XGatewayService : XChannelObject, IXGatewayService
    {
        public ConcurrentDictionary<string, XDataObject> PendingSignals { get; } = new();

        public event Action<XDataObject>? SignalAddedOrUpdated;
        public event Action<string>? SignalRemoved;

        private ISequence<XHubState> _msgSeq = null!;
        private readonly ConcurrentDictionary<string, TaskCompletionSource<bool>> _saveWaiters = new();
        
        private readonly Channel<XDataObject> _msgChannel = Channel.CreateUnbounded<XDataObject>();
        private readonly Channel<XDataObject> _interpretedChannel = Channel.CreateUnbounded<XDataObject>();
        private CancellationTokenSource? _cts;
        
        // 메시지 소비자 컨텍스트
        private XDataObject? _currentXdo;
        private XChannelInfo? _currentInfo;

        private bool _isStarted = false;
        private readonly HashSet<int> _processedMsgIds = new();

        public XGatewayService(XParameter param) : base(param, new XChannelInfo(0, 0, "GATEWAY_HUB", "SYSTEM"))
        {
            InitSequences();
        }

        public override void Start()
        {
            lock (_processedMsgIds) { if (_isStarted) return; _isStarted = true; }
            _cts = new CancellationTokenSource();
            Task.Run(() => ProcessMessageQueueAsync(_cts.Token));
            Task.Run(() => ProcessInterpretedQueueAsync(_cts.Token));
        }

        public override void Stop() 
        { 
            _cts?.Cancel(); 
            _isStarted = false; 
        }
    }
}
