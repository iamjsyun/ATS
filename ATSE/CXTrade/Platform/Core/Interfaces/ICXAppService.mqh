#ifndef ICXAPPSERVICE_MQH
#define ICXAPPSERVICE_MQH

#include <Object.mqh>
#include "..\Defines\CXDefine.mqh"
#include "ICXConfig.mqh"
#include "ICXServiceFactory.mqh"

class ICXAppService : public CObject {
public:
    virtual ~ICXAppService() {}

    /**
     * @brief Two-phase Initialization (Detect internal failures)
     */
    virtual bool Initialize(ICXConfig* config, ICXServiceFactory* factory) = 0;
    virtual void Pulse() = 0;
    virtual void OnTradeTransaction(const MqlTradeTransaction& trans,
                                    const MqlTradeRequest& request,
                                    const MqlTradeResult& result) = 0;
};

#endif
