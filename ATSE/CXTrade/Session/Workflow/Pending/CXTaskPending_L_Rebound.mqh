#ifndef CX_TASK_PENDING_L_REBOUND_MQH
#define CX_TASK_PENDING_L_REBOUND_MQH

#include "..\..\..\Core\Interfaces\IXTask.mqh"
#include "..\..\..\Core\Macros\CXMacros.mqh"
#include "..\..\..\Shared\Logging\CXAuditFormatter.mqh"

/**
 * @class CXTaskPending_L_Rebound
 * @brief [Logic] 반등 감지 (Market 전환 여부 판단)
 */
class CXTaskPending_L_Rebound : public IXTask {
public:
    virtual string Name() override { return "Pending_L_Rebound"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig) || 0 >= sig.GetTEStart()) return TASK_CONTINUE;

        double point = SymbolInfoDouble(sig.GetSymbol(), SYMBOL_POINT);
        double currentPrice = SymbolInfoDouble(sig.GetSymbol(), (sig.GetDir() == CX_DIR_BUY) ? SYMBOL_BID : SYMBOL_ASK);
        
        // [v16.26 Mandate] 극점(Extreme) 대비 TE_STEP 만큼 반등 시 시장가 진입
        string extKey = "LastEntryExtremity_" + sig.GetSid();
        ICXParam* pExt = ctx.GetParam(extKey);
        if(IS_INVALID(pExt)) return TASK_CONTINUE; // 아직 극점이 확보되지 않음
        
        double extreme = pExt.GetDouble();
        if(extreme <= 0) return TASK_CONTINUE;

        bool is_rebounded = (sig.GetDir() == CX_DIR_BUY) ? (currentPrice >= extreme + (sig.GetTEStep() * point))
                                                         : (currentPrice <= extreme - (sig.GetTEStep() * point));

        if(is_rebounded) {
            XP_LOG_OK(xp, CXAuditFormatter::Build("PEND-L-REBD", xp, 
                StringFormat("TE-STEP Rebound Triggered! Mkt:%.5f, Extreme:%.5f, Step:%d", 
                currentPrice, extreme, sig.GetTEStep())));
            
            xp.SetInt(10); // 시장가 전환 트리거 (Market Fallback)
            CXChartVisualizer::RemoveTEStart(sig); // 라인 제거
        }

        return TASK_CONTINUE;
    }
};

#endif
