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

    //--- [2] 인터페이스 접근자 자동 구현
    #define X(type, name, dbType, getter) \
        virtual type Get##getter() const override { return name; } \
        virtual void Set##getter(type v) override { name = v; }
    SIGNAL_SCHEMA_FIELDS
    #undef X

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
