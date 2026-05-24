#ifndef CX_TASK_ALPHA_APPLY_MQH
#define CX_TASK_ALPHA_APPLY_MQH

#include "..\..\..\Interfaces\IXTask.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"
#include "..\..\..\Interfaces\IXPositionManager.mqh"
#include "..\..\..\Interfaces\IXGuard.mqh"
#include "..\..\..\Infra\CXAuditFormatter.mqh"

/**
 * @class CXTaskAlphaApply
 * @brief 계산된 SL/TP를 브로커에 적용 (Action)
 */
class CXTaskAlphaApply : public IXTask {
public:
    virtual string Name() override { return "Task_AlphaApply"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig) || sig.GetStatus() == XE_ERROR) return TASK_BREAK;

        double newSL = xp.GetDouble();
        if(newSL <= 0) return TASK_CONTINUE;

        XP_LOG_TRACE(xp, CXAuditFormatter::Build("ALPHA-APPLY", xp, StringFormat("Attempting SL:%.5f", newSL)));

        IXPositionManager* posMgr = CX_GET_OBJ(ctx, "pos_mgr", IXPositionManager);
        IXGuard* guard = CX_GET_OBJ(ctx, "guard", IXGuard);
        if(IS_INVALID(posMgr)) {
            XP_LOG_ERROR(xp, CXAuditFormatter::Build("ALPHA-APPLY", xp, "FAILED: PositionManager missing."));
            return TASK_BREAK;
        }

        double currentPrice = SymbolInfoDouble(sig.GetSymbol(), (sig.GetDir() == CX_DIR_BUY) ? SYMBOL_BID : SYMBOL_ASK);
        
        if(IS_VALID(guard) && !guard.ValidateStopLevel(sig.GetSymbol(), currentPrice, newSL)) {
            XP_LOG_WARN(xp, CXAuditFormatter::Build("ALPHA-APPLY", xp, StringFormat("StopLevel Violation. SL:%.5f", newSL)));
            return TASK_BREAK;
        }

        if(posMgr.ModifyPosition(xp, (ulong)sig.GetTicket(), newSL, sig.GetTP())) {
            sig.SetSL(newSL);
            sig.SetStatusMsg(MSG_EXIT_TS_MODIFIED);
            XP_LOG_OK(xp, CXAuditFormatter::Build("ALPHA-APPLY", xp, "SUCCESS: SL Modified."));
        } else {
            string lastErr = xp.GetString();
            if(lastErr == "") lastErr = "Broker Rejected";
            XP_LOG_ERROR(xp, CXAuditFormatter::Build("ALPHA-APPLY", xp, "FAILED: " + lastErr));
        }

        return TASK_CONTINUE;
    }
};

#endif
