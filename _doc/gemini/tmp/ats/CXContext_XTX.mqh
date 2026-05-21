//+------------------------------------------------------------------+
//|                                                     CXContext.mqh |
//|                                  Copyright 2026, Gemini CLI      |
//| [Fluent Xequence] Universal Context with Service Locator Pattern |
//+------------------------------------------------------------------+
#ifndef CX_CONTEXT_MQH
#define CX_CONTEXT_MQH

#include <Object.mqh>
#include <Generic\HashMap.mqh>

/**
 * @class CXContext
 * @brief 시퀀스 단계 간 리소스 공유를 위한 Service Locator 클래스
 */
class CXContext : public CObject {
private:
    CHashMap<string, CObject*> m_resources;

public:
    CXContext() {}
    ~CXContext() { m_resources.Clear(); }

    /**
     * @brief 리소스 등록
     */
    void Set(string key, CObject* obj) {
        if(m_resources.ContainsKey(key)) m_resources.Remove(key);
        m_resources.Add(key, obj);
    }

    /**
     * @brief 리소스 획득
     */
    CObject* Get(string key) {
        CObject* obj = NULL;
        m_resources.TryGetValue(key, obj);
        return obj;
    }

    virtual void Reset() {
        m_resources.Clear();
    } 
};

#endif
