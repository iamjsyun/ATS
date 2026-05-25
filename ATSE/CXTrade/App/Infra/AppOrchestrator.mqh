#ifndef APPORCHESTRATOR_MQH
#define APPORCHESTRATOR_MQH

#include "..\..\Session\Sequence\CXSequenceOrchestrator.mqh"

/**
 * @class AppOrchestrator
 * @brief [v16.7] 비즈니스 로직(3-Phase) 및 앱 전용 시퀀스 구성을 정의하는 구체 클래스
 */
class AppOrchestrator : public CXSequenceOrchestrator {
public:
    AppOrchestrator() : CXSequenceOrchestrator() {
        // 부모 생성자 호출 후 자동 초기화
        Initialize();
    }

protected:
    /**
     * @brief [v16.6] 표준 명칭과 실제 상수값 매핑
     */
    virtual void RegisterStandardNames() override {
        // [v16.9] Exact Enum Identity Mapping
        // Session States (Align with ENUM_SESSION_STATE)
        m_registry.Add("SESSION_READY",        (int)SESSION_READY);
        m_registry.Add("SESSION_ACTIVE",       (int)SESSION_ACTIVE);
        m_registry.Add("SESSION_LIQUIDATING",  (int)SESSION_LIQUIDATING);
        m_registry.Add("SESSION_CLOSED",       (int)SESSION_CLOSED);
        m_registry.Add("SESSION_ERROR",        (int)SESSION_ERROR);

        // XE_STATUS Anchors (For Internal Logic)
        m_registry.Add("XE_READY",             (int)XE_READY);
        m_registry.Add("XE_PENDING_REQ",       (int)XE_PENDING_REQ);
        m_registry.Add("XE_IN_TRANSIT",        (int)XE_IN_TRANSIT);
        m_registry.Add("XE_PENDING_PLACED",    (int)XE_PENDING_PLACED);
        m_registry.Add("XE_EXECUTED",          (int)XE_EXECUTED);
        m_registry.Add("XE_CLOSED_SIGNAL",     (int)XE_CLOSED_SIGNAL);
        m_registry.Add("XE_CLOSED_SL",         (int)XE_CLOSED_SL);
        m_registry.Add("XE_CLOSED_TP",         (int)XE_CLOSED_TP);
        m_registry.Add("XE_ERROR",             (int)XE_ERROR);

        // Watcher States (Align with ENUM_WATCHER_STATE)
        m_registry.Add("WATCHER_DISCOVERY",    (int)WATCHER_DISCOVERY);
        m_registry.Add("WATCHER_VALIDATION",   (int)WATCHER_VALIDATION);
        m_registry.Add("WATCHER_SPAWNING",     (int)WATCHER_SPAWNING);
        m_registry.Add("WATCHER_ERROR",        (int)WATCHER_ERROR);
    }

    /**
     * @brief Watcher DSL 정의 (Exact Enum Names)
     */
    virtual void InitWatcherMap() override {
        string dsl[] = {
            "WATCHER_DISCOVERY  | Discovery:Step_Discovery   ? WATCHER_VALIDATION ! WATCHER_DISCOVERY @ 0s, 0x",
            "WATCHER_VALIDATION | Validation:Step_Validation ? WATCHER_SPAWNING   ! WATCHER_DISCOVERY @ 0s, 0x",
            "WATCHER_SPAWNING   | Spawning:Step_Spawning     ? WATCHER_DISCOVERY  ! WATCHER_DISCOVERY @ 0s, 0x"
        };
        BuildFromDSL(dsl, m_watcher_map);
    }

    /**
     * @brief 3-Phase Session DSL 정의 (Exact Enum Names)
     */
    virtual void InitSessionMap() override {
        // Phase 1: Pending & Entry Trailing
        string pendingDsl[] = {
            "SESSION_READY                                                                 "
            "| Composite:Step_Pending                                                      "
            "  : TASK_A_INTENT_WATCH, TASK_E_L_REDIRECT, TASK_E_L_IDENTITY, TASK_E_L_RISK, "
            "    TASK_E_L_PRICE,      TASK_E_G_SPREAD,   TASK_E_P_INTENT,   TASK_E_R_ORDER,"
            "    TASK_E_V_ERROR,      TASK_E_V_TICKET,   TASK_E_V_REAL,     TASK_E_V_DOUBLECHECK,"
            "    TASK_E_P_FINALIZE,   TASK_P_V_SYNC,     TASK_P_L_REBOUND,  TASK_P_L_IMPROVE,  "
            "    TASK_P_R_APPLY                                                            "
            "? SESSION_ACTIVE                                                              "
            "! SESSION_ERROR                                                               "
            "@ 3600s, 0x                                                                   "
            "* XE_EXECUTED=SESSION_ACTIVE, XE_CLOSED_SIGNAL=SESSION_LIQUIDATING           "
        };
        BuildFromDSL(pendingDsl, m_session_map);

        // Phase 2: Active & Profit Trailing
        string activeDsl[] = {
            "SESSION_ACTIVE                                                                "
            "| Composite:Step_Active                                                       "
            "  : TASK_A_INTENT_WATCH, TASK_A_V_STATUS, TASK_A_V_TERMINAL, TASK_A_P_ALIGN,  "
            "    TASK_A_ALPHA_CALC,   TASK_A_ALPHA_APPLY                                   "
            "? SESSION_LIQUIDATING                                                         "
            "! SESSION_ERROR                                                               "
            "@ 72000s, 0x                                                                  "
            "* XE_CLOSED_SIGNAL=SESSION_LIQUIDATING                                        "
        };
        BuildFromDSL(activeDsl, m_session_map);

        // Phase 3: Liquidation & Finalization
        string exitDsl[] = {
            "SESSION_LIQUIDATING                                                           "
            "| Composite:Step_Exit                                                         "
            "  : TASK_A_INTENT_WATCH, TASK_X_L_PREPARE, TASK_X_P_LOCK, TASK_X_R_ORDER,      "
            "    TASK_X_V_ERROR,      TASK_X_V_TERMINAL, TASK_X_P_FINALIZE                 "
            "? SESSION_CLOSED                                                              "
            "! SESSION_ERROR                                                               "
            "@ 300s, 3x                                                                    "
        };
        BuildFromDSL(exitDsl, m_session_map);
    }
};

#endif
