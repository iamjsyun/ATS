#ifndef CXTASKFACTORY_MQH
#define CXTASKFACTORY_MQH

#include "..\Interfaces\IXTask.mqh"
#include "..\Interfaces\CXDefine.mqh"

// Entry Tasks
#include "..\Session\Tasks\Entry\CXTaskEntry_L_Redirect.mqh"
#include "..\Session\Tasks\Entry\CXTaskEntry_L_Identity.mqh"
#include "..\Session\Tasks\Entry\CXTaskEntry_L_Risk.mqh"
#include "..\Session\Tasks\Entry\CXTaskEntry_L_Price.mqh"
#include "..\Session\Tasks\Entry\CXTaskEntry_P_Intent.mqh"
#include "..\Session\Tasks\Entry\CXTaskEntry_L_Validate.mqh"
#include "..\Session\Tasks\Entry\CXTaskGuard_V_Spread.mqh"
#include "..\Session\Tasks\Entry\CXTaskGuard_V_Volatility.mqh"
#include "..\Session\Tasks\Entry\CXTaskEntry_P_Lock.mqh"
#include "..\Session\Tasks\Entry\CXTaskEntry_R_Order.mqh"
#include "..\Session\Tasks\Entry\CXTaskEntry_V_Error.mqh"
#include "..\Session\Tasks\Entry\CXTaskEntry_V_Ticket.mqh"
#include "..\Session\Tasks\Entry\CXTaskEntry_V_Real.mqh"
#include "..\Session\Tasks\Entry\CXTaskFinalize_V_DoubleCheck.mqh"
#include "..\Session\Tasks\Entry\CXTaskEntry_P_Finalize.mqh"

// Pending Tasks
#include "..\Session\Tasks\Pending\CXTaskPending_V_Sync.mqh"
#include "..\Session\Tasks\Pending\CXTaskPending_L_Rebound.mqh"
#include "..\Session\Tasks\Pending\CXTaskPending_L_Improve.mqh"
#include "..\Session\Tasks\Pending\CXTaskPending_R_Apply.mqh"

// Active Tasks
#include "..\Session\Tasks\Active\CXTaskIntentWatch.mqh"
#include "..\Session\Tasks\Active\CXTaskComm_V_Status.mqh"
#include "..\Session\Tasks\Active\CXTaskSync_V_Stale.mqh"
#include "..\Session\Tasks\Active\CXTaskActive_V_Terminal.mqh"
#include "..\Session\Tasks\Active\CXTaskActive_P_Align.mqh"
#include "..\Session\Tasks\Active\CXTaskActive_L_Status.mqh"
#include "..\Session\Tasks\Active\CXTaskAlphaCalc.mqh"
#include "..\Session\Tasks\Active\CXTaskAlphaApply.mqh"

// Exit Tasks
#include "..\Session\Tasks\Exit\CXTaskExit_L_Prepare.mqh"
#include "..\Session\Tasks\Exit\CXTaskExit_P_Lock.mqh"
#include "..\Session\Tasks\Exit\CXTaskExit_R_Order.mqh"
#include "..\Session\Tasks\Exit\CXTaskExit_V_Error.mqh"
#include "..\Session\Tasks\Exit\CXTaskExit_V_Terminal.mqh"
#include "..\Session\Tasks\Exit\CXTaskExit_P_Finalize.mqh"

/**
 * @class CXTaskFactory
 * @brief Enum 기반으로 IXTask 객체 생성을 담당
 */
class CXTaskFactory {
public:
    /**
     * @brief [v11.4] 문자열 이름을 기반으로 ENUM_TASK_TYPE 반환
     */
    static ENUM_TASK_TYPE GetTaskTypeByName(string name) {
        if(name == "TASK_E_L_REDIRECT")    return TASK_E_L_REDIRECT;
        if(name == "TASK_E_L_IDENTITY")    return TASK_E_L_IDENTITY;
        if(name == "TASK_E_L_RISK")        return TASK_E_L_RISK;
        if(name == "TASK_E_L_PRICE")       return TASK_E_L_PRICE;
        if(name == "TASK_E_P_INTENT")      return TASK_E_P_INTENT;
        if(name == "TASK_E_L_VALIDATE")    return TASK_E_L_VALIDATE;
        if(name == "TASK_E_G_SPREAD")      return TASK_E_G_SPREAD;
        if(name == "TASK_E_G_VOLATILITY")  return TASK_E_G_VOLATILITY;
        if(name == "TASK_E_P_LOCK")        return TASK_E_P_LOCK;
        if(name == "TASK_E_R_ORDER")       return TASK_E_R_ORDER;
        if(name == "TASK_E_V_ERROR")       return TASK_E_V_ERROR;
        if(name == "TASK_E_V_TICKET")      return TASK_E_V_TICKET;
        if(name == "TASK_E_V_REAL")        return TASK_E_V_REAL;
        if(name == "TASK_E_V_DOUBLECHECK") return TASK_E_V_DOUBLECHECK;
        if(name == "TASK_E_P_FINALIZE")    return TASK_E_P_FINALIZE;
        
        if(name == "TASK_P_V_SYNC")        return TASK_P_V_SYNC;
        if(name == "TASK_P_L_REBOUND")     return TASK_P_L_REBOUND;
        if(name == "TASK_P_L_IMPROVE")     return TASK_P_L_IMPROVE;
        if(name == "TASK_P_R_APPLY")       return TASK_P_R_APPLY;
        
        if(name == "TASK_A_INTENT_WATCH")  return TASK_A_INTENT_WATCH;
        if(name == "TASK_A_V_STATUS")      return TASK_A_V_STATUS;
        if(name == "TASK_A_V_STALE")       return TASK_A_V_STALE;
        if(name == "TASK_A_V_TERMINAL")    return TASK_A_V_TERMINAL;
        if(name == "TASK_A_P_ALIGN")       return TASK_A_P_ALIGN;
        if(name == "TASK_A_L_STATUS")      return TASK_A_L_STATUS;
        if(name == "TASK_A_ALPHA_CALC")    return TASK_A_ALPHA_CALC;
        if(name == "TASK_A_ALPHA_APPLY")   return TASK_A_ALPHA_APPLY;
        
        if(name == "TASK_X_L_PREPARE")     return TASK_X_L_PREPARE;
        if(name == "TASK_X_P_LOCK")        return TASK_X_P_LOCK;
        if(name == "TASK_X_R_ORDER")       return TASK_X_R_ORDER;
        if(name == "TASK_X_V_ERROR")       return TASK_X_V_ERROR;
        if(name == "TASK_X_V_TERMINAL")    return TASK_X_V_TERMINAL;
        if(name == "TASK_X_P_FINALIZE")    return TASK_X_P_FINALIZE;
        
        return TASK_NONE;
    }

    static IXTask* CreateTask(ENUM_TASK_TYPE type) {
        switch(type) {
            // Entry
            case TASK_E_L_REDIRECT:    return new CXTaskEntry_L_Redirect();
            case TASK_E_L_IDENTITY:    return new CXTaskEntry_L_Identity();
            case TASK_E_L_RISK:        return new CXTaskEntry_L_Risk();
            case TASK_E_L_PRICE:       return new CXTaskEntry_L_Price();
            case TASK_E_P_INTENT:      return new CXTaskEntry_P_Intent();
            case TASK_E_L_VALIDATE:    return new CXTaskEntry_L_Validate();
            case TASK_E_G_SPREAD:      return new CXTaskGuard_V_Spread();
            case TASK_E_G_VOLATILITY:  return new CXTaskGuard_V_Volatility();
            case TASK_E_P_LOCK:        return new CXTaskEntry_P_Lock();
            case TASK_E_R_ORDER:       return new CXTaskEntry_R_Order();
            case TASK_E_V_ERROR:       return new CXTaskEntry_V_Error();
            case TASK_E_V_TICKET:      return new CXTaskEntry_V_Ticket();
            case TASK_E_V_REAL:        return new CXTaskEntry_V_Real();
            case TASK_E_V_DOUBLECHECK: return new CXTaskFinalize_V_DoubleCheck();
            case TASK_E_P_FINALIZE:    return new CXTaskEntry_P_Finalize();
            
            // Pending
            case TASK_P_V_SYNC:        return new CXTaskPending_V_Sync();
            case TASK_P_L_REBOUND:     return new CXTaskPending_L_Rebound();
            case TASK_P_L_IMPROVE:     return new CXTaskPending_L_Improve();
            case TASK_P_R_APPLY:       return new CXTaskPending_R_Apply();
            
            // Active
            case TASK_A_INTENT_WATCH:  return new CXTaskIntentWatch();
            case TASK_A_V_STATUS:      return new CXTaskComm_V_Status();
            case TASK_A_V_STALE:       return new CXTaskSync_V_Stale();
            case TASK_A_V_TERMINAL:    return new CXTaskActive_V_Terminal();
            case TASK_A_P_ALIGN:       return new CXTaskActive_P_Align();
            case TASK_A_L_STATUS:      return new CXTaskActive_L_Status();
            case TASK_A_ALPHA_CALC:    return new CXTaskAlphaCalc();
            case TASK_A_ALPHA_APPLY:   return new CXTaskAlphaApply();
            
            // Exit
            case TASK_X_L_PREPARE:     return new CXTaskExit_L_Prepare();
            case TASK_X_P_LOCK:        return new CXTaskExit_P_Lock();
            case TASK_X_R_ORDER:       return new CXTaskExit_R_Order();
            case TASK_X_V_ERROR:       return new CXTaskExit_V_Error();
            case TASK_X_V_TERMINAL:    return new CXTaskExit_V_Terminal();
            case TASK_X_P_FINALIZE:    return new CXTaskExit_P_Finalize();
            
            default:                   return NULL;
        }
    }
};

#endif
