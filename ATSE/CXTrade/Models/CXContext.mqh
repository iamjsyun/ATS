#ifndef CXCONTEXT_MQH
#define CXCONTEXT_MQH

#include "..\Interfaces\ICXContext.mqh"
#include <Generic\HashMap.mqh>

class CXContext : public ICXContext {
private:
    ICXParam*                   m_param;
    CHashMap<string, CObject*>  m_resources;

public:
    CXContext() : m_param(NULL) {}
    ~CXContext() { 
        m_resources.Clear(); 
        SAFE_DELETE(m_param);
    }

    virtual ICXParam* GetParam() override { return m_param; }
    void SetParam(ICXParam* p) { m_param = p; }

    virtual void Set(string key, CObject* obj) override {
        if(m_resources.ContainsKey(key)) m_resources.Remove(key);
        m_resources.Add(key, obj);
    }

    virtual void Register(string key, CObject* obj) override {
        Set(key, obj);
    }

    virtual CObject* Get(string key) override {
        CObject* obj = NULL;
        m_resources.TryGetValue(key, obj);
        return obj;
    }
};

#endif


