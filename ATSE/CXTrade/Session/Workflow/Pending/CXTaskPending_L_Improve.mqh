#ifndef CX_TASK_PENDING_L_IMPROVE_MQH
#define CX_TASK_PENDING_L_IMPROVE_MQH

#include "..\..\..\Core\Interfaces\IXTask.mqh"
#include "..\..\..\Core\Macros\CXMacros.mqh"
#include "..\..\..\Core\Interfaces\IXPriceTracker.mqh"
#include "..\..\..\Shared\Logging\CXAuditFormatter.mqh"
#include "..\..\..\Shared\Graphics\CXChartVisualizer.mqh"

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
            if(IS_VALID(sig)) CXChartVisualizer::RemoveTEStart(sig);
            return TASK_CONTINUE;
        }

        double point = SymbolInfoDouble(sig.GetSymbol(), SYMBOL_POINT);
        double dir_sign = (sig.GetDir() == CX_DIR_BUY) ? -1.0 : 1.0;
        double currentPrice = SymbolInfoDouble(sig.GetSymbol(), (sig.GetDir() == CX_DIR_BUY) ? SYMBOL_BID : SYMBOL_ASK);
        
        // [v16.27 Stability Fix] 이번 틱의 가격 수정 요청 초기화 (Timer 루프 누출 방지)
        xp.SetDouble(0.0);
        
        // [v16.24 Precision Control] Intended price (price_signal) 기준 정밀 비교
        double orderPrice = sig.GetPriceSignal(); 
        if(orderPrice <= 0) orderPrice = sig.GetPriceOpen();
        
        // --- 1. [트리거 라인 실시간 추격 (Timer)] ---
        // 유리한 방향(Buy:하락, Sell:상승)으로 TE_STEP 이상 갱신 시 트리거 라인 이동
        string extKey = "LastEntryExtremity_" + sig.GetSid();
        double lastExt = 0;
        ICXParam* pExt = ctx.GetParam(extKey);
        if(IS_VALID(pExt)) lastExt = pExt.GetDouble();

        bool is_improved = (sig.GetDir() == CX_DIR_BUY) ? (currentPrice < lastExt - (sig.GetTEStep() * point) || lastExt <= 0)
                                                        : (currentPrice > lastExt + (sig.GetTEStep() * point) || lastExt <= 0);

        if(is_improved) {
            // [v16.26 Mandate] 극점(lastExt) 갱신 및 트리거 라인(TE_START) 재계산
            // 트리거 라인 = 현재 극점으로부터 TE_START 만큼 반등 방향으로 설정
            double newExt = currentPrice;
            double triggerPrice = newExt + (sig.GetTEStart() * point * (-dir_sign));
            
            // [v16.27] Solid Blue Line으로 시각화 (MT5 기본 점선과 구별)
            CXChartVisualizer::DrawTEStart(sig, triggerPrice);
            
            if(IS_INVALID(pExt)) {
                pExt = new CXParam();
                ctx.Set(extKey, pExt);
            }
            pExt.SetDouble(newExt);
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
                if(currentGap < sig.GetTELimit()) {
                    double target = refPrice + (sig.GetTELimit() * point * dir_sign);
                    double normTarget = NormalizeDouble(target, (int)SymbolInfoInteger(sig.GetSymbol(), SYMBOL_DIGITS));

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
