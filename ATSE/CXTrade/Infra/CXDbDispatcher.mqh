#ifndef CXDBDISPATCHER_MQH
#define CXDBDISPATCHER_MQH

#include <Arrays\ArrayObj.mqh>
#include "..\Interfaces\IRepository.mqh"
#include "..\Interfaces\ICXSignal.mqh"
#include "..\Models\CXSignal.mqh"

/**
 * @class CXDbRequest
 * @brief 비동기 처리를 위한 DB 요청 엔티티
 */
class CXDbRequest : public CObject {
public:
    ICXSignal* signal;
    bool       isStatusOnly;
    
    CXDbRequest(ICXSignal* sig, bool statusOnly) : isStatusOnly(statusOnly) {
        signal = new CXSignal();
        // Deep copy of relevant fields for thread-safe-like consistency
        CX_CAST(CXSignal, signal).id = sig.GetId();
        CX_CAST(CXSignal, signal).sid = sig.GetSid();
        CX_CAST(CXSignal, signal).xe_status = sig.GetStatus();
        CX_CAST(CXSignal, signal).xe_status_msg = sig.GetStatusMsg();
        // Add more fields if full save is needed
    }
    
    ~CXDbRequest() { SAFE_DELETE(signal); }
};

/**
 * @class CXDbDispatcher
 * @brief [Refinement 3] Queue-based Non-blocking DB Dispatcher
 */
class CXDbDispatcher : public CObject {
private:
    IRepository* m_repo;
    CArrayObj    m_queue;
    int          m_maxBatch;

public:
    CXDbDispatcher(IRepository* repo, int maxBatch = 5) 
        : m_repo(repo), m_maxBatch(maxBatch) {}

    /**
     * @brief 요청 큐에 삽입 (Non-blocking)
     */
    void Enqueue(ICXSignal* sig, bool statusOnly = true) {
        if(IS_INVALID(sig)) return;
        m_queue.Add(new CXDbRequest(sig, statusOnly));
    }

    /**
     * @brief 메인 루프에서 호출되어 큐를 소비
     */
    void Dispatch() {
        if(m_queue.Total() <= 0) return;

        int processed = 0;
        while(m_queue.Total() > 0 && processed < m_maxBatch) {
            CXDbRequest* req = CX_CAST(CXDbRequest, m_queue.Detach(0));
            if(IS_VALID(req)) {
                if(req.isStatusOnly) m_repo.UpdateStatus(req.signal);
                else                 m_repo.SaveSignal(req.signal);
            }
            SAFE_DELETE(req);
            processed++;
        }
    }
    
    int QueueSize() const { return m_queue.Total(); }
};

#endif
