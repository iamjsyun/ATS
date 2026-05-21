using System;

namespace XTA.XData.Models
{
    /// <summary>
    /// XTA 시스템 공통 코드 및 상태 정의 (SSOT)
    /// XTA.XData 프로젝트로 이동하여 하위 레이어에서 공통 참조 가능하도록 함.
    /// </summary>
    public static class XCode
    {
        public const string NONE = "NONE";
        public const string TRADE = "TRADE";
        public const string OPEN = "TRADE"; // OPEN is an alias for TRADE
        public const string CLOSE = "CLOSE";
        public const string GRID = "GRID";
        public const int BUY = 1;
        public const int SELL = 2; // v7.5 Standard: 1=BUY, 2=SELL
        public const string GROUP_CLOSE = "GROUP_CLOSE";
        public const string INFO = "INFO";
        // --- 그리드 체계 (G0 ~ G4) ---
        public const int GNO_MASTER = 0;    // G0: 첫 번째 그리드이자 메인 신호
        public const int GNO_MAX = 4;       // 최대 G4까지 가능

        // --- 주문 타입 체계 (XABC v3.5 표준 - CXDefine.mqh 해석) ---
        public const int TYPE_CLOSE = 0;           // 청산 (Liquidation - SID)
        public const int TYPE_LIMIT_TRAILING = 1;  // Type 1: 리미트 트레일링 (Limit Trailing)
        public const int TYPE_LIMIT = 2;           // Type 2: 리미트 (Limit)
        public const int TYPE_STOP = 3;            // Type 3: 스탑 (Stop)
        public const int TYPE_MARKET = 9;          // Type 9: 시장가 (Market)
        /// <summary>
        /// 청산 타입 체계 ---
        /// </summary>
        public const int CLOSE_SID = 0;            // 단일 청산 (SID)
        public const int CLOSE_GROUP = 9;          // 그룹 청산 (GID)

        public const int SNO_DEFAULT = 1;          // 기본 회차

        public const int XA_RAW = 0; 
        public const int XA_ACTIVE = 1; 
        public const int XA_CLOSED_COMPLETED = 2; // [v9.8.5] 청산 완료 (TTS 등 완료 상태 트리거)
        public const int XA_ARCHIVE_READY = 3; 


        /// <summary>
        /// EA(MQL5)에서 사용하는 신호 실행 상태 코드 (Lifecycle v4.0 - CXDefine.mqh 동기화)
        /// </summary>
        public enum EaStatus
        {
            Ready = 0,            // 초기 상태 (XE_READY)
            PendingPlaced = 1,    // 대기 오더 접수 중 (XE_PENDING_PLACED)
            PendingReq = 2,       // [v9.9.2] 브로커 요청 전 DB 잠금 (XE_PENDING_REQ)
            InTransit = 3,        // [v9.9.2] 명령 송신 완료, 동기화 대기 (XE_IN_TRANSIT)
            Executed = 10,        // 체결 완료 / 포지션 진입 (XE_EXECUTED)

            // [v1.5] 익절 트레일링(IkTe) 전용 상태 코드
            IkTeStarted = 15,     // 익절 트레일링 시작 (XE_IKTE_STARTED)
            IkTePriceMoved = 16,  // 익절 트레일링 가격 이동 (XE_IKTE_PRICE_MOVED)

            // [v1.3 Patch] 청산 상세 상태 코드 (XE_CLOSED_XXX)
            Closed_Signal = 20,   // 신호 청산 (XE_CLOSED_SIGNAL)
            Closed_TP = 21,       // 익절 청산 (XE_CLOSED_TP)
            Closed_IKTE = 22,     // 익트 청산 (XE_CLOSED_IKTE)
            Closed_SL = 23,       // 손절 청산 (XE_CLOSED_SL)
            Closed_Manual = 24,   // 수동 청산 (XE_CLOSED_MANUAL)
            VerifyAbs = 25,       // [v9.9.2] 청산 후 소멸 검증 (XE_VERIFY_ABS)

            Error = 99            // 에러 발생 (XE_ERROR)
        }
    }
}
