#ifndef CXSESSIONMANAGER_MQH
#define CXSESSIONMANAGER_MQH

#include <Arrays\ArrayObj.mqh>
#include "..\..\Core\Interfaces\ICXSessionManager.mqh"
#include "..\..\Core\Macros\CXMacros.mqh"

// [v18.0] State-Pattern Session Headers
#include "..\..\Session\CXSessionEntry.mqh"
#include "..\..\Session\CXSessionPending.mqh"
#include "..\..\Session\CXSessionActive.mqh"
#include "..\..\Session\CXSessionExit.mqh"

/**
 * @class CXSessionManager
 * @brief 신호 상태별 최적화된 세션 생성 및 GC를 담당하는 관리자 (v18.0)
 */
class CXSessionManager : public ICXSessionManager {
private:
    CArrayObj*          m_active;       
    IRepository*        m_globalRepo;
    ICXContext*         m_globalContext;
    ICXServiceFactory*  m_factory;

public:
    CXSessionManager() : m_globalRepo(NULL), m_globalContext(NULL), m_factory(NULL) {
        m_active = new CArrayObj();
    }

    virtual ~CXSessionManager() {
        SAFE_DELETE(m_active);
    }

    virtual void Initialize(IRepository* repo, ICXContext* ctx, ICXServiceFactory* factory) override {
        m_globalRepo = repo;
        m_globalContext = ctx;
        m_factory = factory;
    }

    /**
     * @brief [v18.0] 신호의 현재 상태에 가장 적합한 세션 클래스를 동적으로 생성
     */
    virtual ICXTradingSession* CreateSession(ICXParam* xp) override {
        if(IS_INVALID(m_factory) || IS_INVALID(xp)) return NULL;
        
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig)) return NULL;

        int status = sig.GetStatus();
        ICXTradingSession* session = NULL;

        // 상태별 최적화된 클래스 인스턴스화
        if(status < XE_PENDING_PLACED) {
            session = new CXSessionEntry(m_globalRepo, m_globalContext, m_factory);
        }
        else if(status < XE_EXECUTED) {
            session = new CXSessionPending(m_globalRepo, m_globalContext, m_factory);
        }
        else if(status < XE_CLOSED_SIGNAL) {
            session = new CXSessionActive(m_globalRepo, m_globalContext, m_factory);
        }
        else {
            session = new CXSessionExit(m_globalRepo, m_globalContext, m_factory);
        }

        if(IS_VALID(session)) {
            m_active.Add(session);
            return session;
        }
        return NULL;
    }

    virtual ICXTradingSession* FindSessionBySid(const string sid) override {
        if(sid == "") return NULL;
        for(int i = 0; i < m_active.Total(); i++) {
            ICXTradingSession* session = CX_CAST(ICXTradingSession, m_active.At(i));
            if(IS_VALID(session) && session.GetSid() == sid) return session;
        }
        return NULL;
    }

    virtual void Pulse(ICXParam* xp) override {
        for(int i = 0; i < m_active.Total(); i++) {
            ICXTradingSession* session = CX_CAST(ICXTradingSession, m_active.At(i));
            if(IS_VALID(session)) {
                if(IS_VALID(xp)) xp.Reset();
                session.Pulse(xp);
                
                // [v18.0 Optimization] 여기서 상태 전이에 따른 클래스 교체(Swapping) 로직을 추가할 수 있음
                // 현재는 시퀀스가 단일 세션 객체 내에서 동작하므로, 세션 재기동 시에만 최적화된 클래스가 생성됨.
            }
        }
        PurgeInactive();
    }

private:
    void PurgeInactive() {
        for(int i = m_active.Total() - 1; i >= 0; i--) {
            ICXTradingSession* session = CX_CAST(ICXTradingSession, m_active.At(i));
            if(IS_VALID(session) && !session.IsActive()) {
                m_active.Delete(i);
            }
        }
    }
};

#endif
