#ifndef CXSTEPVALIDATION_MQH
#define CXSTEPVALIDATION_MQH

#include "..\..\..\Core\Interfaces\IXStep.mqh"
#include "..\..\..\Core\Interfaces\IXGuard.mqh"
#include "..\..\..\Core\Macros\CXMacros.mqh"
#include "..\..\..\Core\Models\CXSignal.mqh"
#include "..\..\..\Core\Defines\CXIdManager.mqh"
#include "..\..\..\Shared\Logging\CXAuditFormatter.mqh"

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
        
        if(IS_INVALID(activeList)) return WATCHER_DISCOVERY;

        int total = activeList.Total();
        int failed = 0;

        for(int i = total - 1; i >= 0; i--) {
            ICXSignal* sig = CX_CAST(ICXSignal, activeList.At(i));
            if(IS_INVALID(sig)) {
                activeList.Delete(i);
                continue;
            }

            xp.SetSignal(sig); // 0값 출력 및 UAF 조립을 위해 임시 바인딩
            string sid = sig.GetSid();
            bool isStatusChanged = (sig.GetStatus() != sig.GetLastStatus());

            // [v14.5 SID Structure Validation] 필수 검증
            if(!CXIdManager::ValidateSID(sid)) {
                string sidErr = StringFormat("Invalid SID Format: %s", sid);
                if(isStatusChanged) XP_LOG_ERROR(xp, CXAuditFormatter::Build("WATCHER-REJECT", xp, sidErr));
                
                IRepository* repo = CX_GET_OBJ(ctx, "repo", IRepository);
                CXMessageProvider::UpdateStatus(sig, XE_ERROR, sidErr);
                if(IS_VALID(repo)) repo.UpdateStatus(sig);
                
                activeList.Delete(i);
                failed++;
                continue;
            }

            // [v14.5 Parameter Recovery from SID]
            if(sig.GetDir() == CX_DIR_NONE) {
                int recoveredDir = CXIdManager::ExtractDir(sid);
                if(recoveredDir > 0) {
                    sig.SetDir(recoveredDir);
                    XP_LOG_TRACE(xp, CXAuditFormatter::Build("WATCHER-RECOVERY", xp, StringFormat("Recovered Dir:%d", recoveredDir)));
                }
            }
            if(sig.GetType() == 0) {
                int recoveredType = CXIdManager::ExtractType(sid);
                if(recoveredType > 0) {
                    sig.SetType(recoveredType);
                    XP_LOG_TRACE(xp, CXAuditFormatter::Build("WATCHER-RECOVERY", xp, StringFormat("Recovered Type:%d", recoveredType)));
                }
            }

            // [v14.0 Exit-Priority Bypass] 청산 의도가 있는 경우 SID만 검증하고 즉시 통과
            if(sig.GetXAExit() == XA_ACTIVE) {
                if(IS_VALID(guard) && !guard.ValidateSID(sig.GetSid())) {
                    if(isStatusChanged) XP_LOG_ERROR(xp, CXAuditFormatter::Build("WATCHER-REJECT", xp, "EXIT REJECTED: Invalid SID"));
                    activeList.Delete(i);
                    failed++;
                    continue;
                }
                if(isStatusChanged) XP_LOG_TRACE(xp, CXAuditFormatter::Build("WATCHER-VALID-EXIT", xp, "EXIT-PRIORITY PASS"));
                sig.SetLastStatus(sig.GetStatus());
                continue; 
            }

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
        
        int passed = activeList.Total();
        if(passed > 0) {
            XP_LOG_TRACE(xp, StringFormat("[WATCHER-VALIDATION] Complete. Passed:%d, Failed:%d", passed, failed));
            return WATCHER_SPAWNING;
        }

        XP_LOG_WARN(xp, StringFormat("[WATCHER-VALIDATION] All %d signals failed validation.", total));
        return WATCHER_DISCOVERY;
    }

    virtual void OnEnter(ICXContext* ctx) override {}
    virtual void OnExit(ICXContext* ctx) override {
        // [v10.7 Fix] Cleanup context reference if needed
    }
};

#endif
