#ifndef CXSTEPDISCOVERY_MQH
#define CXSTEPDISCOVERY_MQH

#include "..\..\..\Interfaces\IXStep.mqh"
#include "..\..\..\Interfaces\IRepository.mqh"
#include "..\..\..\Models\CXSignal.mqh"

#include <Arrays\ArrayObj.mqh>

/**
 * @class CXStepDiscovery
 * @brief DB에서 신규 활성 신호를 검색하는 단계 (가변적 로그 억제 포함)
 */
class CXStepDiscovery : public IXStep {
private:
    int      m_noSignalCount;   // 연속 "신호 없음" 카운터
    datetime m_lastLogTime;     // 마지막 로그 출력 시간
    int      m_logInterval;     // 로그 출력 간격 (초)
    bool     m_isPulsed;        // 최초 1회 출력 여부

public:
    CXStepDiscovery() : m_noSignalCount(0), m_lastLogTime(0), m_logInterval(0), m_isPulsed(false) {}
    virtual ~CXStepDiscovery() {}

    virtual string Name() override { return "Step_Discovery"; }

    virtual bool OnCondition(ICXParam* xp, ICXContext* ctx, int current_state) override {
        return true; 
    }

    virtual int OnProcess(ICXParam* xp, ICXContext* ctx) override {
        IRepository* repo = CX_GET_OBJ(ctx, "repo", IRepository);
        ICXLogger* log = CX_GET_OBJ(ctx, "logger", ICXLogger);
        if(IS_INVALID(repo)) return STATE_UNCHANGED;

        if(IS_VALID(log) && !m_isPulsed) {
            log.Trace(xp, "[WATCHER-DISCOVERY] Pulsing...");
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
            if(IS_VALID(log)) log.Info(xp, StringFormat("[WATCHER-DISCOVERY] Found %d active signals (Entry:%d, Exit:%d).", found, entryCount, exitCount));
            ctx.Set("active_signals", activeList);
            return WATCHER_VALIDATION;
        }

        // [v11.0] Suppress "No signal" logs to keep context clean
        SAFE_DELETE(activeList);
        return STATE_UNCHANGED;
    }

    virtual void OnEnter(ICXContext* ctx) override {}
    virtual void OnExit(ICXContext* ctx) override {}
};

#endif
