#ifndef CXSTEPEXITTRAILING_MQH
#define CXSTEPEXITTRAILING_MQH

#include "..\..\..\Interfaces\IXStep.mqh"
#include "..\..\..\Interfaces\IXPriceTracker.mqh"
#include "..\..\..\Interfaces\IXPositionManager.mqh"
#include "..\..\..\Models\CXSignal.mqh"
#include "..\..\..\Infra\CXAuditFormatter.mqh"

/**
 * @class CXStepExitTrailing
 * @brief 체결된 포지션의 수익 보존을 위한 익절 트레일링(Ik-Te/TS)
 */
class CXStepExitTrailing : public IXStep {
public:
    virtual string Name() override { return "Step_ExitTrailing"; }

    virtual bool OnCondition(ICXParam* xp, ICXContext* ctx, int current_state) override {
        ICXSignal* sig = xp.GetSignal();
        // 체결된 상태(EXECUTED)이고 트레일링 설정(ts_start)이 있는 경우
        return (IS_VALID(sig) && sig.GetStatus() == XE_EXECUTED && sig.GetTSStart() > 0);
    }

    virtual int OnProcess(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        IXPositionManager* posMgr = CX_GET_OBJ(ctx, "pos_mgr", IXPositionManager);
        IXPriceTracker* tracker = CX_GET_OBJ(ctx, "price_tracker", IXPriceTracker);
        
        if(IS_INVALID(sig) || IS_INVALID(posMgr) || IS_INVALID(tracker)) return STATE_UNCHANGED;

        // 1. 외부 청산 신호 확인
        if(sig.GetXAExit() == XA_ACTIVE) return SESSION_LIQUIDATING;

        // 2. 새로운 트레일링 SL 가격 계산
        double point = SymbolInfoDouble(sig.GetSymbol(), SYMBOL_POINT);
        double currentPrice = SymbolInfoDouble(sig.GetSymbol(), (sig.GetDir() == CX_DIR_BUY) ? SYMBOL_BID : SYMBOL_ASK);
        tracker.Update(currentPrice);

        double dir_sign = (sig.GetDir() == CX_DIR_BUY) ? 1.0 : -1.0;
        double profit = (currentPrice - sig.GetPriceOpen()) * dir_sign;

        if(profit >= sig.GetTSStart() * point) {
            double peak = (sig.GetDir() == CX_DIR_BUY) ? tracker.GetHighest() : tracker.GetLowest();
            double target = peak - (sig.GetTSStart() * point * dir_sign);

            // 갱신 조건 검사 (Better SL check)
            bool is_improved = (sig.GetDir() == CX_DIR_BUY) ? (target > sig.GetSL() + sig.GetTSStep() * point)
                                                       : (target < sig.GetSL() - sig.GetTSStep() * point || sig.GetSL() == 0);

            if(is_improved) {
                double newSL = NormalizeDouble(target, (int)SymbolInfoInteger(sig.GetSymbol(), SYMBOL_DIGITS));

                // [v7.9] 포지션 수정 전 브로커 StopsLevel 검증 필수 수행
                IXGuard* guard = CX_GET_OBJ(ctx, "guard", IXGuard);
                if(IS_VALID(guard) && !guard.ValidateStopLevel(sig.GetSymbol(), currentPrice, newSL)) {
                    XP_LOG_WARN(xp, CXAuditFormatter::Build("TS-MODIFY-VLD-FAIL", xp, "StopsLevel Validation Failed"));
                    return STATE_UNCHANGED;
                }

                // 3. 브로커 포지션 수정 실행
                if(posMgr.ModifyPosition(xp, (ulong)sig.GetTicket(), newSL, sig.GetTP())) {
                    double oldSL = sig.GetSL();
                    sig.SetSL(newSL);
                    sig.SetStatusMsg(MSG_EXIT_TS_MODIFIED);
                    XP_LOG_INFO(xp, CXAuditFormatter::Build("TS-MODIFY-OK", xp, StringFormat("SL:%.5f->%.5f", oldSL, newSL)));
                }
            }
        }

        return STATE_UNCHANGED; // 상태 유지
    }

    virtual void OnEnter(ICXContext* ctx) override { XP_LOG_DEBUG(NULL, "[STEP-TS] Starting Exit Trailing Loop"); }
    virtual void OnExit(ICXContext* ctx) override { XP_LOG_DEBUG(NULL, "[STEP-TS] Exiting Exit Trailing Loop"); }
};

#endif
