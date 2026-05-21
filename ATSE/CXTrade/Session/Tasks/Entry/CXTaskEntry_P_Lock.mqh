#ifndef CX_TASK_ENTRY_P_LOCK_MQH
#define CX_TASK_ENTRY_P_LOCK_MQH

#include "..\..\..\Interfaces\IXTask.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"
#include "..\..\..\Interfaces\IRepository.mqh"
#include "..\..\..\Infra\CXMessageProvider.mqh"

/**
 * @class CXTaskEntry_P_Lock
 * @brief [Persistence] DB에 PENDING_REQ 상태 기록 (잠금)
 */
class CXTaskEntry_P_Lock : public IXTask {
public:
    virtual string Name() override { return "Entry_P_Lock"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        IRepository* repo = CX_GET_OBJ(ctx, "repo", IRepository);
        if(IS_INVALID(sig) || IS_INVALID(repo)) return TASK_BREAK;

        if(sig.GetStatus() >= XE_PENDING_REQ) {
            XP_LOG_DEBUG(xp, StringFormat("[ENTRY-P] SKIP: Already Locked (Status:%d)", sig.GetStatus()));
            return TASK_CONTINUE;
        }

        XP_LOG_TRACE(xp, "[ENTRY-P] Attempting to Write PENDING_REQ Lock to DB...");
        CXMessageProvider::UpdateStatus(sig, XE_PENDING_REQ, "Intent: Entry Requesting...");
        
        if(repo.UpdateStatus(sig)) {
            XP_LOG_OK(xp, "[ENTRY-P] SUCCESS: Status Locked to XE_PENDING_REQ.");
            return TASK_CONTINUE;
        }

        XP_LOG_ERROR(xp, "[ENTRY-P] FAILED: DB Update for PENDING_REQ Lock.");
        return TASK_BREAK; 
    }
};

#endif
