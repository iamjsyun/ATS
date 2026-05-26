#ifndef CXSTEPDISCOVERY_MQH
#define CXSTEPDISCOVERY_MQH

#include "..\..\Platform\Core\Interfaces\IXStep.mqh"
#include "..\..\Platform\Core\Interfaces\IRepository.mqh"
#include "..\..\Platform\Core\Models\CXSignal.mqh"
#include "..\..\Platform\Core\Macros\CXMacros.mqh"

#include <Arrays\ArrayObj.mqh>

/**
 * @class CXStepDiscovery
 * @brief DB에서 신규 활성 신호를 검색하는 단계 (가변적 로그 억제 포함)
 */
class CXStepDiscovery : public IXStep {
private:
    bool     m_isPulsed;        // 최초 1회 출력 여부

public:
    CXStepDiscovery() : m_isPulsed(false) {}
    virtual ~CXStepDiscovery() {}

    virtual string Name() override { return "Step_Discovery"; }

    virtual bool OnCondition(ICXParam* xp, ICXContext* ctx, int current_state) override {
        return true; 
    }

    virtual int OnProcess(ICXParam* xp, ICXContext* ctx) override {
        IRepository* repo = CX_GET_OBJ(ctx, "repo", IRepository);
        if(IS_INVALID(repo)) return STATE_UNCHANGED;

        if(!m_isPulsed) {
            m_isPulsed = true;
        }

        CArrayObj* activeList = new CArrayObj();
        
        int found = repo.LoadActiveSignals(activeList);
        if(found > 0) {
            int entryCount = 0;
            int exitCount = 0;
            for(int i = 0; i < activeList.Total(); i++) {
                ICXSignal* sig = CX_CAST(ICXSignal, activeList.At(i));
                if(IS_VALID(sig)) {
                    if(sig.GetXAEntry() == XA_ACTIVE) entryCount++;
                    if(sig.GetXAExit() == XA_ACTIVE)  exitCount++;
                }
            }
            XP_LOG_OK(xp, StringFormat("[WATCHER-DISCOVERY] Found %d active signals (Entry:%d, Exit:%d)", found, entryCount, exitCount));
            ctx.Set("active_signals", activeList);
            return WATCHER_VALIDATION;
        }

        // Suppress "No signal" logs to keep context clean
        SAFE_DELETE(activeList);
        return STATE_UNCHANGED;
    }

    virtual void OnEnter(ICXContext* ctx) override {}
    virtual void OnExit(ICXContext* ctx) override {}
};

#endif
