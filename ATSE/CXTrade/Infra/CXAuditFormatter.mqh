#ifndef CXAUDITFORMATTER_MQH
#define CXAUDITFORMATTER_MQH

#include "..\Interfaces\ICXParam.mqh"
#include "..\Interfaces\ICXSignal.mqh"
#include "..\Interfaces\CXDefine.mqh"

/**
 * @class CXAuditFormatter
 * @brief Universal Audit Format (UAF) 조립을 전담하는 스태틱 유틸리티
 */
class CXAuditFormatter {
public:
    /**
     * @brief 표준화된 로그 메시지 조립
     * @param action 동작 명칭 (Block 1)
     * @param xp 실행 파라미터 (Block 2, 3 추출용)
     * @param specData 클래스별 특화 데이터 (Block 4)
     */
    static string Build(string action, ICXParam* xp, string specData = "") {
        if(IS_INVALID(xp)) return StringFormat("[%s] INVALID_PARAM", action);
        
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig)) return StringFormat("[%s] INVALID_SIGNAL", action);

        // 1. [META] + [BASE] 조립 (TE, TS, SL, TP 포인트 필수 포함)
        string metaBase = StringFormat("[%s] [%s] [%s, %.2f, %s, %s] [TE:%d,%d,%d TS:%d,%d SL:%d TP:%d]",
                                       action, 
                                       sig.GetSid(), 
                                       sig.GetSymbol(), 
                                       sig.GetLot(), 
                                       EnumToString((ENUM_CX_DIRECTION)sig.GetDir()),
                                       GetStatusName((ENUM_XE_STATUS)sig.GetStatus()),
                                       (int)sig.GetTEStart(), (int)sig.GetTEStep(), (int)sig.GetTELimit(),
                                       (int)sig.GetTSStart(), (int)sig.GetTSStep(),
                                       (int)sig.GetSL(), (int)sig.GetTP());

        // 2. [PRICE] 조립
        string symbol = sig.GetSymbol();
        double mkt = SymbolInfoDouble(symbol, (sig.GetDir() == CX_DIR_BUY) ? SYMBOL_ASK : SYMBOL_BID);
        
        string prices = StringFormat("[P:%.5f, SL:%.5f, TP:%.5f, Mkt:%.5f]",
                                     sig.GetPriceOpen(), 
                                     sig.GetPriceSL(), 
                                     sig.GetPriceTP(), 
                                     mkt);

        // 3. 최종 결합 (SPEC 유무에 따라 처리)
        string finalMsg = metaBase + " " + prices;
        if(specData != "") {
            finalMsg += " {" + specData + "}";
        }
        
        return finalMsg;
    }

private:
    static string GetStatusName(ENUM_XE_STATUS status) {
        switch(status) {
            case XE_READY:          return "READY";
            case XE_PENDING_REQ:    return "PEND_REQ";
            case XE_IN_TRANSIT:     return "TRANSIT";
            case XE_PENDING_PLACED: return "PEND_PLACED";
            case XE_EXECUTED:       return "EXEC";
            case XE_CLOSED_SIGNAL:  return "CLSD_SIG";
            case XE_CLOSED_SL:      return "CLSD_SL";
            case XE_CLOSED_TP:      return "CLSD_TP";
            case XE_CLOSED_MANUAL:  return "CLSD_MAN";
            case XE_ERROR:          return "ERROR";
            default:                return "UNKNOWN";
        }
    }
};

#endif
