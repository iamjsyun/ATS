#ifndef CX_TASK_GUARD_V_SPREAD_MQH
#define CX_TASK_GUARD_V_SPREAD_MQH

#include "..\..\..\Interfaces\IXTask.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"

/**
 * @class CXTaskGuard_V_Spread
 * @brief [Guard] 진입 직전 스프레드 급증 차단
 */
class CXTaskGuard_V_Spread : public IXTask {
public:
    virtual string Name() override { return "Guard_V_Spread"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig)) return TASK_BREAK;

        int spread = (int)SymbolInfoInteger(sig.GetSymbol(), SYMBOL_SPREAD);
        int maxSpread = 100; // 가변 설정값 필요하나 현재 하드코딩

        XP_LOG_TRACE(xp, StringFormat("[GUARD-V-SPREAD] Checking Spread for %s: Current:%d, Max:%d", 
                                      sig.GetSymbol(), spread, maxSpread));

        if(spread > maxSpread) {
            XP_LOG_WARN(xp, StringFormat("[GUARD-V-SPREAD] YIELD: High Spread Detected (%d > %d). Retrying...", spread, maxSpread));
            return TASK_YIELD;
        }

        XP_LOG_DEBUG(xp, "[GUARD-V-SPREAD] PASSED.");
        return TASK_CONTINUE;
    }
};

#endif
