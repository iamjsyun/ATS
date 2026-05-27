#ifndef CXSTAGEENTRYEXECUTE_MQH
#define CXSTAGEENTRYEXECUTE_MQH

#include "..\..\Platform\Core\Interfaces\IXStage.mqh"
#include "..\..\Platform\Core\Interfaces\IXGuard.mqh"
#include "..\..\Platform\Core\Interfaces\ICXServiceFactory.mqh"
#include "..\..\Platform\Core\Interfaces\IXOrderManager.mqh"
#include "..\..\Platform\Core\Interfaces\IRepository.mqh"
#include "..\..\Platform\Core\Models\CXSignal.mqh"
#include "..\..\Platform\Core\Macros\CXMacros.mqh"
#include "..\..\Platform\Core\Sequence\CXSequenceOrchestrator.mqh"
#include "..\..\Platform\Shared\Logging\CXAuditFormatter.mqh"
#include "..\..\Platform\Shared\Logging\CXMessageProvider.mqh"

#include <Arrays\ArrayObj.mqh>

/**
 * @class CXStageEntryExecute
 * @brief [v18.10] 신규 진입 신호 검증 및 최초 대기 오더 접수를 집행하는 단계 (WATCHER_ENTRY_EXECUTE)
 */
class CXStageEntryExecute : public IXStage {
public:
    CXStageEntryExecute() {}
    virtual ~CXStageEntryExecute() {}

    virtual string Name() override { return "Stage_EntryExecute"; }

    virtual bool OnCondition(ICXParam* xp, ICXContext* ctx, int current_state) override {
        CArrayObj* activeList = CX_GET_OBJ(ctx, "entry_signals", CArrayObj);
        return (IS_VALID(activeList) && activeList.Total() > 0);
    }

    virtual int OnProcess(ICXParam* xp, ICXContext* ctx) override {
        CArrayObj* activeList = CX_GET_OBJ(ctx, "entry_signals", CArrayObj);
        IXGuard* guard = CX_GET_OBJ(ctx, "guard", IXGuard);
        IRepository* repo = CX_GET_OBJ(ctx, "repo", IRepository);
        ICXServiceFactory* factory = CX_GET_OBJ(ctx, "factory", ICXServiceFactory);

        if(IS_INVALID(activeList) || IS_INVALID(factory) || IS_INVALID(repo)) {
            CXSequenceOrchestrator* orchestrator = CX_GET_OBJ(ctx, "orchestrator", CXSequenceOrchestrator);
            return IS_VALID(orchestrator) ? orchestrator.ResolveId("WATCHER_EXIT_DISCOVERY") : STATE_UNCHANGED;
        }

        int total = activeList.Total();
        int success = 0;
        int failed = 0;

        IXOrderManager* orderMgr = factory.CreateOrderManager(ctx);
        if(IS_INVALID(orderMgr)) {
            XP_LOG_ERROR(xp, "[WATCHER-ENTRY-EXECUTE] FAILED: OrderManager creation failed.");
            SAFE_DELETE(activeList);
            CXSequenceOrchestrator* orchestrator = CX_GET_OBJ(ctx, "orchestrator", CXSequenceOrchestrator);
            return IS_VALID(orchestrator) ? orchestrator.ResolveId("WATCHER_EXIT_DISCOVERY") : STATE_UNCHANGED;
        }

        for(int i = 0; i < total; i++) {
            ICXSignal* sig = CX_CAST(ICXSignal, activeList.At(i));
            if(IS_INVALID(sig)) continue;

            xp.SetSignal(sig);
            string sid = sig.GetSid();
            bool isStatusChanged = (sig.GetStatus() != sig.GetLastStatus());

            // 1. 진입 가드 검증 (스프레드, 로트, 매직 등)
            string guardReason = "";
            if(IS_VALID(guard)) {
                bool isValidDir = (sig.GetDir() == CX_DIR_BUY || sig.GetDir() == CX_DIR_SELL);
                if(!isValidDir) guardReason = "Invalid Direction (dir=0)";
                else if(!guard.ValidateMagic(sig.GetMagic())) guardReason = guard.GetLastError();
                else if(!guard.ValidateSID(sig.GetSid())) guardReason = guard.GetLastError();
                else if(!guard.ValidateLot(sig.GetSymbol(), sig.GetLot())) guardReason = guard.GetLastError();
            }

            if(guardReason != "") {
                string err = StringFormat("[WATCHER-ENTRY-REJECT] %s", guardReason);
                XP_LOG_ERROR(xp, CXAuditFormatter::Build("WATCHER-ENTRY-REJECT", xp, guardReason));
                
                CXMessageProvider::UpdateStatus(sig, XE_ERROR, err);
                repo.UpdateStatus(sig);
                failed++;
                SAFE_DELETE(sig);
                continue;
            }

            // 2. 최초 대기 오더 접수 진행
            sig.SetStatus(XE_READY);
            sig.SetStatusMsg("Initial Execute Placement");
            repo.UpdateStatus(sig);

            XP_LOG_INFO(xp, StringFormat("[WATCHER-ENTRY-EXECUTE] Plunging Initial Order for SID:%s", sid));

            if(orderMgr.ExecuteEntry(xp)) {
                ulong ticket = sig.GetTicket();
                if(ticket > 0) {
                    // 성공 시 티켓 정보와 함께 상태를 XE_PENDING_PLACED (대기주문 등록완료) 또는 XE_EXECUTED (시장가)로 마킹 후 시퀀스 종결
                    int finalStatus = (sig.GetType() == ORDER_MARKET) ? XE_EXECUTED : XE_PENDING_PLACED;
                    sig.SetStatus(finalStatus);
                    sig.SetStatusMsg(StringFormat("Initial Placement SUCCESS. Ticket:%I64u", ticket));
                    repo.UpdateStatus(sig);
                    
                    XP_LOG_OK(xp, CXAuditFormatter::Build("WATCHER-ENTRY-EXECUTE", xp, StringFormat("SUCCESS: Ticket %I64u Placed.", ticket)));
                    success++;
                } else {
                    XP_LOG_ERROR(xp, CXAuditFormatter::Build("WATCHER-ENTRY-EXECUTE", xp, "FAILED: Ticket not generated."));
                    failed++;
                }
            } else {
                XP_LOG_ERROR(xp, CXAuditFormatter::Build("WATCHER-ENTRY-EXECUTE", xp, "FAILED: ExecuteEntry failed."));
                failed++;
            }
            
            SAFE_DELETE(sig);
        }

        SAFE_DELETE(orderMgr);
        while(activeList.Total() > 0) activeList.Detach(0);
        SAFE_DELETE(activeList);

        CXSequenceOrchestrator* orchestrator = CX_GET_OBJ(ctx, "orchestrator", CXSequenceOrchestrator);
        return IS_VALID(orchestrator) ? orchestrator.ResolveId("WATCHER_EXIT_DISCOVERY") : STATE_UNCHANGED;
    }

    virtual void OnEnter(ICXContext* ctx) override {}
    virtual void OnExit(ICXContext* ctx) override {}
};

#endif
