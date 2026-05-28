#ifndef CX_TASK_PENDING_L_IMPROVE_MQH
#define CX_TASK_PENDING_L_IMPROVE_MQH

#include "..\..\..\Platform\Core\Interfaces\IXTask.mqh"
#include "..\..\..\Platform\Core\Macros\CXMacros.mqh"
#include "..\..\..\Platform\Core\Interfaces\IXPriceTracker.mqh"
#include "..\..\..\Platform\Shared\Logging\CXAuditFormatter.mqh"
#include "..\..\..\Platform\Shared\Graphics\CXChartVisualizer.mqh"
#include "..\..\..\Platform\Core\Interfaces\ICXSymbolManager.mqh"
#include "..\..\..\Platform\Core\Interfaces\ICXPriceManager.mqh"

/**
 * @class CXTaskPending_L_Improve
 * @brief [Logic] 진입 트레일링 가격 개선 계산
 */
class CXTaskPending_L_Improve : public IXTask {
public:
    virtual string Name() override { return "Pending_L_Improve"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig) || 0 >= sig.GetTEStart() || xp.GetInt() == 10) {
            // [v16.20 Cleanup] 진입 완료 또는 로직 중단 시 라인 제거
            if(IS_VALID(sig)) CXChartVisualizer::RemoveTEStart(ctx, sig);
            return TASK_CONTINUE;
        }

        ICXSymbolManager* symMgr = CX_GET_OBJ(ctx, "sym_mgr", ICXSymbolManager);
        ICXPriceManager* priceMgr = CX_GET_OBJ(ctx, "price_mgr", ICXPriceManager);

        double point = IS_VALID(symMgr) ? symMgr.GetPoint(sig.GetSymbol()) : SymbolInfoDouble(sig.GetSymbol(), SYMBOL_POINT);
        double dir_sign = (sig.GetDir() == CX_DIR_BUY) ? -1.0 : 1.0;
        double currentPrice = IS_VALID(priceMgr) ? priceMgr.GetLiquidationPrice(sig.GetSymbol(), sig.GetDir()) : SymbolInfoDouble(sig.GetSymbol(), (sig.GetDir() == CX_DIR_BUY) ? SYMBOL_BID : SYMBOL_ASK);
        
        // [v16.27 Stability Fix] 이번 틱의 가격 수정 요청 초기화 (Timer 루프 누출 방지)
        xp.SetDouble(0.0);
        
        // [v16.24 Precision Control] Intended price (price_signal) 기준 정밀 비교
        double orderPrice = sig.GetPriceSignal(); 
        if(orderPrice <= 0) orderPrice = sig.GetPriceOpen();
        
        // --- 1. [트리거 라인 실시간 추격 (Timer)] ---
        // [v16.31 Phase Detection] 활성화 상태에 따른 시각화 및 로직 분리
        string activeKey = "TE_Active_" + sig.GetSid();
        bool isActive = false;
        ICXParam* pActive = ctx.GetParam(activeKey);
        if(IS_VALID(pActive) && pActive.GetInt() == 1) isActive = true;

        string extKey = "LastEntryExtremity_" + sig.GetSid();
        double extVal = 0;
        ICXParam* pExt = ctx.GetParam(extKey);
        if(IS_VALID(pExt)) extVal = pExt.GetDouble();

        // [v16.32 Visual Correction] 활성화 여부에 따른 트리거 라인 위치 정밀화
        double triggerPrice = 0;
        bool shouldDraw = false;

        if(!isActive) {
            // 1. 활성화 전: 진트 활성화 임계선 표시 (price_signal 기준 고정)
            double priceSignal = sig.GetPriceSignal();
            if(priceSignal <= 0) priceSignal = orderPrice - (sig.GetTELimit() * point * dir_sign);
            triggerPrice = priceSignal + (sig.GetTEStart() * point * dir_sign);

            // [v18.36] 활성화 전 라인은 최초 1회 또는 상태 전이 시에만 출력
            string drawKey = "TE_InitialDraw_" + sig.GetSid();
            if(IS_INVALID(ctx.GetParam(drawKey))) {
                ICXParam* pDraw = new CXParam();
                pDraw.SetInt(1);
                ctx.Set(drawKey, pDraw);
                shouldDraw = true;
            }
            } else {
            // 2. 활성화 후: 실제 시장가 진입 반등 트리거선 표시 (extreme 기준 유동)
            // BUY: extreme + TE_STEP, SELL: extreme - TE_STEP
            if(extVal > 0) {
                triggerPrice = extVal - (sig.GetTEStep() * point * dir_sign);

                // 극점이 갱신되었거나, 방금 활성화 상태로 전환되었다면 갱신
                string lastDrawExtKey = "TE_LastDrawExt_" + sig.GetSid();
                ICXParam* pLastDraw = ctx.GetParam(lastDrawExtKey);
                if(IS_INVALID(pLastDraw) || pLastDraw.GetDouble() != extVal) {
                    if(IS_INVALID(pLastDraw)) {
                        pLastDraw = new CXParam();
                        ctx.Set(lastDrawExtKey, pLastDraw);
                    }
                    pLastDraw.SetDouble(extVal);
                    shouldDraw = true;
                }
            }
            }
        
        if(shouldDraw && triggerPrice > 0) {
            CXChartVisualizer::DrawTEStart(ctx, sig, triggerPrice, "CXTaskPending_L_Improve");
        }

        // --- 2. [진입 오더 가격 유지 (1분봉 마감)] ---
        // 1분봉 마감 시 iLow/iHigh 대비 간격이 TE_LIMIT 미만으로 줄어들면 오더를 뒤로 밀어냄 (Push-back)
        string barKey = "LastEntryUpdateBar_" + sig.GetSymbol();
        datetime lastBar = 0;
        ICXParam* pBar = ctx.GetParam(barKey);
        if(IS_VALID(pBar)) lastBar = (datetime)pBar.GetLong();

        datetime currentBar = iTime(sig.GetSymbol(), PERIOD_M1, 0);
        
        if(currentBar > lastBar) {
            double refPrice = (sig.GetDir() == CX_DIR_BUY) ? iLow(sig.GetSymbol(), PERIOD_M1, 1) 
                                                           : iHigh(sig.GetSymbol(), PERIOD_M1, 1);
            
            if(refPrice > 0) {
                double currentGap = MathAbs(refPrice - orderPrice) / point;
                if(sig.GetTELimit() - currentGap >= 0) {
                    double target = refPrice + (sig.GetTELimit() * point * dir_sign);
                    int digits = IS_VALID(symMgr) ? symMgr.GetDigits(sig.GetSymbol()) : (int)SymbolInfoInteger(sig.GetSymbol(), SYMBOL_DIGITS);
                    double normTarget = NormalizeDouble(target, digits);

                    if(MathAbs(normTarget - orderPrice) >= sig.GetTEStep() * point) {
                        XP_LOG_OK(xp, CXAuditFormatter::Build("PEND-L-IMPR", xp, 
                            StringFormat("Gap Tightened (%.1f < %d). Pushing order to %.5f", 
                            currentGap, sig.GetTELimit(), normTarget)));
                        
                        // [CRITICAL] 1분봉 마감 시에만 목표 가격을 설정하여 타이머 주기의 떨림 방지
                        xp.SetDouble(normTarget);
                        xp.SetInt(1); // Trigger Modification
                    }
                }
            }
            
            if(IS_INVALID(pBar)) {
                pBar = new CXParam();
                ctx.Set(barKey, pBar);
            }
            pBar.SetLong((long)currentBar);
        }

        return TASK_CONTINUE;
    }
};

#endif
