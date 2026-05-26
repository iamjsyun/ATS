#ifndef CXSTEPENTRYDISCOVERY_MQH
#define CXSTEPENTRYDISCOVERY_MQH

#include "..\..\Platform\Core\Interfaces\IXStep.mqh"
#include "..\..\Platform\Core\Interfaces\IRepository.mqh"
#include "..\..\Platform\Core\Models\CXSignal.mqh"
#include "..\..\Platform\Core\Macros\CXMacros.mqh"
#include "..\..\Platform\Core\Sequence\CXSequenceOrchestrator.mqh"

#include <Arrays\ArrayObj.mqh>

/**
 * @class CXStepEntryDiscovery
 * @brief DB에서 신규 진입 신호(xa_entry=1, xe_status < 10)를 검색하는 단계
 */
class CXStepEntryDiscovery : public IXStep {
private:
    bool     m_isPulsed;

public:
    CXStepEntryDiscovery() : m_isPulsed(false) {}
    virtual ~CXStepEntryDiscovery() {}

    virtual string Name() override { return "Step_EntryDiscovery"; }

    virtual bool OnCondition(ICXParam* xp, ICXContext* ctx, int current_state) override {
        return true; 
    }

    virtual int OnProcess(ICXParam* xp, ICXContext* ctx) override {
        IRepository* repo = CX_GET_OBJ(ctx, "repo", IRepository);
        if(IS_INVALID(repo)) return STATE_UNCHANGED;

        CArrayObj* activeList = new CArrayObj();
        
        int found = repo.LoadEntrySignals(activeList);
        if(found > 0) {
            XP_LOG_OK(xp, StringFormat("[WATCHER-ENTRY-DISCOVERY] Found %d active entry signals", found));
            ctx.Set("entry_signals", activeList);
            
            CXSequenceOrchestrator* orchestrator = CX_GET_OBJ(ctx, "orchestrator", CXSequenceOrchestrator);
            if(IS_VALID(orchestrator)) {
                return orchestrator.ResolveId("WATCHER_ENTRY_EXECUTE");
            }
        }

        SAFE_DELETE(activeList);
        return STATE_UNCHANGED;
    }

    virtual void OnEnter(ICXContext* ctx) override {}
    virtual void OnExit(ICXContext* ctx) override {}
};

#endif
