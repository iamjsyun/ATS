#ifndef CXSESSIONMANAGER_MQH
#define CXSESSIONMANAGER_MQH

#include <Arrays\ArrayObj.mqh>
#include "..\Platform\Core\Interfaces\ICXSessionManager.mqh"
#include "..\Platform\Core\Macros\CXMacros.mqh"

// [v18.6] State-Pattern Session Headers (Hyper-Atomic)
#include "CXSessionEntry.mqh"
#include "CXSessionPending.mqh"
#include "CXSessionTrailingEntry.mqh"
#include "CXSessionPositioned.mqh"
#include "CXSessionExit.mqh"

/**
 * @class CXSessionManager
 * @brief 신호 상태별 최적화된 세션 생성 및 GC를 담당하는 관리자 (v18.6)
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
     * @brief [v18.6] 신호의 현재 상태에 가장 적합한 세션 클래스를 동적으로 생성
     */
    virtual ICXTradingSession* CreateSession(ICXParam* xp) override {
        if(IS_INVALID(m_factory) || IS_INVALID(xp)) return NULL;
        
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig)) return NULL;

        int status = sig.GetStatus();
        ICXTradingSession* session = NULL;

        // [v18.6 Refinement] 물리적 자산 상태에 따른 정밀 매핑
        if(status < XE_PENDING_PLACED) {
            session = new CXSessionEntry(m_globalRepo, m_globalContext, m_factory);
        }
        else if(status == XE_PENDING_PLACED) {
            // 터미널 오더는 있으나 아직 추격을 시작하지 않은 '접수' 상태
            session = new CXSessionPending(m_globalRepo, m_globalContext, m_factory);
        }
        else if(status < XE_EXECUTED) {
            // 적극적으로 가격을 추격 중인 상태
            session = new CXSessionTrailingEntry(m_globalRepo, m_globalContext, m_factory);
        }
        else if(status < XE_CLOSED_SIGNAL) {
            // 체결 완료되어 포지션을 보유 중인 상태
            session = new CXSessionPositioned(m_globalRepo, m_globalContext, m_factory);
        }
        else {
            // 청산 절차 진행 중
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
        string trimmed = sid; StringTrimLeft(trimmed); StringTrimRight(trimmed);
        for(int i = 0; i < m_active.Total(); i++) {
            ICXTradingSession* session = CX_CAST(ICXTradingSession, m_active.At(i));
            if(IS_VALID(session) && session.GetSid() == trimmed) return session;
        }
        return NULL;
    }

    /**
     * @brief [v18.15] SID 또는 (CNO+SNO) 조합으로 활성 세션을 검색
     */
    ICXTradingSession* FindSessionByIdentity(ICXSignal* sig) {
        if(IS_INVALID(sig)) return NULL;
        
        string sid = sig.GetSid(); StringTrimLeft(sid); StringTrimRight(sid);
        int cno = sig.GetCno();
        int sno = sig.GetSno();

        for(int i = 0; i < m_active.Total(); i++) {
            ICXTradingSession* session = CX_CAST(ICXTradingSession, m_active.At(i));
            if(!IS_VALID(session)) continue;

            // 1. SID 일치 확인
            if(sid != "" && session.GetSid() == sid) return session;

            // 2. CNO+SNO 일치 확인 (SID가 없거나 바뀐 경우 대비)
            ICXSignal* s_sig = session.GetSignal();
            if(IS_VALID(s_sig)) {
                if(s_sig.GetCno() == cno && s_sig.GetSno() == sno) return session;
            }
        }
        return NULL;
    }

    virtual void Pulse(ICXParam* xp) override {
        for(int i = 0; i < m_active.Total(); i++) {
            ICXTradingSession* session = CX_CAST(ICXTradingSession, m_active.At(i));
            if(IS_VALID(session)) {
                if(IS_VALID(xp)) xp.Reset();
                session.Pulse(xp);
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
