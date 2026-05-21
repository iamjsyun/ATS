#ifndef CXSTEPBINDING_MQH
#define CXSTEPBINDING_MQH

#include "..\..\..\Interfaces\IXStep.mqh"
#include "..\..\..\Interfaces\ICXTradingSessionPool.mqh"
#include "..\..\..\Interfaces\ICXTradingSession.mqh"
#include "..\..\..\Models\CXSignal.mqh"
#include "..\..\..\Models\CXParam.mqh"
#include "..\..\CXLogDispatcher.mqh"
#include <Arrays\ArrayObj.mqh>

/**
 * @class CXStepBinding
 * @brief 검증된 신호를 SessionPool에서 세션에 할당하고 기동하는 단계
 */
class CXStepBinding : public IXStep {
public:
    CXStepBinding() {}
    virtual ~CXStepBinding() {}

    virtual string Name() override { return "Step_Binding"; }

    virtual bool OnCondition(ICXParam* xp, ICXContext* ctx, int current_state) override {
        CArrayObj* activeList = CX_GET_OBJ(ctx, "active_signals", CArrayObj);
        return (IS_VALID(activeList) && activeList.Total() > 0);
    }

    virtual int OnProcess(ICXParam* xp, ICXContext* ctx) override {
        CArrayObj* activeList = CX_GET_OBJ(ctx, "active_signals", CArrayObj);
        ICXTradingSessionPool* pool = CX_GET_OBJ(ctx, "session_pool", ICXTradingSessionPool);
        ICXLogger* log = CX_GET_OBJ(ctx, "logger", ICXLogger);

        if(IS_INVALID(activeList) || IS_INVALID(pool)) return WATCHER_DISCOVERY;

        int total = activeList.Total();
        int success = 0;
        int skipped = 0;
        int failed = 0;

        for(int i = 0; i < total; i++) {
            ICXSignal* sig = CX_CAST(ICXSignal, activeList.At(i));
            if(IS_INVALID(sig)) continue;

            string sid = sig.GetSid();

            //-- 0. 중복 바인딩 방지
            ICXTradingSession* existing = pool.FindSessionBySid(sid);
            if(IS_VALID(existing)) {
                if(IS_VALID(log)) log.Debug(xp, StringFormat("[WATCHER-BINDING] SKIP: SID:%s is already active.", sid));
                skipped++;
                SAFE_DELETE(sig); //-- [v10.7 Fix] Delete orphan signal object
                continue;
            }

            //-- 1. 세션 풀에서 세션 대여
            ICXTradingSession* session = pool.BorrowSession();
            if(IS_VALID(session)) {
                //-- 2. 세션 기동 및 신호 주입 (Ownership transfer to Session)
                CXParam sp;
                sp.SetSignal(sig);
                session.Start(GetPointer(sp));

                if(IS_VALID(log)) log.Ok(xp, StringFormat("[WATCHER-BINDING] SUCCESS: SID:%s bound to session.", sid));
                success++;
            } else {
                if(IS_VALID(log)) log.Error(xp, StringFormat("[WATCHER-BINDING] FAILED: No idle session for SID:%s", sid));
                failed++;
                SAFE_DELETE(sig); //-- [v10.7 Fix] Delete orphan signal object
            }
        }

        if(total > 0) {
            if(IS_VALID(log)) log.Info(xp, StringFormat("[WATCHER-BINDING] Complete. Success: %d, Skipped: %d, Failed: %d", success, skipped, failed));
        }

        // 3. 작업 완료 후 리스트 정리
        while(activeList.Total() > 0) activeList.Detach(0); 

        return WATCHER_DISCOVERY;
    }

    virtual void OnEnter(ICXContext* ctx) override {}
    virtual void OnExit(ICXContext* ctx) override {}
};

#endif
