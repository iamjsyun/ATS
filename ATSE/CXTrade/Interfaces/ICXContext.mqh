#ifndef ICXCONTEXT_MQH
#define ICXCONTEXT_MQH

#include <Object.mqh>

class ICXParam;

class ICXContext : public CObject {
public:
    virtual ~ICXContext() {}
    virtual ICXParam* GetParam() = 0;
    virtual void      SetParam(ICXParam* p) = 0;
    virtual void      Set(string key, CObject* obj) = 0;
    virtual void      Register(string key, CObject* obj) = 0;
    virtual CObject*  Get(string key) = 0;
};

#endif
