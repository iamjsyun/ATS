#ifndef CXSTEPVALIDATION_MQH
#define CXSTEPVALIDATION_MQH

#include "..\..\..\Interfaces\IXStep.mqh"
#include "..\..\..\Interfaces\IXGuard.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"
#include "..\..\..\Models\CXSignal.mqh"
#include "..\..\..\Infra\CXIdManager.mqh"

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
        ICXLogger* log = CX_GET_OBJ(ctx, "logger", ICXLogger);
        
        if(IS_INVALID(activeList)) return WATCHER_DISCOVERY;

        int total = activeList.Total();
        int failed = 0;

        for(int i = total - 1; i >= 0; i--) {
            ICXSignal* sig = CX_CAST(ICXSignal, activeList.At(i));
            if(IS_INVALID(sig)) {
                activeList.Delete(i);
                continue;
            }

            string sid = sig.GetSid();
            bool isStatusChanged = (sig.GetStatus() != sig.GetLastStatus());

            // [v14.5 SID Structure Validation] 필수 검증
            if(!CXIdManager::ValidateSID(sid)) {
                string sidErr = StringFormat("[WATCHER-REJECT] Invalid SID Format: %s", sid);
                if(isStatusChanged && IS_VALID(log)) log.Error(xp, sidErr);
                
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
                    XP_LOG_TRACE(xp, StringFormat("[WATCHER-RECOVERY] Recovered Dir:%d from SID:%s", recoveredDir, sid));
                }
            }
            if(sig.GetType() == 0) {
                int recoveredType = CXIdManager::ExtractType(sid);
                if(recoveredType > 0) {
                    sig.SetType(recoveredType);
                    XP_LOG_TRACE(xp, StringFormat("[WATCHER-RECOVERY] Recovered Type:%d from SID:%s", recoveredType, sid));
                }
            }

            // [v11.4] Distinguish Entry and Exit intents in logs
            string mode = "UNKNOWN";
            if(sig.GetXAEntry() == XA_ACTIVE) mode = "ENTRY";
            else if(sig.GetXAExit() == XA_ACTIVE) mode = "EXIT";

            // [v11.0 Rule 1 & 3] 상세 로그 생성 및 중복 방지
            string sigInfo = StringFormat("[%s] SID:%s, Sym:%s, P:%.5f, L:%.2f, Typ:%d, TE:%d, TS:%d, SL:%d, TP:%d, EN:%d, EX:%d, ST:%d",
                mode, sig.GetSid(), sig.GetSymbol(), sig.GetPriceSignal(), sig.GetLot(), sig.GetType(), 
                (int)sig.GetTEStart(), (int)sig.GetTSStart(), (int)sig.GetSL(), (int)sig.GetTP(),
                sig.GetXAEntry(), sig.GetXAExit(), sig.GetStatus());

            // [v14.0 Exit-Priority Bypass] 청산 의도가 있는 경우 SID만 검증하고 즉시 통과
            if(sig.GetXAExit() == XA_ACTIVE) {
                if(IS_VALID(guard) && !guard.ValidateSID(sig.GetSid())) {
                    if(isStatusChanged && IS_VALID(log)) log.Error(xp, StringFormat("[WATCHER-VALIDATION] EXIT REJECTED: Invalid SID:%s", sig.GetSid()));
                    activeList.Delete(i);
                    failed++;
                    continue;
                }
                if(isStatusChanged && IS_VALID(log)) log.Trace(xp, StringFormat("[WATCHER-VALIDATION] EXIT-PRIORITY PASS: SID:%s", sig.GetSid()));
                sig.SetLastStatus(sig.GetStatus());
                continue; 
            }

            // [v14.0 Data Normalization] ATSA UI 및 수동 입력 데이터 보정
            if(sig.GetType() != ORDER_MARKET) {
                if(sig.GetTEStart() > 0 && sig.GetTELimit() <= 0) sig.SetTELimit(sig.GetTEStart());
                if(sig.GetTELimit() > 0 && sig.GetTEStart() <= 0) sig.SetTEStart(sig.GetTELimit());
            }

            if(IS_VALID(guard)) {
                // [v14.4 Validation Guard] 방향 데이터 최종 체크
                bool isValidDir = (sig.GetDir() == CX_DIR_BUY || sig.GetDir() == CX_DIR_SELL);
                string guardReason = "";
                
                if(!isValidDir) guardReason = "Invalid Direction (dir=0)";
                else if(!guard.ValidateMagic(sig.GetMagic())) guardReason = guard.GetLastError();
                else if(!guard.ValidateSID(sig.GetSid())) guardReason = guard.GetLastError();
                else if(!guard.ValidateLot(sig.GetSymbol(), sig.GetLot())) guardReason = guard.GetLastError();
                else if(!guard.ValidatePrice(sig.GetSymbol(), sig.GetPriceSignal())) guardReason = guard.GetLastError();

                if(guardReason != "") {
                    // [v14.4 Active Rejection] DB에 거절 사유 기록 (Stuck 방지)
                    string err = StringFormat("[WATCHER-REJECT] %s. SID:%s", guardReason, sig.GetSid());
                    if(isStatusChanged && IS_VALID(log)) log.Error(xp, err);
                    
                    IRepository* repo = CX_GET_OBJ(ctx, "repo", IRepository);
                    CXMessageProvider::UpdateStatus(sig, XE_ERROR, err);
                    if(IS_VALID(repo)) repo.UpdateStatus(sig);
                    
                    activeList.Delete(i);
                    failed++;
                } else {
                    if(isStatusChanged && IS_VALID(log)) log.Trace(xp, StringFormat("[WATCHER-VALIDATION] PASSED [%s]", sigInfo));
                    sig.SetLastStatus(sig.GetStatus());
                }
            }
        }
        
        int passed = activeList.Total();
        if(passed > 0) {
            if(IS_VALID(log)) log.Trace(xp, StringFormat("[WATCHER-VALIDATION] Passed: %d, Failed: %d", passed, failed));
            return WATCHER_BINDING;
        }

        if(IS_VALID(log)) log.Warn(xp, StringFormat("[WATCHER-VALIDATION] All %d signals failed validation.", total));
        return WATCHER_DISCOVERY;
    }

    virtual void OnEnter(ICXContext* ctx) override {}
    virtual void OnExit(ICXContext* ctx) override {
        // [v10.7 Fix] Cleanup context reference if needed
    }
};

#endif
