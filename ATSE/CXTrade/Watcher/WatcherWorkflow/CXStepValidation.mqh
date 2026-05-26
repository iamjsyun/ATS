#ifndef CXSTEPVALIDATION_MQH
#define CXSTEPVALIDATION_MQH

#include "..\..\Platform\Core\Interfaces\IXStep.mqh"
#include "..\..\Platform\Core\Interfaces\IXGuard.mqh"
#include "..\..\Platform\Core\Macros\CXMacros.mqh"
#include "..\..\Platform\Core\Models\CXSignal.mqh"
#include "..\..\Platform\Core\Defines\CXIdManager.mqh"
#include "..\..\Platform\Shared\Logging\CXAuditFormatter.mqh"
#include "..\..\Platform\Core\Interfaces\ICXInventoryManager.mqh"

/**
 * @class CXStepValidation
 * @brief 발견된 신호의 유효성을 IXGuard를 통해 검증하는 단계 (Watcher 전용)
 */
class CXStepValidation : public IXStep {
public:
    CXStepValidation() {}
    virtual ~CXStepValidation() {}

    virtual string Name() override { return "Step_Validation"; }

    virtual bool OnCondition(ICXParam* xp, ICXContext* ctx, int current_state) override {
        CArrayObj* activeList = CX_GET_OBJ(ctx, "active_signals", CArrayObj);
        return (IS_VALID(activeList) && activeList.Total() > 0);
    }

    virtual int OnProcess(ICXParam* xp, ICXContext* ctx) override {
        CArrayObj* activeList = CX_GET_OBJ(ctx, "active_signals", CArrayObj);
        IXGuard* guard = CX_GET_OBJ(ctx, "guard", IXGuard);
        CXSessionManager* session_mgr = CX_GET_OBJ(ctx, "session_mgr", CXSessionManager);
        
        if(IS_INVALID(activeList)) return WATCHER_DISCOVERY;

        int total = activeList.Total();
        int failed = 0;
        int handled_by_fastpass = 0;

        for(int i = total - 1; i >= 0; i--) {
            ICXSignal* sig = CX_CAST(ICXSignal, activeList.At(i));
            if(IS_INVALID(sig)) {
                activeList.Delete(i);
                continue;
            }

            string sid = sig.GetSid();
            StringTrimLeft(sid); StringTrimRight(sid);
            sig.SetSid(sid);

            xp.SetSignal(sig); 
            string sid_val = sig.GetSid();
            bool isStatusChanged = (sig.GetStatus() != sig.GetLastStatus());
            bool isExitIntent = (sig.GetXAExit() == XA_ACTIVE);

            // [v18.20 Watcher-First Liquidation]
            // 청산 의도가 발견되면 세션 존재 여부와 관계없이 감지기가 즉시 집행 (Master Executioner)
            if(isExitIntent) {
                ulong ticket = (ulong)sig.GetTicket();
                IXExitManager* exitMgr = CX_GET_OBJ(ctx, "exit_mgr", IXExitManager);
                IRepository* repo = CX_GET_OBJ(ctx, "repo", IRepository);
                
                // [v18.15 Terminal Double-Check]
                if(ticket <= 0) {
                    IXTerminalPlatform* terminal = CX_GET_OBJ(ctx, "terminal_platform", IXTerminalPlatform);
                    if(IS_VALID(terminal)) {
                        ticket = terminal.GetTicketBySid(sig.GetMagic(), sig.GetSid());
                        if(ticket > 0) sig.SetTicket(ticket);
                    }
                }
                
                // [v18.18 Direct-Execution] 감지기 단계에서 즉시 청산 집행
                if(IS_VALID(exitMgr) && ticket > 0) {
                    XP_LOG_INFO(xp, CXAuditFormatter::Build("WATCHER-DIRECT-EXIT", xp, StringFormat("Executing Watcher-Priority Liquidation for Ticket:%I64u", ticket)));
                    
                    if(exitMgr.ExecuteExit(xp)) {
                        string successMsg = StringFormat("Direct-Liquidation SUCCESS. Ticket %I64u Removed.", ticket);
                        XP_LOG_OK(xp, CXAuditFormatter::Build("WATCHER-DIRECT-EXIT", xp, successMsg));
                        
                        if(IS_VALID(repo)) {
                            CXMessageProvider::UpdateStatus(sig, XE_CLOSED_SIGNAL, successMsg);
                            repo.UpdateStatus(sig);
                        }
                        
                        activeList.Delete(i);
                        handled_by_fastpass++;
                        continue;
                    }
                }

                // [v18.10 Fast-Pass] 물리 티켓이 아예 없는 경우 (이미 삭제됨) DB만 정리
                if(ticket <= 0) {
                    string skipMsg = "Auto-Closed: No physical asset generated yet. Fast-tracking exit.";
                    XP_LOG_OK(xp, CXAuditFormatter::Build("WATCHER-EXIT-FAST", xp, skipMsg));
                    
                    if(IS_VALID(repo)) {
                        CXMessageProvider::UpdateStatus(sig, XE_CLOSED_SIGNAL, skipMsg);
                        repo.UpdateStatus(sig);
                    }
                    
                    activeList.Delete(i);
                    handled_by_fastpass++;
                    continue;
                }
                
                // 청산 시퀀스가 진행 중인 경우 더 이상의 검증 없이 통과
                continue; 
            }

            // [v18.15 Session Conflict Guard] (Entry 신호 전용)
            // 이미 실행 중인 세션이 있다면 Watcher는 신규 세션을 스폰하지 않음
            if(IS_VALID(session_mgr) && IS_VALID(session_mgr.FindSessionByIdentity(sig))) {
                activeList.Delete(i);
                continue;
            }

            // [v18.12 Exit-Identity Standard]
            // 진입 신호 식별자 검증
            bool hasValidIdentity = CXIdManager::ValidateSID(sid) || (sig.GetCno() > 0 && sig.GetSno() > 0);

            //--- [Entry Specific Validation] ---
            // ATSA UI 및 수동 입력 데이터 보정
            if(sig.GetType() != ORDER_MARKET) {
                if(sig.GetTEStart() >= 1 && 0 >= sig.GetTELimit()) sig.SetTELimit(sig.GetTEStart());
                if(sig.GetTELimit() >= 1 && 0 >= sig.GetTEStart()) sig.SetTEStart(sig.GetTELimit());
            }

            if(IS_VALID(guard)) {
                bool isValidDir = (sig.GetDir() == CX_DIR_BUY || sig.GetDir() == CX_DIR_SELL);
                string guardReason = "";
                
                if(!isValidDir) guardReason = "Invalid Direction (dir=0)";
                else if(!guard.ValidateMagic(sig.GetMagic())) guardReason = guard.GetLastError();
                else if(!guard.ValidateSID(sig.GetSid())) guardReason = guard.GetLastError();
                else if(!guard.ValidateLot(sig.GetSymbol(), sig.GetLot())) guardReason = guard.GetLastError();

                if(guardReason != "") {
                    string err = StringFormat("[WATCHER-REJECT] %s", guardReason);
                    if(isStatusChanged) XP_LOG_ERROR(xp, CXAuditFormatter::Build("WATCHER-REJECT", xp, guardReason));
                    
                    IRepository* repo = CX_GET_OBJ(ctx, "repo", IRepository);
                    CXMessageProvider::UpdateStatus(sig, XE_ERROR, err);
                    if(IS_VALID(repo)) repo.UpdateStatus(sig);
                    
                    activeList.Delete(i);
                    failed++;
                } else {
                    if(isStatusChanged) XP_LOG_TRACE(xp, CXAuditFormatter::Build("WATCHER-VALIDATION", xp, "PASSED"));
                    sig.SetLastStatus(sig.GetStatus());
                }
            }
        }
        
        int remaining = activeList.Total();
        
        // [v18.12 Flow Control Fix]
        // 모든 신호가 Fast-Pass 또는 Reject되어 남은 것이 없다면 Discovery로 돌아가되, 
        // Fast-Pass에 의한 정리는 실패(Warning)로 간주하지 않음.
        if(remaining > 0) {
            XP_LOG_TRACE(xp, StringFormat("[WATCHER-VALIDATION] Complete. To Spawn:%d, Failed:%d, FastPass:%d", remaining, failed, handled_by_fastpass));
            return WATCHER_SPAWNING;
        }

        if(failed > 0) {
             XP_LOG_WARN(xp, StringFormat("[WATCHER-VALIDATION] Handled %d signals. (Failed:%d, FastPass:%d). Back to Discovery.", total, failed, handled_by_fastpass));
        }
        
        return WATCHER_DISCOVERY;
    }

    virtual void OnEnter(ICXContext* ctx) override {}
    virtual void OnExit(ICXContext* ctx) override {
        // [v10.7 Fix] Cleanup context reference if needed
    }
};

#endif
