#ifndef CXPAYLOADER_MQH
#define CXPAYLOADER_MQH

#include "CXParam.mqh"

/**
 * @class CXPayloader
 * @brief CXParam에 Fluent API(Chaining)를 추가한 확장 클래스
 */
class CXPayloader : public CXParam {
public:
    CXPayloader() {}
    virtual ~CXPayloader() {}

    //-- Fluent Interface 방식의 Setter (Chaining 지원)
    CXPayloader* WithSignal(ICXSignal* sig) { SetSignal(sig); return GetPointer(this); }
    CXPayloader* WithInt(int val)          { SetInt(val);    return GetPointer(this); }
    CXPayloader* WithString(string str)    { SetString(str); return GetPointer(this); }
    CXPayloader* WithContext(ICXContext* ctx) { SetContext(ctx); return GetPointer(this); }
};

#endif
