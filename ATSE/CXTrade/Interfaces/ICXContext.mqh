#ifndef ICXCONTEXT_MQH
#define ICXCONTEXT_MQH

#include <Object.mqh>

#include <Arrays\ArrayObj.mqh>

class ICXParam;

class ICXContext : public CObject {
public:
    virtual ~ICXContext() {}
    virtual ICXParam* GetParam() = 0;
    virtual void      SetParam(ICXParam* p) = 0;
    virtual void      Set(string key, CObject* obj) = 0;
    virtual void      Register(string key, CObject* obj) = 0;
    virtual CObject*  Get(string key) = 0;
    
    //--- Hierarchy & Observability
    virtual void      AddChild(string name, ICXContext* child) = 0;
    virtual ICXContext* GetChild(string name) = 0;
    virtual string    GetName() const = 0;
    virtual string    Snapshot(int indent = 0) = 0;
};

#endif
