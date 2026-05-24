#ifndef CXTRADINGSESSIONPOOL_MQH
#define CXTRADINGSESSIONPOOL_MQH

#include <Arrays\ArrayObj.mqh>
#include "..\Session\CXTradingSession.mqh"
#include "..\Interfaces\ICXTradingSessionPool.mqh"

/**
 * @class CXTradingSessionPool
 * @brief Sandboxed 세션들을 미리 생성하고 관리하는 풀 클래스
 */
class CXTradingSessionPool : public ICXTradingSessionPool {
private:
    CArrayObj     m_pool;      // 사용 가능한 유휴 세션 풀
    CArrayObj     m_active;    // 현재 사용 중인 세션 리스트
    int           m_initialCount;

public:
    CXTradingSessionPool(int count) : m_initialCount(count) {}
    virtual ~CXTradingSessionPool() {
        m_pool.Clear();
        m_active.Clear();
    }

    /**
     * @brief EA 초기화 시 지정된 개수만큼 샌드박스 세션 미리 생성 (Warm-up)
     */
    virtual void Initialize(IRepository* globalRepo, ICXContext* globalContext, ICXServiceFactory* factory) override {
        for(int i = 0; i < m_initialCount; i++) {
            // 각 세션은 고유의 자원(DB, Log 등)을 가질 수 있도록 리포지토리와 팩토리를 통해 생성
            CXTradingSession* session = new CXTradingSession(globalRepo, globalContext, factory);
            if(IS_VALID(session)) {
                m_pool.Add(session);
            }
        }
    }

    /**
     * @brief 풀에서 유휴 세션 획득 (Borrow)
     */
    virtual ICXTradingSession* BorrowSession() override {
        if(m_pool.Total() <= 0) return NULL; // 또는 추가 생성 로직
        
        ICXTradingSession* session = CX_CAST(ICXTradingSession, m_pool.Detach(0));
        m_active.Add(session);
        return session;
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
     * @brief 사용이 끝난 세션을 풀로 반환 (Return)
     */
    virtual void ReturnSession(ICXTradingSession* session) override {
        for(int i = 0; i < m_active.Total(); i++) {
            if(m_active.At(i) == session) {
                m_active.Detach(i);
                session.Reset(); // 상태 초기화 후 반환
                m_pool.Add(session);
                break;
            }
        }
    }

    /**
     * @brief 활성 세션들에 대해 주기적 로직(Pulse) 실행
     */
    virtual void Pulse(ICXParam* xp) override {
        for(int i = 0; i < m_active.Total(); i++) {
            ICXTradingSession* session = CX_CAST(ICXTradingSession, m_active.At(i));
            if(IS_VALID(session)) {
                // [v14.12 Anti-Crosstalk] Reset shared param before each session pulse
                if(IS_VALID(xp)) xp.Reset();
                session.Pulse(xp);
            }
        }
        PurgeClosed();
    }

    /**
     * @brief 종료된 세션을 감지하여 풀로 반환
     */
    void PurgeClosed() {
        for(int i = m_active.Total() - 1; i >= 0; i--) {
            ICXTradingSession* session = CX_CAST(ICXTradingSession, m_active.At(i));
            if(IS_VALID(session) && !session.IsActive()) {
                ReturnSession(session);
            }
        }
    }
};

#endif
