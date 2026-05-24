#ifndef CX_TASK_PENDING_L_REBOUND_MQH
#define CX_TASK_PENDING_L_REBOUND_MQH

#include "..\..\..\Interfaces\IXTask.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"
#include "..\..\..\Infra\CXAuditFormatter.mqh"

/**
 * @class CXTaskPending_L_Rebound
 * @brief [Logic] 반등 감지 (Market 전환 여부 판단)
 */
class CXTaskPending_L_Rebound : public IXTask {
public:
    virtual string Name() override { return "Pending_L_Rebound"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig) || sig.GetTEStart() <= 0) return TASK_CONTINUE;

        double point = SymbolInfoDouble(sig.GetSymbol(), SYMBOL_POINT);
        double currentPrice = SymbolInfoDouble(sig.GetSymbol(), (sig.GetDir() == CX_DIR_BUY) ? SYMBOL_BID : SYMBOL_ASK);

        bool is_rebounded = (sig.GetDir() == CX_DIR_BUY) ? (currentPrice > sig.GetPriceSignal() + (sig.GetTEStep() * 1 * point))
                                                         : (currentPrice < sig.GetPriceSignal() - (sig.GetTEStep() * 1 * point));

        XP_LOG_TRACE(xp, CXAuditFormatter::Build("PEND-L-REBD", xp, StringFormat("Price rebound check: Rebounded=%d", is_rebounded)));

        if(is_rebounded) {
            XP_LOG_INFO(xp, CXAuditFormatter::Build("PEND-L-REBD", xp, "Market Fallback Triggered."));
            xp.SetInt(10); 
        }

        return TASK_CONTINUE;
    }
};

#endif
