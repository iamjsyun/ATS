#ifndef APPORCHESTRATOR_MQH
#define APPORCHESTRATOR_MQH

#include "..\..\Platform\Core\Sequence\CXSequenceOrchestrator.mqh"

/**
 * @class AppOrchestrator
 * @brief [v18.30] 자산 중심 아키텍처에 최적화된 핵심 트레이딩 시퀀스 정의
 */
class AppOrchestrator : public CXSequenceOrchestrator {
public:
    AppOrchestrator() : CXSequenceOrchestrator() {
        Initialize();
    }

    /**
     * @brief [v19.30] 초기화 시퀀스 (SystemMap 추가)
     */
    virtual void Initialize() override {
        RegisterStandardNames();
        InitSystemMap();
        InitWatcherMap();
        InitSessionMap();
    }

    /**
     * @brief [v19.31] 시스템 공통 시퀀스 등록 (Bootstrap)
     */
    void InitSystemMap() {
        string systemDsl[] = {
            "SYS_BOOTSTRAP             > SystemSetup        ? WATCHER_ENTRY_DISCOVERY  ! SYS_ERROR"
        };
        BuildFromDSL(systemDsl, m_watcher_map);
    }

protected:
    virtual void RegisterStandardNames() override {
        // Core Logic States
        m_registry.Add("ORD_TRACKING",   (int)ORD_TRAILING);
        m_registry.Add("POS_MONITORING", (int)POS_ACTIVE);
        m_registry.Add("SYS_CLOSED",     (int)SYS_CLOSED);
        m_registry.Add("SYS_ERROR",      (int)SYS_ERROR);

        // Watcher States
        m_registry.Add("SYS_BOOTSTRAP",           999);
        m_registry.Add("WATCHER_ENTRY_DISCOVERY", 1000);
        m_registry.Add("WATCHER_ENTRY_EXECUTE",   1001);
        m_registry.Add("WATCHER_EXIT_DISCOVERY",  1002);
        m_registry.Add("WATCHER_EXIT_EXECUTE",    1003);
    }

    /**
     * @brief [v18.30] 단순 명확한 4단계 코어 워처 시퀀스 (Discovery ~ Execute)
     */
    virtual void InitWatcherMap() override {
        string unifiedDsl[] = {
            "WATCHER_ENTRY_DISCOVERY   > EntryDiscovery     ? WATCHER_ENTRY_EXECUTE    ! WATCHER_EXIT_DISCOVERY    @ 0s, 0x",
            "WATCHER_ENTRY_EXECUTE     > EntryExecute       ? WATCHER_EXIT_DISCOVERY   ! WATCHER_EXIT_DISCOVERY    @ 0s, 0x",

            "WATCHER_EXIT_DISCOVERY    > ExitDiscovery      ? WATCHER_EXIT_EXECUTE     ! WATCHER_ENTRY_DISCOVERY   @ 0s, 0x",
            "WATCHER_EXIT_EXECUTE      > ExitExecute        ? WATCHER_ENTRY_DISCOVERY  ! WATCHER_ENTRY_DISCOVERY   @ 0s, 0x"
        };
        BuildFromDSL(unifiedDsl, m_watcher_map);
    }

    /**
     * @brief [v18.30] 자산 단위 태스크 시퀀스 (Unit Task DSL)
     */
    virtual void InitSessionMap() override {
        // A. 대기 주문 관리 태스크 (Pending)
        string pendingDsl[] = {
            "ORD_TRACKING                                                                  "
            "> Stage_OrderOptimization                                                     "
            "  : TASK_A_INTENT_WATCH, TASK_P_L_EXTREME, TASK_P_L_REBOUND, TASK_P_L_IMPROVE,  "
            "    TASK_P_R_APPLY, TASK_P_V_SYNC                                             "
            "? ORD_TRACKING                                                                "
            "! SYS_ERROR                                                                   "
            "@ 300s, 0x                                                                    "
            "* 10=POS_MONITORING, 20=SYS_CLOSED" // [v18.39] XE_EXECUTED(10), SESSION_LIQUIDATING(20) 예외 전이 허용
        };
        BuildFromDSL(pendingDsl, m_session_map);

        // B. 포지션 관리 태스크 (Positioned)
        string positionedDsl[] = {
            "POS_MONITORING                                                                "
            "> Stage_PositionGovernance                                                    "
            "  : TASK_A_INTENT_WATCH, TASK_A_ALPHA_CALC, TASK_A_ALPHA_APPLY, TASK_A_V_TERMINAL,"
            "    TASK_A_P_ALIGN                                                            "
            "? POS_MONITORING                                                              "
            "! SYS_ERROR                                                                   "
            "@ 3600s, 0x                                                                   "
            "* 20=SYS_CLOSED" // [v18.39] SESSION_LIQUIDATING(20) 예외 전이 허용
        };
        BuildFromDSL(positionedDsl, m_session_map);

        // C. 청산 관리 태스크 (Exit/Liquidation)
        string exitDsl[] = {
            "SESSION_LIQUIDATING                                                           "
            "> Stage_PositionLiquidation                                                   "
            "  : TASK_A_INTENT_WATCH, TASK_X_L_PREPARE, TASK_X_P_LOCK, TASK_X_R_ORDER,      "
            "    TASK_X_V_ERROR,      TASK_X_V_TERMINAL, TASK_X_P_FINALIZE                 "
            "? SYS_CLOSED                                                                  "
            "! SYS_ERROR                                                                   "
            "@ 300s, 3x"
        };
        BuildFromDSL(exitDsl, m_session_map);
    }
};

#endif
