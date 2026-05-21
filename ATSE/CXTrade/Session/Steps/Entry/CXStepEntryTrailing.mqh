#ifndef CXSTEPENTRYTRAILING_MQH
#define CXSTEPENTRYTRAILING_MQH

#include "..\..\..\Interfaces\IXStep.mqh"
#include "..\..\..\Interfaces\IXPriceTracker.mqh"
#include "..\..\..\Interfaces\IXOrderManager.mqh"
#include "..\..\..\Infra\CXMessageProvider.mqh"

/**
 * @class CXStepEntryTrailing
 * @brief 지정가 주문의 실시간 가격 추적 및 수정 (Trailing Entry)
 */
class CXStepEntryTrailing : public IXStep {
public:
    virtual string Name() override { return "Step_EntryTrailing"; }

    virtual bool OnCondition(ICXParam* xp, ICXContext* ctx, int current_state) override {
        ICXSignal* sig = xp.GetSignal();
        // 주문이 배치된 상태(PENDING_PLACED)이면 트레일링 설정(te_start) 유무와 무관하게 진입하여 감시
        return (IS_VALID(sig) && sig.GetStatus() == XE_PENDING_PLACED);
    }

    virtual int OnProcess(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        IXOrderManager* orderMgr = CX_GET_OBJ(ctx, "order_mgr", IXOrderManager);
        IXPriceTracker* tracker = CX_GET_OBJ(ctx, "price_tracker", IXPriceTracker);
        
        if(IS_INVALID(sig) || IS_INVALID(orderMgr) || IS_INVALID(tracker)) return STATE_UNCHANGED;

        // [방어 로직] 에러 상태인 경우 즉시 에러 전이
        if(sig.GetStatus() == XE_ERROR) return SESSION_ERROR;

        //-- [추가] 외부 청산/취소 명령 확인 (L-01 대응)
        if(sig.GetXAExit() == XA_ACTIVE) {
            XP_LOG_WARN(xp, "[TE-PROCESS] Exit command (XA_ACTIVE) detected during trailing. Moving to LIQUIDATING.");
            return SESSION_LIQUIDATING;
        }

        // 1. 체결 여부 확인 (OnTradeTransaction 등에 의해 xe_status가 변경된 경우)
        if(sig.GetStatus() >= XE_EXECUTED) return SESSION_ACTIVE;

        // 트레일링 설정이 없는 경우 (일반 지정가 대기), 상태 변경 여부만 확인하고 리턴
        if(sig.GetTEStart() <= 0) return STATE_UNCHANGED;

        // 2. 새로운 트레일링 가격 계산
        double point = SymbolInfoDouble(sig.GetSymbol(), SYMBOL_POINT);
        double currentPrice = SymbolInfoDouble(sig.GetSymbol(), (sig.GetDir() == CX_DIR_BUY) ? SYMBOL_BID : SYMBOL_ASK);
        tracker.Update(currentPrice);

        //-- [수정] 반등 감지 및 시장가 진입 전환 (Fallback)
        // 가격이 TE Step만큼 반등 시 즉시 시장가 진입
        bool is_rebounded = (sig.GetDir() == CX_DIR_BUY) ? (currentPrice > sig.GetPriceSignal() + (sig.GetTEStep() * 1 * point))
                                                   : (currentPrice < sig.GetPriceSignal() - (sig.GetTEStep() * 1 * point));

        if(is_rebounded) {
            XP_LOG_WARN(xp, "[TE-MODIFY] Price rebound detected. Switching to Market Entry.");
            
            // 2.1 기존 대기 주문 취소 및 결과 확인
            if(orderMgr.DeleteOrder(xp, (ulong)sig.GetTicket())) {
                XP_LOG_INFO(xp, "[TE-MODIFY] Pending order deleted successfully.");
                
                // 2.2 시장가 진입 실행
                sig.SetType(ORDER_MARKET);
                if(orderMgr.ExecuteEntry(xp)) {
                    return SESSION_ACTIVE; 
                } else {
                    XP_LOG_ERROR(xp, "[TE-MODIFY] Market entry failed after rebound. Moving to SESSION_ERROR.");
                    return SESSION_ERROR;
                }
            } else {
                XP_LOG_ERROR(xp, "[TE-MODIFY] Failed to delete pending order. Aborting market entry.");
                return SESSION_ERROR;
            }
        }

        double dir_sign = (sig.GetDir() == CX_DIR_BUY) ? -1.0 : 1.0;
        double target = currentPrice + (sig.GetTEStart() * point * dir_sign);
        
        // 갱신 조건 검사 (Better Price check)
        bool is_improved = (sig.GetDir() == CX_DIR_BUY) ? (target < sig.GetPriceSignal() - sig.GetTEStep() * point) 
                                                   : (target > sig.GetPriceSignal() + sig.GetTEStep() * point);

        if(is_improved) {
            double newPrice = NormalizeDouble(target, (int)SymbolInfoInteger(sig.GetSymbol(), SYMBOL_DIGITS));
            
            // [v7.9] 주문 수정 전 브로커 StopsLevel 검증 필수 수행
            IXGuard* guard = CX_GET_OBJ(ctx, "guard", IXGuard);
            if(IS_VALID(guard) && !guard.ValidateStopLevel(sig.GetSymbol(), currentPrice, newPrice)) {
                XP_LOG_WARN(xp, "[TE-MODIFY] StopsLevel Validation Failed! Modification deferred.");
                return STATE_UNCHANGED;
            }

            // 3. 브로커 주문 수정 실행
            if(orderMgr.ModifyOrder(xp, (ulong)sig.GetTicket(), newPrice, sig.GetSL(), sig.GetTP())) {
                sig.UpdatePriceSignal(newPrice);

                CXMessageProvider::UpdateStatus(sig, sig.GetStatus(), MSG_ENTRY_TRAILING_MODIFIED);
                XP_LOG_INFO(xp, StringFormat("[TE-MODIFY] Ticket:%lld, New Price:%.5f", sig.GetTicket(), newPrice));
            }
        }

        return STATE_UNCHANGED; // 상태 유지
    }

    virtual void OnEnter(ICXContext* ctx) override { XP_LOG_DEBUG(NULL, "[STEP-TE] Starting Entry Trailing Loop"); }
    virtual void OnExit(ICXContext* ctx) override { XP_LOG_DEBUG(NULL, "[STEP-TE] Exiting Entry Trailing Loop"); }
};

#endif

