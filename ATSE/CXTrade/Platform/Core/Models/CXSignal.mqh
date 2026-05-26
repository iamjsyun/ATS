#ifndef CXSIGNAL_MQH
#define CXSIGNAL_MQH

#include "..\Interfaces\ICXSignal.mqh"
#include "..\Defines\CXDefine.mqh"

/**
 * @class CXSignal
 * @brief 시스템 전반에서 사용되는 신호 엔티티 (Schema SSOT 적용)
 */
class CXSignal : public ICXSignal {
public:
    //--- [1] 멤버 변수 자동 생성
    #define X(type, name, dbType, getter) type name;
    SIGNAL_SCHEMA_FIELDS
    #undef X

    //--- 런타임 전용 필드 (비영속)
    int       last_status; 

    CXSignal() {
        Reset();
    }

    /**
     * @brief [SSOT] 모든 필드를 표준 초기값으로 리셋.
     * @details MQL5 내장 ZeroMemory를 사용하여 타입별 경고 없이 안전하게 초기화.
     */
    void Reset() {
        #define X(type, name, dbType, getter) ZeroMemory(name);
        SIGNAL_SCHEMA_FIELDS
        #undef X
        
        last_status = -1;
    }

    virtual ~CXSignal() override {}

    //--- [2] 인터페이스 접근자 수동 전개 (SetSid, SetGid 커스터마이징을 위해 매크로 최소화)
    // Getters
    #define X(type, name, dbType, getter) virtual type Get##getter() const override { return name; }
    SIGNAL_SCHEMA_FIELDS
    #undef X

    // Setters (수동 구현)
    virtual void SetId(int v) override { id = v; }
    virtual void SetSid(string v) override { sid = v; StringTrimLeft(sid); StringTrimRight(sid); }
    virtual void SetGid(string v) override { gid = v; StringTrimLeft(gid); StringTrimRight(gid); }
    virtual void SetCno(int v) override { cno = v; }
    virtual void SetSno(int v) override { sno = v; }
    virtual void SetMsgId(int v) override { msg_id = v; }
    virtual void SetRawId(int v) override { raw_id = v; }
    virtual void SetXAEntry(int v) override { xa_entry = v; }
    virtual void SetXAExit(int v) override { xa_exit = v; }
    virtual void SetStatus(int v) override { xe_status = v; }
    virtual void SetStatusMsg(string v) override { xe_status_msg = v; }
    virtual void SetTime(string v) override { time = v; }
    virtual void SetSymbol(string v) override { symbol = v; }
    virtual void SetDir(int v) override { dir = v; }
    virtual void SetType(int v) override { type = v; }
    virtual void SetPriceSignal(double v) override { price_signal = v; }
    virtual void SetTEStart(double v) override { te_start = v; }
    virtual void SetTEStep(double v) override { te_step = v; }
    virtual void SetTELimit(double v) override { te_limit = v; }
    virtual void SetTEInterval(int v) override { te_interval = v; }
    virtual void SetIkTeStart(double v) override { ikte_start = v; }
    virtual void SetIkTeStep(double v) override { ikte_step = v; }
    virtual void SetTP(double v) override { tp = v; }
    virtual void SetSL(double v) override { sl = v; }
    virtual void SetTSStart(int v) override { ts_start = v; }
    virtual void SetTSStep(int v) override { ts_step = v; }
    virtual void SetCloseType(int v) override { close_type = v; }
    virtual void SetTrailPrice(double v) override { trail_price = v; }
    virtual void SetPriceLimit(double v) override { price_limit = v; }
    virtual void SetPrice(double v) override { price = v; }
    virtual void SetPriceOpen(double v) override { price_open = v; }
    virtual void SetPriceClose(double v) override { price_close = v; }
    virtual void SetPriceTP(double v) override { price_tp = v; }
    virtual void SetPriceSL(double v) override { price_sl = v; }
    virtual void SetLot(double v) override { lot = v; }
    virtual void SetTicket(ulong v) override { ticket = v; }
    virtual void SetMagic(long v) override { magic = v; }
    virtual void SetComment(string v) override { comment = v; }
    virtual void SetTag(string v) override { tag = v; }
    virtual void SetCreated(datetime v) override { created = v; }
    virtual void SetUpdated(datetime v) override { updated = v; }

    //--- [3] 수동 구현이 필요한 특수 로직
    virtual int GetGno() const override {
        string parts[];
        if (StringSplit(sid, '-', parts) >= 4) return (int)StringToInteger(parts[3]);
        return 0;
    }
    
    virtual void   UpdatePriceSignal(double p) override { price_signal = p; }
    virtual double GetOffset() const override { return 0; } 
    virtual double GetStep() const override { return 0; }   
    
    //--- [v11.0] Log Spam Prevention
    virtual int    GetLastStatus() const override { return last_status; }
    virtual void   SetLastStatus(int status) override { last_status = status; }
};

#endif
