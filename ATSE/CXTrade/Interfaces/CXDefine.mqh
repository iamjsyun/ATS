#ifndef CX_DEFINE_MQH
#define CX_DEFINE_MQH

/**
 * @file CXDefine.mqh
 * @brief XTA 시스템 전역 상수 및 열거형 정의 (Constants & Enums)
 * @details 상태 코드, 타입 정의, 고정값 등 정적 데이터 정의 모음
 */

//--- 시스템 규격 상수
#define SID_MAX_LENGTH       23
#define GID_MAX_LENGTH       16
#define COMMENT_MAX_LENGTH   31
#define DEFAULT_SLIPPAGE     30
#define MAX_SLIPPAGE         1000

//--- 로그 레벨 정의
enum ENUM_LOG_LEVEL {
    LOG_LVL_TRACE = 0,
    LOG_LVL_INFO  = 1,
    LOG_LVL_DEBUG = 2,
    LOG_LVL_WARN  = 3,
    LOG_LVL_ERROR = 4,
    LOG_LVL_OK    = 5
};

//--- 방향 정의 (dir)
enum ENUM_CX_DIRECTION {
    CX_DIR_NONE = 0,
    CX_DIR_BUY  = 1,
    CX_DIR_SELL = 2
};

//--- 주문 타입 정의
enum ENUM_CX_ORDER_TYPE {
    ORDER_LIMIT_TRAILING = 1,
    ORDER_LIMIT          = 2,
    ORDER_STOP           = 3,
    ORDER_MARKET         = 9
};

//--- XA_INTENT (UI/외부 명령 의도)
enum ENUM_XA_INTENT {
    XA_RAW           = 0,  // 초기 상태
    XA_ACTIVE        = 1,  // 활성화 (진입/청산 실행)
    XA_ARCHIVE_READY = 3   // 이관 대기 (App 마킹)
};

//--- XE_STATUS (EA 실행 상태)
enum ENUM_XE_STATUS {
    XE_READY            = 0,
    XE_PENDING_PLACED   = 1,
    XE_PENDING_REQ      = 2,  // [v9.9.2] 브로커 요청 전 DB 잠금 상태
    XE_IN_TRANSIT       = 3,  // [v9.9.2] 명령 송신 완료, 실물 동기화 대기 중
    XE_EXECUTED         = 10,
    XE_CLOSED_SIGNAL    = 20,
    XE_CLOSED_TP        = 21,
    XE_CLOSED_SL        = 23,
    XE_CLOSED_MANUAL    = 24,
    XE_VERIFY_ABS       = 25, // [v9.9.2] 청산 후 자산 소멸 검증 중
    XE_ERROR            = 99
};

//--- 세션 상태 및 시퀀스 단계 정의 (Sequence States)
enum ENUM_SESSION_STATE {
    SESSION_READY            = 0,
    STATE_ENTRY_TRANSIT      = 3,  // [v9.9.2] 주문 송신 후 브로커 응답 대기 상태
    STATE_ENTRY_VERIFY       = 4,  // [v9.9.2] 브로커 응답 후 실물 자산 존재 확인 상태
    STATE_ENTRY_TRAILING     = 5,
    SESSION_ACTIVE           = 10,
    STATE_SYNC_ALIGN         = 12, // [v9.9.2] DB와 터미널 간 강제 동기화 수행 상태
    STATE_EXIT_TRAILING      = 15,
    SESSION_LIQUIDATING      = 20,
    STATE_LIQUIDATING_TRANSIT = 21, // [v9.9.2] 청산 요청 후 브로커 응답 대기 상태
    STATE_EXIT_SWEEP         = 22,
    STATE_EXIT_VERIFY        = 23,
    SESSION_CLOSED           = 30,
    SESSION_ERROR            = 99
};

//--- Watcher 상태 및 시퀀스 단계 정의 (Watcher Sequence States)
enum ENUM_WATCHER_STATE {
    WATCHER_DISCOVERY      = 0,
    WATCHER_VALIDATION     = 1,
    WATCHER_BINDING        = 2,
    WATCHER_ERROR          = 99
};

//--- 시스템 이벤트 타입 정의
enum ENUM_CX_EVENT {
    EVENT_TICK          = 0,
    EVENT_TRANSACTION   = 1,
    EVENT_TIMER         = 2,
    EVENT_START         = 100,
    EVENT_INJECT        = 101
};

//--- Step 실행 공통 결과 (Generic Step Results)
#define STATE_UNCHANGED     -1

//--- 계산 스텝 결과 (Alpha Calculation Results)
enum ENUM_CALC_RESULT {
    CALC_NO_CHANGE = 0,
    CALC_MODIFIED  = 1
};

#endif
