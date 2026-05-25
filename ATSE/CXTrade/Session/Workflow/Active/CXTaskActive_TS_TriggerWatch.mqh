#ifndef CX_TASK_ACTIVE_TS_TRIGGER_WATCH_MQH
#define CX_TASK_ACTIVE_TS_TRIGGER_WATCH_MQH

#include "..\..\..\Core\Interfaces\IXTask.mqh"
#include "..\..\..\Core\Macros\CXMacros.mqh"
#include "..\..\..\Shared\Logging\CXAuditFormatter.mqh"

/**
 * @class CXTaskActive_TS_TriggerWatch
 * @brief [Verify] 익절 트레일링(TS_START) 활성화 지점 감시 (v17.6)
 */
class CXTaskActive_TS_TriggerWatch : public IXTask {
public:
    virtual string Name() override { return "TS_TriggerWatch"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig) || 0 >= sig.GetTSStart()) return TASK_BREAK;

        double point = SymbolInfoDouble(sig.GetSymbol(), SYMBOL_POINT);
        double currentPrice = SymbolInfoDouble(sig.GetSymbol(), (sig.GetDir() == CX_DIR_BUY) ? SYMBOL_BID : SYMBOL_ASK);
        
        double dir_sign = (sig.GetDir() == CX_DIR_BUY) ? 1.0 : -1.0;
        double profit = (currentPrice - sig.GetPriceOpen()) * dir_sign;

        // 수익이 TS_START(포인트) 이상 발생했는지 확인
        if(profit >= sig.GetTSStart() * point) {
            XP_LOG_OK(xp, CXAuditFormatter::Build("TS-WATCH", xp, StringFormat("TS Triggered! Profit %.0f pts >= TS_START %d pts", profit / point, (int)sig.GetTSStart())));
            return SESSION_TRAILING_STOP; // 익절 트레일링 상태로 전이
        }

        return TASK_CONTINUE;
    }
};

#endif
