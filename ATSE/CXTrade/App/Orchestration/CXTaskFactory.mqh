#ifndef CXTASKFACTORY_MQH
#define CXTASKFACTORY_MQH

#include "..\..\Platform\Core\Interfaces\IXTask.mqh"
#include "..\..\Platform\Core\Macros\CXMacros.mqh"

// Entry Tasks
#include "..\..\Session\Workflow\Entry\CXTaskEntry_L_Redirect.mqh"
#include "..\..\Session\Workflow\Entry\CXTaskEntry_L_Identity.mqh"
#include "..\..\Session\Workflow\Entry\CXTaskEntry_L_Risk.mqh"
#include "..\..\Session\Workflow\Entry\CXTaskEntry_L_Price.mqh"
#include "..\..\Session\Workflow\Entry\CXTaskEntry_P_Intent.mqh"
#include "..\..\Session\Workflow\Entry\CXTaskEntry_L_Validate.mqh"
#include "..\..\Session\Workflow\Entry\CXTaskGuard_V_Spread.mqh"
#include "..\..\Session\Workflow\Entry\CXTaskGuard_V_Volatility.mqh"
#include "..\..\Session\Workflow\Entry\CXTaskEntry_P_Lock.mqh"
#include "..\..\Session\Workflow\Entry\CXTaskEntry_R_Order.mqh"
#include "..\..\Session\Workflow\Entry\CXTaskEntry_V_Error.mqh"
#include "..\..\Session\Workflow\Entry\CXTaskEntry_V_TICKET.mqh"
#include "..\..\Session\Workflow\Entry\CXTaskEntry_V_REAL.mqh"
#include "..\..\Session\Workflow\Entry\CXTaskFinalize_V_DoubleCheck.mqh"
#include "..\..\Session\Workflow\Entry\CXTaskEntry_P_Finalize.mqh"

// Pending Tasks
#include "..\..\Session\Workflow\Pending\CXTaskPending_V_Sync.mqh"
#include "..\..\Session\Workflow\Pending\CXTaskPending_V_Terminal.mqh"
#include "..\..\Session\Workflow\Pending\CXTaskPending_P_Align.mqh"
#include "..\..\Session\Workflow\Pending\CXTaskPending_L_Rebound.mqh"
#include "..\..\Session\Workflow\Pending\CXTaskPending_L_Improve.mqh"
#include "..\..\Session\Workflow\Pending\CXTaskPending_L_Extreme.mqh"
#include "..\..\Session\Workflow\Pending\CXTaskPending_R_Apply.mqh"

// Active Tasks
#include "..\..\Session\Workflow\Active\CXTaskIntentWatch.mqh"
#include "..\..\Session\Workflow\Active\CXTaskComm_V_Status.mqh"
#include "..\..\Session\Workflow\Active\CXTaskSync_V_Stale.mqh"
#include "..\..\Session\Workflow\Active\CXTaskActive_V_Terminal.mqh"
#include "..\..\Session\Workflow\Active\CXTaskActive_P_Align.mqh"
#include "..\..\Session\Workflow\Active\CXTaskActive_L_Status.mqh"
#include "..\..\Session\Workflow\Active\CXTaskAlphaCalc.mqh"
#include "..\..\Session\Workflow\Active\CXTaskAlphaApply.mqh"
#include "..\..\Session\Workflow\Active\CXTaskActive_TS_TriggerWatch.mqh"
#include "..\..\Session\Workflow\Active\CXTaskActive_Closed.mqh"

// Exit Tasks
#include "..\..\Session\Workflow\Exit\CXTaskExit_L_Prepare.mqh"
#include "..\..\Session\Workflow\Exit\CXTaskExit_P_Lock.mqh"
#include "..\..\Session\Workflow\Exit\CXTaskExit_R_Order.mqh"
#include "..\..\Session\Workflow\Exit\CXTaskExit_V_Error.mqh"
#include "..\..\Session\Workflow\Exit\CXTaskExit_V_Terminal.mqh"
#include "..\..\Session\Workflow\Exit\CXTaskExit_P_Finalize.mqh"

/**
 * @class CXTaskFactory
 * @brief [v17.6] 문자열 기반 IXTask 객체 생성을 담당 (Hyper-Atomic)
 */
class CXTaskFactory {
public:
    /**
     * @brief [v17.6] 문자열 이름을 기반으로 IXTask 객체 생성
     */
    static IXTask* CreateTask(string name) {
        // Entry
        if(name == "TASK_E_L_REDIRECT")    return new CXTaskEntry_L_Redirect();
        if(name == "TASK_E_L_IDENTITY")    return new CXTaskEntry_L_Identity();
        if(name == "TASK_E_L_RISK")        return new CXTaskEntry_L_Risk();
        if(name == "TASK_E_L_PRICE")       return new CXTaskEntry_L_Price();
        if(name == "TASK_E_P_INTENT")      return new CXTaskEntry_P_Intent();
        if(name == "TASK_E_L_VALIDATE")    return new CXTaskEntry_L_Validate();
        if(name == "TASK_E_G_SPREAD")      return new CXTaskGuard_V_Spread();
        if(name == "TASK_E_G_VOLATILITY")  return new CXTaskGuard_V_Volatility();
        if(name == "TASK_E_P_LOCK")        return new CXTaskEntry_P_Lock();
        if(name == "TASK_E_R_ORDER")       return new CXTaskEntry_R_Order();
        if(name == "TASK_E_V_ERROR")       return new CXTaskEntry_V_Error();
        if(name == "TASK_E_V_TICKET")      return new CXTaskEntry_V_Ticket();
        if(name == "TASK_E_V_REAL")        return new CXTaskEntry_V_Real();
        if(name == "TASK_E_V_DOUBLECHECK") return new CXTaskFinalize_V_DoubleCheck();
        if(name == "TASK_E_P_FINALIZE")    return new CXTaskEntry_P_Finalize();
        
        // Pending & Trailing Entry
        if(name == "TASK_P_V_SYNC")        return new CXTaskPending_V_Sync();
        if(name == "TASK_P_V_TERMINAL")    return new CXTaskPending_V_Terminal();
        if(name == "TASK_P_P_ALIGN")       return new CXTaskPending_P_Align();
        if(name == "TASK_P_L_REBOUND")     return new CXTaskPending_L_Rebound();
        if(name == "TASK_P_L_IMPROVE")     return new CXTaskPending_L_Improve();
        if(name == "TASK_P_L_EXTREME")     return new CXTaskPending_L_Extreme();
        if(name == "TASK_P_R_APPLY")       return new CXTaskPending_R_Apply();
        
        // Active & Trailing Stop
        if(name == "TASK_A_INTENT_WATCH")      return new CXTaskIntentWatch();
        if(name == "TASK_A_V_STATUS")          return new CXTaskComm_V_Status();
        if(name == "TASK_A_V_STALE")           return new CXTaskSync_V_Stale();
        if(name == "TASK_A_V_TERMINAL")        return new CXTaskActive_V_Terminal();
        if(name == "TASK_A_P_ALIGN")           return new CXTaskActive_P_Align();
        if(name == "TASK_A_L_STATUS")          return new CXTaskActive_L_Status();
        if(name == "TASK_A_ALPHA_CALC")        return new CXTaskAlphaCalc();
        if(name == "TASK_A_ALPHA_APPLY")       return new CXTaskAlphaApply();
        if(name == "TASK_A_TS_TRIGGER_WATCH")  return new CXTaskActive_TS_TriggerWatch();
        if(name == "TASK_E_P_FINALIZE")        return new CXTaskEntry_P_Finalize(); // Reuse for Step_Closed
        if(name == "TASK_ACTIVE_CLOSED")       return new CXTaskActive_Closed(); // Specific cleanup
        
        // Exit
        if(name == "TASK_X_L_PREPARE")     return new CXTaskExit_L_Prepare();
        if(name == "TASK_X_P_LOCK")        return new CXTaskExit_P_Lock();
        if(name == "TASK_X_R_ORDER")       return new CXTaskExit_R_Order();
        if(name == "TASK_X_V_ERROR")       return new CXTaskExit_V_Error();
        if(name == "TASK_X_V_TERMINAL")    return new CXTaskExit_V_Terminal();
        if(name == "TASK_X_P_FINALIZE")    return new CXTaskExit_P_Finalize();
        
        return NULL;
    }

    /**
     * @brief [v16.6] 호환성 유지를 위한 구형 메서드 스텁
     */
    static bool Exists(string name) {
        IXTask* t = CreateTask(name);
        if(IS_VALID(t)) {
            delete t;
            return true;
        }
        return false;
    }
};

#endif
