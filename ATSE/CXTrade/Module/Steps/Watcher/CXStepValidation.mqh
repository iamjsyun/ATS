#ifndef CXSTEPVALIDATION_MQH
#define CXSTEPVALIDATION_MQH

#include "..\..\..\Interfaces\IXStep.mqh"
#include "..\..\..\Interfaces\IXGuard.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"
#include "..\..\..\Models\CXSignal.mqh"

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

            // [v11.0 Rule 1 & 3] 상세 로그 생성 및 중복 방지
            string sigInfo = StringFormat("SID:%s, Sym:%s, P:%.5f, L:%.2f, Typ:%d, TE:%d, TS:%d, SL:%d, TP:%d, EN:%d, EX:%d, ST:%d",
                sig.GetSid(), sig.GetSymbol(), sig.GetPriceSignal(), sig.GetLot(), sig.GetType(), 
                (int)sig.GetTEStart(), (int)sig.GetTSStart(), (int)sig.GetSL(), (int)sig.GetTP(),
                sig.GetXAEntry(), sig.GetXAExit(), sig.GetStatus());

            bool isStatusChanged = (sig.GetStatus() != sig.GetLastStatus());

            if(IS_VALID(guard)) {
                // [v10.22] Explicit Error Status Filtering
                if(sig.GetStatus() == XE_ERROR) {
                    if(isStatusChanged && IS_VALID(log)) log.Error(xp, StringFormat("[WATCHER-VALIDATION] REJECTED (XE_ERROR) [%s]", sigInfo));
                    sig.SetLastStatus(XE_ERROR);
                    activeList.Delete(i);
                    failed++;
                    continue;
                }

                if(!guard.ValidateMagic(sig.GetMagic()) || 
                   !guard.ValidateSID(sig.GetSid()) || 
                   !guard.ValidateLot(sig.GetSymbol(), sig.GetLot()) ||
                   !guard.ValidatePrice(sig.GetSymbol(), sig.GetPriceSignal())) {
                    
                    if(isStatusChanged && IS_VALID(log)) {
                        string err = StringFormat("[WATCHER-VALIDATION] FAILED [%s] - %s", sigInfo, guard.GetLastError());
                        log.Error(xp, err);
                    }
                    
                    sig.SetLastStatus(sig.GetStatus());
                    activeList.Delete(i);
                    failed++;
                } else {
                    if(isStatusChanged && IS_VALID(log)) log.Debug(xp, StringFormat("[WATCHER-VALIDATION] PASSED [%s]", sigInfo));
                    sig.SetLastStatus(sig.GetStatus());
                }
            }
        }
        
        int passed = activeList.Total();
        if(passed > 0) {
            if(IS_VALID(log)) log.Info(xp, StringFormat("[WATCHER-VALIDATION] Passed: %d, Failed: %d", passed, failed));
            return WATCHER_BINDING;
        }

        if(IS_VALID(log)) log.Warn(xp, StringFormat("[WATCHER-VALIDATION] All %d signals failed validation.", total));
        return WATCHER_DISCOVERY;
    }

    virtual void OnEnter(ICXContext* ctx) override {}
    virtual void OnExit(ICXContext* ctx) override {}
};

#endif
