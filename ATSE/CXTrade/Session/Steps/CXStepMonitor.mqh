#ifndef CXSTEPMONITOR_MQH
#define CXSTEPMONITOR_MQH

#include "..\..\Interfaces\IXStep.mqh"
#include "..\..\Interfaces\CXDefine.mqh"
#include "..\..\Interfaces\CXMacros.mqh"
#include "..\..\Interfaces\IXPositionManager.mqh"
#include "..\..\Interfaces\IXPriceTracker.mqh"
#include "..\..\Interfaces\IXGuard.mqh"
#include "..\..\Infra\CXMessageProvider.mqh"

/**
 * @class CXStepMonitor
 * @brief 체결된 포지션의 실시간 상태 감시 및 TP/SL 체크 (Position Monitoring)
 *        [Task M1(Sync), M2(Intent), M3(Alpha/TS)] 통합 수행
 */
class CXStepMonitor : public IXStep {
public:
    virtual string Name() override { return "Step_Monitor"; }

    virtual bool OnCondition(ICXParam* xp, ICXContext* ctx, int current_state) override {
        ICXSignal* sig = xp.GetSignal();
        // 포지션이 살아있거나(EXECUTED) 이미 터미널에서 청산된 상태(CLOSED) 모두 감시/처리 대상
        return (IS_VALID(sig) && sig.GetStatus() >= XE_EXECUTED);
    }

    virtual int OnProcess(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig)) return STATE_UNCHANGED;

        // [방어 로직] 에러 상태인 경우 즉시 에러 전이
        if(sig.GetStatus() == XE_ERROR) return SESSION_ERROR;

        // Task M1: 터미널 상태 동기화 (Sync)
        IXPositionManager* posMgr = CX_GET_OBJ(ctx, "pos_mgr", IXPositionManager);
        if(IS_VALID(posMgr)) {
            posMgr.Pulse(xp);
        }

        // 0. 이미 브로커 레벨에서 청산된 경우 (SL/TP 히트 등으로 xe_status 갱신 시)
        if(sig.GetStatus() >= XE_CLOSED_SIGNAL) {
            XP_LOG_INFO(xp, "[STEP-MONITOR] Broker-level exit detected. Moving to LIQUIDATING.");
            return SESSION_LIQUIDATING;
        }

        // Task M2: 외부 청산 의도 감시 (Intent)
        if(sig.GetXAExit() == XA_ACTIVE) {
            CXMessageProvider::UpdateStatus(sig, sig.GetStatus(), MSG_EXIT_REQUESTED);
            XP_LOG_INFO(xp, "[STEP-MONITOR] Exit Command (XA_ACTIVE) Detected. Moving to LIQUIDATING.");
            return SESSION_LIQUIDATING;
        }

        // Task M3: 알파(트레일링) 엔진 실행 (AlphaTask)
        if(sig.GetTSStart() > 0) {
            IXPriceTracker* tracker = CX_GET_OBJ(ctx, "price_tracker", IXPriceTracker);
            if(IS_VALID(posMgr) && IS_VALID(tracker)) {
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

                        // 브로커 StopsLevel 검증 필수 수행
                        IXGuard* guard = CX_GET_OBJ(ctx, "guard", IXGuard);
                        if(IS_VALID(guard) && !guard.ValidateStopLevel(sig.GetSymbol(), currentPrice, newSL)) {
                            XP_LOG_WARN(xp, "[TS-MODIFY] StopsLevel Validation Failed! Modification deferred.");
                        } else {
                            // 브로커 포지션 수정 실행
                            if(posMgr.ModifyPosition(xp, (ulong)sig.GetTicket(), newSL, sig.GetTP())) {
                                sig.SetSL(newSL);
                                sig.SetStatusMsg(MSG_EXIT_TS_MODIFIED);
                                XP_LOG_INFO(xp, StringFormat("[TS-MODIFY] Ticket:%lld, SL:%.5f -> %.5f", sig.GetTicket(), sig.GetSL(), newSL));
                            }
                        }
                    }
                }
            }
        }

        return STATE_UNCHANGED; // 상태 유지 (세션 활성 상태 지속)
    }

    virtual void OnEnter(ICXContext* ctx) override { XP_LOG_DEBUG(NULL, "[STEP-MONITOR] Starting Position Monitoring"); }
    virtual void OnExit(ICXContext* ctx) override { XP_LOG_DEBUG(NULL, "[STEP-MONITOR] Stopping Position Monitoring"); }
};

#endif

