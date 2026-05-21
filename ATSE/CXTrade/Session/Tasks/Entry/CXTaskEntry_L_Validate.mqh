#ifndef CX_TASK_ENTRY_L_VALIDATE_MQH
#define CX_TASK_ENTRY_L_VALIDATE_MQH

#include "..\..\..\Interfaces\IXTask.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"
#include "..\..\..\Interfaces\IXGuard.mqh"
#include "..\..\..\Interfaces\ICXRiskManager.mqh"
#include "..\..\..\Interfaces\ICXPriceManager.mqh"

/**
 * @class CXTaskEntry_L_Validate
 * @brief [Logic] 진입 조건 및 가드 검증 (I/O 없음)
 */
class CXTaskEntry_L_Validate : public IXTask {
public:
    virtual string Name() override { return "Entry_L_Validate"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        IXGuard* guard = CX_GET_OBJ(ctx, "guard", IXGuard);
        ICXRiskManager* riskMgr = CX_GET_OBJ(ctx, "risk_mgr", ICXRiskManager);
        ICXPriceManager* priceMgr = CX_GET_OBJ(ctx, "price_mgr", ICXPriceManager);

        if(IS_INVALID(sig) || IS_INVALID(riskMgr) || IS_INVALID(priceMgr)) {
            XP_LOG_ERROR(xp, "[ENTRY-L] FAILED: Required services missing.");
            return TASK_BREAK;
        }

        XP_LOG_TRACE(xp, StringFormat("[ENTRY-L] Starting Validation for SID:%s (Sym:%s, Lot:%.2f, Status:%d, XAExit:%d)", 
                                      sig.GetSid(), sig.GetSymbol(), sig.GetLot(), sig.GetStatus(), sig.GetXAExit()));

        //--- [v10.24 Fix] Error-State Liquidation Bypass
        if(sig.GetXAExit() == XA_ACTIVE) {
            XP_LOG_INFO(xp, "[ENTRY-L] OK: Exit intent detected. Redirecting to LIQUIDATING.");
            return SESSION_LIQUIDATING;
        }

        if(sig.GetStatus() == XE_ERROR) return SESSION_ERROR;
        
        if(sig.GetXAEntry() != XA_ACTIVE || sig.GetStatus() >= XE_EXECUTED) return TASK_BREAK;

        // 1. Identification Validation (Guard)
        if(IS_VALID(guard)) {
            if(!guard.ValidateMagic(sig.GetMagic()) || !guard.ValidateSID(sig.GetSid())) return TASK_BREAK;
        }

        // 2. Lot & Margin Validation (SSOC via RiskManager)
        string symbol = sig.GetSymbol();
        double lot = sig.GetLot();
        int dir = sig.GetDir();
        double marketPrice = priceMgr.GetMarketPrice(symbol, dir);

        if(!riskMgr.ValidateLot(xp, symbol, lot)) return TASK_BREAK;
        if(!riskMgr.CheckMarginAvailability(xp, symbol, dir, lot, marketPrice)) return TASK_BREAK;
        if(!riskMgr.ValidateAccountRisk(xp)) return TASK_BREAK;

        return TASK_CONTINUE;
    }
};

#endif
