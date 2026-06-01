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
            Unknown = -1,         // 상태 불명 (초기화 오류 등) (XE_UNKNOWN)
            Ready = 0,            // 신호 주입 완료, 엔진 감지 대기 (XE_READY)
            PendingReq = 1,       // 브로커 주문 송신 중 (DB 잠금) (XE_PENDING_REQ)
            InTransit = 2,        // 브로커 응답 완료, 실물 동기화 대기 (XE_IN_TRANSIT)
            PendingPlaced = 5,    // 대기오더 안착 (단순 대기 상태) (XE_PENDING_PLACED)
            EntryTrailing = 6,    // 진입 트레일링 활성 (ESTART 도달) (XE_ENTRY_TRAILING)
            Executed = 10,        // 포지션 체결 및 유지 중 (XE_EXECUTED)
            StopTrailing = 11,    // 수익보존 트레일링 활성 (SSTART 도달) (XE_STOP_TRAILING)

            // [v16.4 Scenario C] Zombie Asset Quarantine (EA 규격 v4.0 동기화)
            Quarantined = 15,     // 좀비 자산 격리 (수동 확인 필요) (XE_QUARANTINED)

            // [v1.3 Patch] 청산 상세 상태 코드 (XE_CLOSED_XXX)
            Closed_Signal = 20,   // 정상 신호 청산 완료 (XE_CLOSED_SIGNAL)
            Closed_SL = 21,       // 물리적 손절(Stop Loss) 종료 (XE_CLOSED_SL)
            Closed_TP = 22,       // 물리적 익절(Take Profit) 종료 (XE_CLOSED_TP)
            Closed_IKTE = 23,     // 익트 청산 (XE_CLOSED_IKTE)
            Closed_Manual = 24,   // 외부 요인 또는 수동 종료 감지 (XE_CLOSED_MANUAL)
            VerifyAbs = 25,       // 최종 청산 확인 절차 진행 중 (XE_VERIFY_ABS)

            Error = 99            // 실행 오류 (메시지 확인 필수) (XE_ERROR)
        }
    }
}
