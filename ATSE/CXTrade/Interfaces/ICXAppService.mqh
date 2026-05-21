#ifndef ICXAPPSERVICE_MQH
#define ICXAPPSERVICE_MQH

#include <Object.mqh>
#include "CXDefine.mqh"

class ICXAppService : public CObject {
public:
    virtual ~ICXAppService() {}

    /**
     * @brief Two-phase Initialization (Detect internal failures)
     */
    virtual bool Initialize(int poolSize = 50) = 0;
    virtual void Pulse() = 0;
    virtual void Pulse(ENUM_CX_EVENT event) = 0;
    virtual void OnTradeTransaction(const MqlTradeTransaction& trans,
                                    const MqlTradeRequest& request,
                                    const MqlTradeResult& result) = 0;
};

#endif
