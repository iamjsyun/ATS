#ifndef IREPOSITORY_MQH
#define IREPOSITORY_MQH

#include <Object.mqh>
#include <Arrays\ArrayObj.mqh>
#include "ICXSignal.mqh"
#include "ICXParam.mqh"

class IRepository : public CObject {
public:
    virtual ~IRepository() {}
    virtual void SaveSignal(ICXSignal* signal) = 0;
    virtual void LoadParam(ICXParam* param) = 0;
    virtual int  GetStatusBySid(const string sid) = 0;
    virtual bool UpdateStatus(ICXSignal* signal) = 0;
    virtual int  LoadActiveSignals(CArrayObj* list) = 0;
    virtual ICXSignal* GetSignalBySid(const string sid) = 0;
    virtual bool DeleteBySid(const string sid) = 0;
    virtual ICXSignal* GetSignalByCnoSno(int cno, int sno, string symbol) = 0;
};

#endif
