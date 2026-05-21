#ifndef CXSEQUENCEORCHESTRATOR_MQH
#define CXSEQUENCEORCHESTRATOR_MQH

#include <Arrays\ArrayObj.mqh>
#include "..\Interfaces\CXDefine.mqh"
#include "..\Infra\CXSequenceRegistry.mqh"

/**
 * @class CXSequenceOrchestrator
 * @brief ATSE 전체 시퀀스 및 태스크 구성을 전담 관리 (SSOT/SSOC 완성)
 */
class CXSequenceOrchestrator : public CObject {
private:
    CArrayObj* m_watcher_map;
    CArrayObj* m_session_map;

public:
    CXSequenceOrchestrator() {
        m_watcher_map = new CArrayObj();
        m_session_map = new CArrayObj();
        InitWatcherMap();
        InitSessionMap();
    }

    ~CXSequenceOrchestrator() {
        SAFE_DELETE(m_watcher_map);
        SAFE_DELETE(m_session_map);
    }

    void BuildWatcherSequence(CXFluentSequence* seq) {
        CXSequenceRegistry::BuildSequence(seq, m_watcher_map);
    }

    void BuildSessionSequence(CXFluentSequence* seq) {
        CXSequenceRegistry::BuildSequence(seq, m_session_map);
    }

private:
    void InitWatcherMap() {
        //--- Watcher Matrix: Discovery -> Validation -> Binding
        m_watcher_map.Add(new CXSequenceStep(ST_W_DISCOVERY,  STEP_W_DISCOVERY,  ST_W_VALIDATION, ST_W_DISCOVERY, T_NONE));
        m_watcher_map.Add(new CXSequenceStep(ST_W_VALIDATION, STEP_W_VALIDATION, ST_W_BINDING,    ST_W_DISCOVERY, T_NONE));
        m_watcher_map.Add(new CXSequenceStep(ST_W_BINDING,    STEP_W_BINDING,    ST_W_DISCOVERY,  ST_W_DISCOVERY, T_NONE));
    }

    void InitSessionMap() {
        //--- Session Matrix (Hyper-Atomized Task Composition)

        // 1. Entry Pipeline
        CXSequenceStep* entry_logic = new CXSequenceStep(ST_S_READY, STEP_S_COMPOSITE, ST_S_ENTRY_TRANSIT, ST_S_ERROR, T_ENTRY_EXIT, 0, "Step_Entry_Logic");
        entry_logic.AddTask(TASK_E_L_VALIDATE)
                   .AddTask(TASK_E_G_SPREAD)
                   .AddTask(TASK_E_G_VOLATILITY)
                   .AddTask(TASK_E_P_LOCK)
                   .AddTask(TASK_E_R_ORDER)
                   .Case(ST_S_ACTIVE, ST_S_ACTIVE)
                   .Case(ST_S_LIQUIDATING, ST_S_LIQUIDATING);
        m_session_map.Add(entry_logic);

        CXSequenceStep* entry_transit = new CXSequenceStep(ST_S_ENTRY_TRANSIT, STEP_S_COMPOSITE, ST_S_ENTRY_VERIFY, ST_S_ERROR, T_VERIFY, 0, "Step_Entry_Transit");
        entry_transit.AddTask(TASK_E_V_ERROR)
                     .AddTask(TASK_E_V_TICKET)
                     .AddTask(TASK_E_V_REAL)
                     .Case(ST_S_LIQUIDATING, ST_S_LIQUIDATING);
        m_session_map.Add(entry_transit);

        CXSequenceStep* entry_verify = new CXSequenceStep(ST_S_ENTRY_VERIFY, STEP_S_COMPOSITE, ST_S_ACTIVE, ST_S_ERROR, T_SHORT, 0, "Step_Entry_Verify");
        entry_verify.AddTask(TASK_E_V_DOUBLECHECK)
                    .AddTask(TASK_E_P_FINALIZE)
                    .Case(ST_S_LIQUIDATING, ST_S_LIQUIDATING);
        m_session_map.Add(entry_verify);

        // 2. Pending Pipeline
        CXSequenceStep* pending = new CXSequenceStep(ST_S_ENTRY_TRAILING, STEP_S_COMPOSITE, ST_S_ACTIVE, ST_S_ERROR, T_NORMAL, 0, "Step_Pending");
        pending.AddTask(TASK_P_V_SYNC)
               .AddTask(TASK_P_L_REBOUND)
               .AddTask(TASK_P_L_IMPROVE)
               .AddTask(TASK_P_R_APPLY);
        m_session_map.Add(pending);

        // 3. Active Pipeline
        CXSequenceStep* active = new CXSequenceStep(ST_S_ACTIVE, STEP_S_COMPOSITE, ST_S_ACTIVE, ST_S_ERROR, T_LONG, 0, "Step_Active");
        active.AddTask(TASK_A_INTENT_WATCH)
              .AddTask(TASK_A_V_STATUS)
              .AddTask(TASK_A_V_STALE)
              .AddTask(TASK_A_V_TERMINAL)
              .AddTask(TASK_A_P_ALIGN)
              .AddTask(TASK_A_L_STATUS)
              .AddTask(TASK_A_ALPHA_CALC)
              .AddTask(TASK_A_ALPHA_APPLY)
              .Case(ST_S_LIQUIDATING, ST_S_LIQUIDATING);
        m_session_map.Add(active);

        // 4. Liquidation Pipeline
        CXSequenceStep* exit_logic = new CXSequenceStep(ST_S_LIQUIDATING, STEP_S_COMPOSITE, ST_S_LIQUIDATING_TRANSIT, ST_S_ERROR, T_ENTRY_EXIT, 3, "Step_Exit_Logic");
        exit_logic.AddTask(TASK_X_L_PREPARE)
                  .AddTask(TASK_X_P_LOCK)
                  .AddTask(TASK_X_R_ORDER);
        m_session_map.Add(exit_logic);

        CXSequenceStep* exit_transit = new CXSequenceStep(ST_S_LIQUIDATING_TRANSIT, STEP_S_COMPOSITE, ST_S_EXIT_VERIFY, ST_S_ERROR, T_VERIFY, 0, "Step_Exit_Transit");
        exit_transit.AddTask(TASK_X_V_ERROR)
                    .AddTask(TASK_X_V_TERMINAL);
        m_session_map.Add(exit_transit);

        CXSequenceStep* exit_verify = new CXSequenceStep(ST_S_EXIT_VERIFY, STEP_S_COMPOSITE, ST_S_CLOSED, ST_S_ERROR, T_SHORT, 0, "Step_Exit_Verify");
        exit_verify.AddTask(TASK_X_P_FINALIZE);
        m_session_map.Add(exit_verify);
    }
};

#endif
