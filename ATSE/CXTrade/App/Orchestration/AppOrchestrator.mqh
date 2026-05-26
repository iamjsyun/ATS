#ifndef APPORCHESTRATOR_MQH
#define APPORCHESTRATOR_MQH

#include "..\..\Platform\Core\Sequence\CXSequenceOrchestrator.mqh"

/**
 * @class AppOrchestrator
 * @brief [v18.8] 비즈니스 로직(8-Phase) 및 앱 전용 시퀀스 구성을 정의하는 구체 클래스
 * @details 하이퍼-원자적 상태 분할 및 시맨틱 화살표(>) 표기법 전면 적용 완료
 */
class AppOrchestrator : public CXSequenceOrchestrator {
public:
    AppOrchestrator() : CXSequenceOrchestrator() {
        // 부모 생성자 호출 후 자동 초기화
        Initialize();
    }

protected:
    /**
     * @brief [v18.8] 표준 명칭과 실제 상수값 매핑
     */
    virtual void RegisterStandardNames() override {
        // Hyper-Atomic State Mapping (Old Names)
        m_registry.Add("SESSION_READY",           (int)SESSION_READY);
        m_registry.Add("SESSION_VALIDATING",      (int)SESSION_VALIDATING);
        m_registry.Add("SESSION_EXECUTING",       (int)SESSION_EXECUTING);
        m_registry.Add("SESSION_PENDING",         (int)SESSION_PENDING);
        m_registry.Add("SESSION_TRAILING_ENTRY",  (int)SESSION_TRAILING_ENTRY);
        m_registry.Add("SESSION_ACTIVE",          (int)SESSION_ACTIVE);
        m_registry.Add("SESSION_TRAILING_STOP",   (int)SESSION_TRAILING_STOP);
        m_registry.Add("SESSION_LIQUIDATING",     (int)SESSION_LIQUIDATING);
        m_registry.Add("SESSION_CLOSED",          (int)SESSION_CLOSED);
        m_registry.Add("SESSION_ERROR",           (int)SESSION_ERROR);

        // Hyper-Atomic State Mapping (New E2E Names)
        m_registry.Add("ORD_READY",               (int)ORD_READY);
        m_registry.Add("ORD_VALIDATING",          (int)ORD_VALIDATING);
        m_registry.Add("ORD_EXECUTING",           (int)ORD_EXECUTING);
        m_registry.Add("ORD_PENDING",             (int)ORD_PENDING);
        m_registry.Add("ORD_TRAILING",            (int)ORD_TRAILING);
        m_registry.Add("POS_ACTIVE",              (int)POS_ACTIVE);
        m_registry.Add("POS_TRAILING",            (int)POS_TRAILING);
        m_registry.Add("POS_LIQUIDATING",         (int)POS_LIQUIDATING);
        m_registry.Add("SYS_CLOSED",              (int)SYS_CLOSED);
        m_registry.Add("SYS_ERROR",               (int)SYS_ERROR);

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
    }

    /**
     * @brief Watcher DSL 정의 (v18.8 Flow Semantic)
     */
    virtual void InitWatcherMap() override {
        string entryDsl[] = {
            "WATCHER_ENTRY_DISCOVERY  > EntryDiscovery   ? WATCHER_ENTRY_EXECUTE   ! WATCHER_ENTRY_DISCOVERY @ 0s, 0x",
            "WATCHER_ENTRY_EXECUTE    > EntryExecute     ? WATCHER_ENTRY_DISCOVERY ! WATCHER_ENTRY_DISCOVERY @ 0s, 0x"
        };
        BuildFromDSL(entryDsl, m_watcher_map);

        string exitDsl[] = {
            "WATCHER_EXIT_DISCOVERY   > ExitDiscovery    ? WATCHER_EXIT_EXECUTE    ! WATCHER_EXIT_DISCOVERY @ 0s, 0x",
            "WATCHER_EXIT_EXECUTE     > ExitExecute      ? WATCHER_EXIT_DISCOVERY  ! WATCHER_EXIT_DISCOVERY @ 0s, 0x"
        };
        BuildFromDSL(exitDsl, m_watcher_exit_map);
    }

    /**
     * @brief 8-Phase Hyper-Atomic Session DSL (v18.8 Semantic Flow)
     */
    virtual void InitSessionMap() override {
        // Phase 1: Preparation & Execution
        string prepDsl[] = {
            "ORD_READY                                                                     "
            "> Step_OrderValidation                                                        "
            "  : TASK_E_L_VALIDATE, TASK_E_L_IDENTITY, TASK_E_L_RISK, TASK_E_L_PRICE,      "
            "    TASK_E_G_SPREAD, TASK_E_P_INTENT                                          "
            "? ORD_EXECUTING                                                               "
            "! SYS_ERROR                                                                   "
            "@ 60s, 0x",

            "ORD_EXECUTING                                                                 "
            "> Step_OrderPlacement                                                         "
            "  : TASK_A_INTENT_WATCH, TASK_E_R_ORDER, TASK_E_V_ERROR, TASK_E_V_TICKET      "
            "? ORD_PENDING                                                                 "
            "! SYS_ERROR                                                                   "
            "@ 60s, 3x"
        };
        BuildFromDSL(prepDsl, m_session_map);

        // Phase 2: Entry Optimization
        string entryDsl[] = {
            "ORD_PENDING                                                                   "
            "> Step_OrderWatch                                                             "
            "  : TASK_A_INTENT_WATCH, TASK_P_V_TERMINAL, TASK_P_V_SYNC                     "
            "? ORD_TRAILING                                                                "
            "! SYS_ERROR                                                                   "
            "@ 300s, 0x                                                                    "
            "* XE_EXECUTED=POS_ACTIVE",

            "ORD_TRAILING                                                                  "
            "> Step_OrderOptimization                                                      "
            "  : TASK_A_INTENT_WATCH, TASK_P_L_EXTREME, TASK_P_L_REBOUND, TASK_P_L_IMPROVE,  "
            "    TASK_P_R_APPLY, TASK_P_V_SYNC                                             "
            "? POS_ACTIVE                                                                  "
            "! SYS_ERROR                                                                   "
            "@ 3600s, 0x                                                                   "
            "* XE_EXECUTED=POS_ACTIVE"
        };
        BuildFromDSL(entryDsl, m_session_map);

        // Phase 3: Position Management & Profit Trailing
        string positionedDsl[] = {
            "POS_ACTIVE                                                                    "
            "> Step_PositionWatch                                                          "
            "  : TASK_A_INTENT_WATCH, TASK_A_V_TERMINAL, TASK_A_TS_TRIGGER_WATCH           "
            "? POS_TRAILING                                                                "
            "! SYS_ERROR                                                                   "
            "@ 72000s, 0x                                                                  "
            "* XE_CLOSED_SIGNAL=POS_LIQUIDATING",

            "POS_TRAILING                                                                  "
            "> Step_PositionGovernance                                                     "
            "  : TASK_A_INTENT_WATCH, TASK_A_ALPHA_CALC, TASK_A_ALPHA_APPLY, TASK_A_V_TERMINAL"
            "? POS_LIQUIDATING                                                             "
            "! SYS_ERROR                                                                   "
            "@ 72000s, 0x                                                                  "
            "* XE_CLOSED_SIGNAL=POS_LIQUIDATING"
        };
        BuildFromDSL(positionedDsl, m_session_map);

        // Phase 4: Termination
        string exitDsl[] = {
            "POS_LIQUIDATING                                                               "
            "> Step_PositionLiquidation                                                    "
            "  : TASK_A_INTENT_WATCH, TASK_X_L_PREPARE, TASK_X_P_LOCK, TASK_X_R_ORDER,      "
            "    TASK_X_V_ERROR,      TASK_X_V_TERMINAL, TASK_X_P_FINALIZE                 "
            "? SYS_CLOSED                                                                  "
            "! SYS_ERROR                                                                   "
            "@ 300s, 3x",

            "SYS_CLOSED                                                                    "
            "> Step_SystemCleanup                                                          "
            "  : TASK_ACTIVE_CLOSED                                                        "
            "? SYS_CLOSED                                                                  "
            "! SYS_ERROR                                                                   "
            "@ 0s, 0x"
        };
        BuildFromDSL(exitDsl, m_session_map);
    }
};

#endif
