#ifndef CXCONTEXT_MQH
#define CXCONTEXT_MQH

#include "..\Interfaces\ICXContext.mqh"
#include <Generic\HashMap.mqh>

/**
 * @class CXContext
 * @brief 계층 구조(Tree) 및 스냅샷(Snapshot)을 지원하는 시스템 컨텍스트
 */
class CXContext : public ICXContext {
private:
    string                      m_name;
    ICXParam*                   m_param;
    CHashMap<string, CObject*>  m_resources;
    CHashMap<string, ICXContext*> m_children;

public:
    CXContext(string name = "Global") : m_name(name), m_param(NULL) {}
    
    ~CXContext() { 
        m_resources.Clear(); 
        m_children.Clear(); 
        SAFE_DELETE(m_param);
    }

    virtual string GetName() const override { return m_name; }

    virtual ICXParam* GetParam() override { return m_param; }
    virtual void SetParam(ICXParam* p) override { m_param = p; }

    virtual void Set(string key, CObject* obj) override {
        if(m_resources.ContainsKey(key)) m_resources.Remove(key);
        m_resources.Add(key, obj);
    }

    virtual void Register(string key, CObject* obj) override {
        Set(key, obj);
    }

    virtual CObject* Get(string key) override {
        CObject* obj = NULL;
        if(m_resources.TryGetValue(key, obj)) return obj;
        return NULL;
    }

    //--- Hierarchy Support
    virtual void AddChild(string name, ICXContext* child) override {
        if(m_children.ContainsKey(name)) m_children.Remove(name);
        if(IS_VALID(child)) m_children.Add(name, child);
    }

    virtual ICXContext* GetChild(string name) override {
        ICXContext* child = NULL;
        m_children.TryGetValue(name, child);
        return child;
    }

    //--- [SSOC] Recursive Observability
    virtual string Snapshot(int indent = 0) override {
        string spc = ""; for(int i=0; i<indent; i++) spc += "  ";
        string out = StringFormat("%s{ \"name\": \"%s\",\n", spc, m_name);
        
        // 1. Resources (Keys only for privacy/size)
        out += StringFormat("%s  \"resources\": [", spc);
        string r_keys[]; CObject* r_vals[];
        m_resources.CopyTo(r_keys, r_vals);
        for(int i=0; i<ArraySize(r_keys); i++) {
            out += (i==0 ? "\"" : ", \"") + r_keys[i] + "\"";
        }
        out += "],\n";

        // 2. Children (Recursive)
        out += StringFormat("%s  \"children\": [\n", spc);
        string c_keys[]; ICXContext* c_vals[];
        m_children.CopyTo(c_keys, c_vals);
        for(int i=0; i<ArraySize(c_keys); i++) {
            if(IS_VALID(c_vals[i])) {
                out += c_vals[i].Snapshot(indent + 2);
                if(i < ArraySize(c_keys) - 1) out += ",\n";
                else out += "\n";
            }
        }
        out += StringFormat("%s  ]\n%s}", spc, spc);
        return out;
    }
};

#endif
