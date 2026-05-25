#ifndef CXSESSIONMANAGER_MQH
#define CXSESSIONMANAGER_MQH

#include <Arrays\ArrayObj.mqh>
#include "..\..\Session\CXTradingSession.mqh"
#include "..\..\Core\Interfaces\ICXSessionManager.mqh"
#include "..\..\Core\Macros\CXMacros.mqh"

/**
 * @class CXSessionManager
 * @brief 신호별 동적 세션 생성 및 GC(Garbage Collection)를 담당하는 관리자 (v14.47)
 */
class CXSessionManager : public ICXSessionManager {
private:
    CArrayObj*          m_active;       // 현재 가동 중인 세션 리스트
    IRepository*        m_globalRepo;
    ICXContext*         m_globalContext;
    ICXServiceFactory*  m_factory;

public:
    CXSessionManager() : m_globalRepo(NULL), m_globalContext(NULL), m_factory(NULL) {
        m_active = new CArrayObj();
    }

    virtual ~CXSessionManager() {
        // 모든 활성 세션 강제 파괴 및 메모리 해제
        SAFE_DELETE(m_active);
    }

    /**
     * @brief 실행 환경 참조 저장
     */
    virtual void Initialize(IRepository* repo, ICXContext* ctx, ICXServiceFactory* factory) override {
        m_globalRepo = repo;
        m_globalContext = ctx;
        m_factory = factory;
    }

    /**
     * @brief 신규 세션 동적 생성 (v15.9 Param-injected)
     */
    virtual ICXTradingSession* CreateSession(ICXParam* xp) override {
        if(IS_INVALID(m_factory)) return NULL;
        
        // 매번 새로운 인스턴스 생성 (상태 오염 방지)
        CXTradingSession* session = new CXTradingSession(m_globalRepo, m_globalContext, m_factory);
        if(IS_VALID(session)) {
            m_active.Add(session);
            return session;
        }
        return NULL;
    }

    /**
     * @brief SID로 활성 세션 검색
     */
    virtual ICXTradingSession* FindSessionBySid(const string sid) override {
        if(sid == "") return NULL;
        for(int i = 0; i < m_active.Total(); i++) {
            ICXTradingSession* session = CX_CAST(ICXTradingSession, m_active.At(i));
            if(IS_VALID(session) && session.GetSid() == sid) return session;
        }
        return NULL;
    }

    /**
     * @brief 활성 세션 실행 및 가비지 컬렉션(GC)
     */
    virtual void Pulse(ICXParam* xp) override {
        for(int i = 0; i < m_active.Total(); i++) {
            ICXTradingSession* session = CX_CAST(ICXTradingSession, m_active.At(i));
            if(IS_VALID(session)) {
                if(IS_VALID(xp)) xp.Reset();
                session.Pulse(xp);
            }
        }
        
        // 종료된 세션 인스턴스 파괴 (GC)
        PurgeInactive();
    }

private:
    /**
     * @brief 비활성화된 세션을 리스트에서 제거하고 메모리 해제
     */
    void PurgeInactive() {
        for(int i = m_active.Total() - 1; i >= 0; i--) {
            ICXTradingSession* session = CX_CAST(ICXTradingSession, m_active.At(i));
            if(IS_VALID(session) && !session.IsActive()) {
                // CArrayObj::Delete(i)가 포인터의 delete를 자동으로 수행함
                m_active.Delete(i);
            }
        }
    }
};

#endif
