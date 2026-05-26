#ifndef CXSTEPEXITEXECUTE_MQH
#define CXSTEPEXITEXECUTE_MQH

#include "..\..\Platform\Core\Interfaces\IXStep.mqh"
#include "..\..\Platform\Core\Interfaces\IXExitManager.mqh"
#include "..\..\Platform\Core\Interfaces\ICXSessionManager.mqh"
#include "..\..\Platform\Core\Interfaces\ICXTradingSession.mqh"
#include "..\..\Platform\Core\Interfaces\IRepository.mqh"
#include "..\..\Platform\Core\Models\CXSignal.mqh"
#include "..\..\Platform\Core\Macros\CXMacros.mqh"
#include "..\..\Platform\Core\Sequence\CXSequenceOrchestrator.mqh"
#include "..\..\Platform\Shared\Logging\CXAuditFormatter.mqh"
#include "..\..\Platform\Shared\Logging\CXMessageProvider.mqh"

#include <Arrays\ArrayObj.mqh>

/**
 * @class CXStepExitExecute
 * @brief 청산 신호 발견 시 세션 제어 전환 또는 직접 물리/DB 청산을 집행하는 단계
 */
class CXStepExitExecute : public IXStep {
public:
    CXStepExitExecute() {}
    virtual ~CXStepExitExecute() {}

    virtual string Name() override { return "Step_ExitExecute"; }

    virtual bool OnCondition(ICXParam* xp, ICXContext* ctx, int current_state) override {
        CArrayObj* activeList = CX_GET_OBJ(ctx, "exit_signals", CArrayObj);
        return (IS_VALID(activeList) && activeList.Total() > 0);
    }

    virtual int OnProcess(ICXParam* xp, ICXContext* ctx) override {
        CArrayObj* activeList = CX_GET_OBJ(ctx, "exit_signals", CArrayObj);
        IXExitManager* exitMgr = CX_GET_OBJ(ctx, "exit_mgr", IXExitManager);
        IRepository* repo = CX_GET_OBJ(ctx, "repo", IRepository);
        ICXSessionManager* session_mgr = CX_GET_OBJ(ctx, "session_mgr", ICXSessionManager);

        if(IS_INVALID(activeList) || IS_INVALID(exitMgr) || IS_INVALID(repo)) {
            CXSequenceOrchestrator* orchestrator = CX_GET_OBJ(ctx, "orchestrator", CXSequenceOrchestrator);
            return IS_VALID(orchestrator) ? orchestrator.ResolveId("WATCHER_EXIT_DISCOVERY") : STATE_UNCHANGED;
        }

        int total = activeList.Total();
        int handled = 0;

        for(int i = total - 1; i >= 0; i--) {
            ICXSignal* sig = CX_CAST(ICXSignal, activeList.At(i));
            if(IS_INVALID(sig)) continue;

            xp.SetSignal(sig);
            string sid = sig.GetSid();
            ulong ticket = sig.GetTicket();

            // 1. 이미 구동 중인 세션이 있는지 탐색
            ICXTradingSession* existing = (IS_VALID(session_mgr)) ? session_mgr.FindSessionBySid(sid) : NULL;
            if(IS_VALID(existing)) {
                // 세션이 있는 경우 청산 단계(SESSION_LIQUIDATING)로 강제 전이시켜 세션 내에서 청산 수행 유도
                XP_LOG_WARN(xp, CXAuditFormatter::Build("WATCHER-EXIT", xp, StringFormat("INTERRUPT: Active session found for SID:%s. Forcing SESSION_LIQUIDATING.", sid)));
                existing.ForceTransition(SESSION_LIQUIDATING);
                
                // DB도 청산 진입 상태로 업데이트
                sig.SetStatus(XE_IN_TRANSIT);
                sig.SetStatusMsg("Exit Intent Synchronized: Forcing session transition.");
                repo.UpdateStatus(sig);
                
                activeList.Delete(i);
                handled++;
                SAFE_DELETE(sig);
                continue;
            }

            // 2. 구동 중인 세션이 없는 경우: 워처가 직접 즉각 물리 자산 청산 (Fast-Path / Bypass)
            
            // 2.1 터미널 더블 체크를 통해 누락 티켓 획득 시도
            if(ticket <= 0) {
                IXTerminalPlatform* terminal = CX_GET_OBJ(ctx, "terminal_platform", IXTerminalPlatform);
                if(IS_VALID(terminal)) {
                    ticket = terminal.GetTicketBySid(sig.GetMagic(), sig.GetSid());
                    if(ticket > 0) sig.SetTicket(ticket);
                }
            }

            // 2.2 물리 티켓이 실존하는 경우 청산 실행
            if(ticket > 0) {
                XP_LOG_INFO(xp, CXAuditFormatter::Build("WATCHER-DIRECT-EXIT", xp, StringFormat("Executing Watcher Direct Liquidation for Ticket:%I64u", ticket)));
                
                if(exitMgr.ExecuteExit(xp)) {
                    string successMsg = StringFormat("Direct-Liquidation SUCCESS. Ticket %I64u Cleared.", ticket);
                    XP_LOG_OK(xp, CXAuditFormatter::Build("WATCHER-DIRECT-EXIT", xp, successMsg));
                    
                    CXMessageProvider::UpdateStatus(sig, XE_CLOSED_SIGNAL, successMsg);
                    repo.UpdateStatus(sig);
                    
                    activeList.Delete(i);
                    handled++;
                } else {
                    XP_LOG_ERROR(xp, CXAuditFormatter::Build("WATCHER-DIRECT-EXIT", xp, StringFormat("FAILED to close Ticket %I64u", ticket)));
                }
            }
            // 2.3 이미 물리 티켓이 아예 없거나 종료된 자산인 경우: DB만 최종 정리 (Fast-Pass)
            else {
                string skipMsg = "Auto-Closed: No physical asset exists in terminal. DB finalized.";
                XP_LOG_OK(xp, CXAuditFormatter::Build("WATCHER-EXIT-FAST", xp, skipMsg));
                
                CXMessageProvider::UpdateStatus(sig, XE_CLOSED_SIGNAL, skipMsg);
                repo.UpdateStatus(sig);
                
                activeList.Delete(i);
                handled++;
            }

            SAFE_DELETE(sig);
        }

        while(activeList.Total() > 0) activeList.Detach(0);
        SAFE_DELETE(activeList);

        CXSequenceOrchestrator* orchestrator = CX_GET_OBJ(ctx, "orchestrator", CXSequenceOrchestrator);
        return IS_VALID(orchestrator) ? orchestrator.ResolveId("WATCHER_EXIT_DISCOVERY") : STATE_UNCHANGED;
    }

    virtual void OnEnter(ICXContext* ctx) override {}
    virtual void OnExit(ICXContext* ctx) override {}
};

#endif
