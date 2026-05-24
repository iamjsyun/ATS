#ifndef CXSTEPBINDING_MQH
#define CXSTEPBINDING_MQH

#include "..\..\..\Interfaces\IXStep.mqh"
#include "..\..\..\Interfaces\ICXTradingSessionPool.mqh"
#include "..\..\..\Interfaces\ICXTradingSession.mqh"
#include "..\..\..\Models\CXSignal.mqh"
#include "..\..\..\Models\CXParam.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"
#include "..\..\..\Infra\CXAuditFormatter.mqh"
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

        if(IS_INVALID(activeList) || IS_INVALID(pool)) return WATCHER_DISCOVERY;

        int total = activeList.Total();
        int success = 0;
        int skipped = 0;
        int failed = 0;

        for(int i = 0; i < total; i++) {
            ICXSignal* sig = CX_CAST(ICXSignal, activeList.At(i));
            if(IS_INVALID(sig)) continue;

            xp.SetSignal(sig); // UAF 조립을 위해 임시 바인딩
            string sid = sig.GetSid();

            //-- 0. 중복 바인딩 방지 및 강제 개입 로직 (v14.3)
            ICXTradingSession* existing = pool.FindSessionBySid(sid);
            if(IS_VALID(existing)) {
                if(sig.GetXAExit() == XA_ACTIVE) {
                    XP_LOG_WARN(xp, CXAuditFormatter::Build("WATCHER-BINDING", xp, "INTERRUPT: SID is active. Forcing Liquidation."));
                    existing.ForceTransition(SESSION_LIQUIDATING);
                    
                    IRepository* repo = CX_GET_OBJ(ctx, "repo", IRepository);
                    if(IS_VALID(repo)) {
                        sig.SetStatus(XE_CLOSED_SIGNAL); 
                        sig.SetStatusMsg("Liquidation Forced by Watcher");
                        repo.UpdateStatus(sig);
                    }
                    skipped++;
                } else {
                    XP_LOG_TRACE(xp, CXAuditFormatter::Build("WATCHER-BINDING", xp, "SKIP: SID is already active."));
                    skipped++;
                }
                SAFE_DELETE(sig); 
                continue;
            }

            //-- 1. 세션 풀에서 세션 대여
            ICXTradingSession* session = pool.BorrowSession();
            if(IS_VALID(session)) {
                // [v13.3 Atomic Binding] 세션 기동 전 DB 상태 선제 잠금
                IRepository* repo = CX_GET_OBJ(ctx, "repo", IRepository);
                if(IS_VALID(repo)) {
                    sig.SetStatus(XE_PENDING_REQ);
                    sig.SetStatusMsg("Session Bound (Pre-lock)");
                    repo.UpdateStatus(sig);
                }

                //-- 2. 세션 기동 및 신호 주입
                CXParam sp;
                sp.SetSignal(sig);
                session.Start(GetPointer(sp));

                XP_LOG_OK(xp, CXAuditFormatter::Build("WATCHER-BINDING", xp, "SUCCESS: Bound to session."));
                success++;
            } else {
                XP_LOG_ERROR(xp, CXAuditFormatter::Build("WATCHER-BINDING", xp, "FAILED: No idle session available."));
                failed++;
                SAFE_DELETE(sig); 
            }
        }

        if(total > 0) {
            XP_LOG_TRACE(xp, StringFormat("[WATCHER-BINDING] Complete. Total:%d, Success:%d, Skipped:%d, Failed:%d", total, success, skipped, failed));
        }

        // 3. 작업 완료 후 리스트 정리
        while(activeList.Total() > 0) activeList.Detach(0); 

        return WATCHER_DISCOVERY;
    }

    virtual void OnEnter(ICXContext* ctx) override {}
    virtual void OnExit(ICXContext* ctx) override {}
};

#endif
