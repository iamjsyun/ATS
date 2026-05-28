#ifndef CX_TASK_PENDING_L_REBOUND_MQH
#define CX_TASK_PENDING_L_REBOUND_MQH

#include "..\..\..\Platform\Core\Interfaces\IXTask.mqh"
#include "..\..\..\Platform\Core\Macros\CXMacros.mqh"
#include "..\..\..\Platform\Shared\Logging\CXAuditFormatter.mqh"
#include "..\..\..\Platform\Core\Interfaces\ICXSymbolManager.mqh"
#include "..\..\..\Platform\Core\Interfaces\ICXPriceManager.mqh"

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

        // 중복 출력 및 처리 방지 (동일 SID/티켓 1회만 출력)
        string triggeredKey = "ReboundTriggered_" + sig.GetSid();
        ICXParam* pTriggered = ctx.GetParam(triggeredKey);
        if(IS_VALID(pTriggered) && pTriggered.GetInt() >= 1) {
            xp.SetInt(10); // 시장가 전환 트리거 상태 유지
            return TASK_CONTINUE;
        }

        // [v16.30 Activation Guard] 활성화되지 않은 경우 반등 체크 스킵
        string activeKey = "TE_Active_" + sig.GetSid();
        ICXParam* pActive = ctx.GetParam(activeKey);
        if(IS_INVALID(pActive) || pActive.GetInt() != 1) return TASK_CONTINUE;

        ICXSymbolManager* symMgr = CX_GET_OBJ(ctx, "sym_mgr", ICXSymbolManager);
        ICXPriceManager* priceMgr = CX_GET_OBJ(ctx, "price_mgr", ICXPriceManager);

        double point = IS_VALID(symMgr) ? symMgr.GetPoint(sig.GetSymbol()) : SymbolInfoDouble(sig.GetSymbol(), SYMBOL_POINT);
        double currentPrice = IS_VALID(priceMgr) ? priceMgr.GetLiquidationPrice(sig.GetSymbol(), sig.GetDir()) : SymbolInfoDouble(sig.GetSymbol(), (sig.GetDir() == CX_DIR_BUY) ? SYMBOL_BID : SYMBOL_ASK);
        
        // [v16.26 Mandate] 극점(Extreme) 대비 TE_STEP 만큼 반등 시 시장가 진입
        string extKey = "LastEntryExtremity_" + sig.GetSid();
        ICXParam* pExt = ctx.GetParam(extKey);
        if(IS_INVALID(pExt)) return TASK_CONTINUE; // 아직 극점이 확보되지 않음
        
        double extreme = pExt.GetDouble();
        if(extreme <= 0) return TASK_CONTINUE;

        // [v1.0 Logger Complement] 정밀 디버깅을 위한 반등 거리 변경 모니터링 로그 추가
        double reboundDist = (sig.GetDir() == CX_DIR_BUY) ? (currentPrice - extreme) / point : (extreme - currentPrice) / point;
        string lastLogKey = "ReboundLastLogDist_" + sig.GetSid();
        ICXParam* pLastLog = ctx.GetParam(lastLogKey);
        double lastLogVal = IS_VALID(pLastLog) ? pLastLog.GetDouble() : -999999.0;

        if(MathAbs(reboundDist - lastLogVal) >= 1.0) {
            if(IS_INVALID(pLastLog)) {
                pLastLog = new CXParam();
                ctx.Set(lastLogKey, pLastLog);
            }
            pLastLog.SetDouble(reboundDist);
            XP_LOG_TRACE(xp, CXAuditFormatter::Build("PEND-L-REBD", xp, 
                StringFormat("Trailing Entry Active: Mkt:%.5f, Extreme:%.5f, ReboundDist:%.1f pt, TargetStep:%d pt", 
                currentPrice, extreme, reboundDist, (int)sig.GetTEStep())));
        }

        bool is_rebounded = (sig.GetDir() == CX_DIR_BUY) ? (currentPrice - extreme >= sig.GetTEStep() * point)
                                                         : (extreme - currentPrice >= sig.GetTEStep() * point);

        if(is_rebounded) {
            XP_LOG_OK(xp, CXAuditFormatter::Build("PEND-L-REBD", xp, 
                StringFormat("TE-STEP Rebound Triggered! Mkt:%.5f, Extreme:%.5f, Step:%d", 
                currentPrice, extreme, (int)sig.GetTEStep())));
            
            sig.SetStatusMsg("Rebound Triggered: Pending Market Entry Task...");
            
            // [v1.2 Fix] 컨텍스트 영속 플래그 설정 (Task 간 간섭 방어)
            ICXParam* pReb = new CXParam();
            pReb.SetInt(10);
            ctx.Set(triggeredKey, pReb);

            xp.SetInt(10); // 시장가 전환 트리거 (Market Fallback)
            CXChartVisualizer::RemoveTEStart(ctx, sig); // 라인 제거
        }

        return TASK_CONTINUE;
    }
};

#endif
