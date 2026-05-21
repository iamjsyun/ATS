#ifndef CX_DEFINE_MQH
#define CX_DEFINE_MQH

/**
 * @file CXDefine.mqh
 * @brief XTA 시스템 전역 상수 및 열거형 정의 (Constants & Enums)
 * @details 상태 코드, 타입 정의, 고정값 등 정적 데이터 정의 모음
 */

//--- 시스템 규격 상수
#define SID_MAX_LENGTH       23
#define GID_MAX_LENGTH       20
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
    XE_UNKNOWN          = -1,
    XE_READY            = 0,
    XE_PENDING_REQ      = 1,  // [v11.3] 브로커 요청 전 DB 잠금 상태
    XE_IN_TRANSIT       = 2,  // [v11.3] 명령 송신 완료, 실물 동기화 대기 중
    XE_PENDING_PLACED   = 5,  // [v11.3] 대기 주문 터미널 등록 완료
    XE_EXECUTED         = 10,
    XE_CLOSED_SIGNAL    = 20,
    XE_CLOSED_SL        = 21, // [v11.3] 손절 청산
    XE_CLOSED_TP        = 22, // [v11.3] 익절 청산
    XE_CLOSED_MANUAL    = 24,
    XE_VERIFY_ABS       = 25,
    XE_ERROR            = 99
};

//--- 세션 상태 및 시퀀스 단계 정의 (Sequence States)
enum ENUM_SESSION_STATE {
    SESSION_READY            = 0,
    STATE_ENTRY_TRANSIT      = 1,  // [v11.3]
    STATE_ENTRY_VERIFY       = 2,  // [v11.3]
    STATE_ENTRY_TRAILING     = 5,  // [v11.3]
    SESSION_ACTIVE           = 10,
    STATE_SYNC_ALIGN         = 12, 
    STATE_EXIT_TRAILING      = 15,
    SESSION_LIQUIDATING      = 20,
    STATE_LIQUIDATING_TRANSIT = 21,
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

//--- 시퀀스 단계 유형 (StepFactory 용)
enum ENUM_STEP_TYPE {
    STEP_NONE = 0,
    //--- Watcher Steps
    STEP_W_DISCOVERY,
    STEP_W_VALIDATION,
    STEP_W_BINDING,
    //--- Session Steps
    STEP_S_COMPOSITE, // Task 기반 복합 단계
    STEP_S_MONITOR
};

//--- 개별 태스크 유형 (TaskFactory 용)
enum ENUM_TASK_TYPE {
    TASK_NONE = 0,
    // Entry
    TASK_E_L_REDIRECT,      // [v11.5] State & Intent Redirect
    TASK_E_L_IDENTITY,      // [v11.5] SID & Magic Validation
    TASK_E_L_RISK,          // [v11.5] Lot & Margin Validation
    TASK_E_L_PRICE,         // [v11.5] Price, SL, TP Calculation
    TASK_E_P_INTENT,        // [v11.5] DB Intent Locking & Price Sync
    TASK_E_L_VALIDATE,
    TASK_E_G_SPREAD,
    TASK_E_G_VOLATILITY,
    TASK_E_P_LOCK,
    TASK_E_R_ORDER,
    TASK_E_V_ERROR,
    TASK_E_V_TICKET,
    TASK_E_V_REAL,
    TASK_E_V_DOUBLECHECK,
    TASK_E_P_FINALIZE,
    // Pending
    TASK_P_V_SYNC,
    TASK_P_L_REBOUND,
    TASK_P_L_IMPROVE,
    TASK_P_R_APPLY,
    // Active
    TASK_A_INTENT_WATCH,
    TASK_A_V_STATUS,
    TASK_A_V_STALE,
    TASK_A_V_TERMINAL,
    TASK_A_P_ALIGN,
    TASK_A_L_STATUS,
    TASK_A_ALPHA_CALC,
    TASK_A_ALPHA_APPLY,
    // Exit
    TASK_X_L_PREPARE,
    TASK_X_P_LOCK,
    TASK_X_R_ORDER,
    TASK_X_V_ERROR,
    TASK_X_V_TERMINAL,
    TASK_X_P_FINALIZE
};

//--- 시퀀스 내 고정 상태 주소 (ST_ 접두사로 통일)
enum ENUM_STATE_ID {
    // Watcher States
    ST_W_DISCOVERY  = WATCHER_DISCOVERY,
    ST_W_VALIDATION = WATCHER_VALIDATION,
    ST_W_BINDING    = WATCHER_BINDING,
    
    // Session States
    ST_S_READY              = SESSION_READY,
    ST_S_ENTRY_TRANSIT      = STATE_ENTRY_TRANSIT,
    ST_S_ENTRY_VERIFY       = STATE_ENTRY_VERIFY,
    ST_S_ENTRY_TRAILING     = STATE_ENTRY_TRAILING,
    ST_S_ACTIVE             = SESSION_ACTIVE,
    ST_S_LIQUIDATING        = SESSION_LIQUIDATING,
    ST_S_LIQUIDATING_TRANSIT = STATE_LIQUIDATING_TRANSIT,
    ST_S_EXIT_VERIFY        = STATE_EXIT_VERIFY,
    ST_S_CLOSED             = SESSION_CLOSED,
    ST_S_ERROR              = SESSION_ERROR
};

//--- 타임아웃 표준 정의
enum ENUM_TIMEOUT_VAL {
    T_NONE       = 0,
    T_SHORT      = 30,
    T_NORMAL     = 3600,
    T_LONG       = 72000,
    T_ENTRY_EXIT = 300,
    T_VERIFY     = 60
};

//--- [v11.4] 시퀀스 무결성 및 DSL 상수
#define SEQ_NODE_DELIMITER   "|"
#define SEQ_STEP_DELIMITER   ":"
#define MAX_RETRY_COUNT      5
#define RETRY_BACKOFF_BASE   1000  // MS

#endif
