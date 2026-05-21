using System;
using System.Threading.Tasks;
using TL;
using XTA.Core;
using XTA.Models;
using XTA.Services.TelegramService;

namespace ATSA.Services
{
    /// <summary>
    /// XTA의 XTelegram을 상속받아 UI 직접 연동 기능을 추가한 서비스
    /// </summary>
    public class XTelegramUI : XTelegram
    {
        public XTelegramUI(XParameter param) : base(param)
        {
        }

        /// <summary>
        /// 대시보드 로그 전용 이벤트 (필요 시 HandleUpdate에서 직접 처리도 가능)
        /// </summary>
        // public event Action<XDataObject>? UIMessageReceived;

        protected override Task HandleUpdate(UpdatesBase updates)
        {
            // 부모의 HandleUpdate가 Gateway 전송 및 기본 MessageReceived 이벤트를 처리함
            return base.HandleUpdate(updates);
        }

        // 부모의 MessageReceived 이벤트를 활용하여 UI 전용 처리를 추가할 수 있음
    }
}
