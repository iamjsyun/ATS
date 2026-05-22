#ifndef CX_TASK_PENDING_P_ALIGN_MQH
#define CX_TASK_PENDING_P_ALIGN_MQH

#include "..\..\..\Interfaces\IXTask.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"
#include "..\..\..\Interfaces\IRepository.mqh"
#include "..\..\..\Interfaces\IXOrderManager.mqh"

/**
 * @class CXTaskPending_P_Align
 * @brief [Persistence] 대기 주문 터미널 상태와 DB 상태 동기화 (수동 삭제 시 정합성 확보)
 */
class CXTaskPending_P_Align : public IXTask {
public:
    virtual string Name() override { return "Pending_P_Align"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        IRepository* repo = CX_GET_OBJ(ctx, "repo", IRepository);
        if(IS_INVALID(sig) || IS_INVALID(repo)) return TASK_BREAK;

        bool exists = (xp.GetInt() == 1);
        
        // 실물이 없는데 DB는 대기(5) 상태인 경우 (수동 삭제 상황)
        if(!exists && sig.GetStatus() == XE_PENDING_PLACED) {
            XP_LOG_WARN(xp, StringFormat("[PENDING-P-ALIGN] Mismatch: Order:%I64u not found. Triggering Pulse...", sig.GetTicket()));
            
            IXOrderManager* ordMgr = CX_GET_OBJ(ctx, "order_mgr", IXOrderManager);
            if(IS_VALID(ordMgr)) {
                ordMgr.Pulse(xp);
            }
        }

        return TASK_CONTINUE;
    }
};

#endif
