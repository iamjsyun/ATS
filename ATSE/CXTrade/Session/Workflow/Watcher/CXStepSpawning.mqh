#ifndef CXSTEPSPAWNING_MQH
#define CXSTEPSPAWNING_MQH

#include "..\..\..\Core\Interfaces\IXStep.mqh"
#include "..\..\..\Core\Interfaces\ICXSessionManager.mqh"
#include "..\..\..\Core\Interfaces\ICXTradingSession.mqh"
#include "..\..\..\Core\Models\CXSignal.mqh"
#include "..\..\..\Core\Models\CXParam.mqh"
#include "..\..\..\Core\Macros\CXMacros.mqh"
#include "..\..\..\Shared\Logging\CXAuditFormatter.mqh"
#include <Arrays\ArrayObj.mqh>

/**
 * @class CXStepSpawning
 * @brief [v14.47] 검증된 신호를 바탕으로 독립적인 트레이딩 세션을 동적으로 생성(Spawn)하고 기동하는 단계
 */
class CXStepSpawning : public IXStep {
public:
    CXStepSpawning() {}
    virtual ~CXStepSpawning() {}

    virtual string Name() override { return "Step_Spawning"; }

    virtual bool OnCondition(ICXParam* xp, ICXContext* ctx, int current_state) override {
        CArrayObj* activeList = CX_GET_OBJ(ctx, "active_signals", CArrayObj);
        return (IS_VALID(activeList) && activeList.Total() > 0);
    }

    virtual int OnProcess(ICXParam* xp, ICXContext* ctx) override {
        CArrayObj* activeList = CX_GET_OBJ(ctx, "active_signals", CArrayObj);
        ICXSessionManager* session_mgr = CX_GET_OBJ(ctx, "session_mgr", ICXSessionManager);

        if(IS_INVALID(activeList) || IS_INVALID(session_mgr)) return WATCHER_DISCOVERY;

        int total = activeList.Total();
        int success = 0;
        int skipped = 0;
        int failed = 0;

        for(int i = 0; i < total; i++) {
            ICXSignal* sig = CX_CAST(ICXSignal, activeList.At(i));
            if(IS_INVALID(sig)) continue;

            xp.SetSignal(sig); 
            string sid = sig.GetSid();

            //-- 0. 중복 생성 방지 (이미 실행 중인 세션 확인)
            ICXTradingSession* existing = session_mgr.FindSessionBySid(sid);
            if(IS_VALID(existing)) {
                if(sig.GetXAExit() == XA_ACTIVE) {
                    XP_LOG_WARN(xp, CXAuditFormatter::Build("WATCHER-SPAWN", xp, "INTERRUPT: SID is active. Forcing Liquidation."));
                    existing.ForceTransition(SESSION_LIQUIDATING);
                    
                    IRepository* repo = CX_GET_OBJ(ctx, "repo", IRepository);
                    if(IS_VALID(repo)) {
                        sig.SetStatus(XE_CLOSED_SIGNAL); 
                        sig.SetStatusMsg("Liquidation Forced by Watcher");
                        repo.UpdateStatus(sig);
                    }
                    skipped++;
                } else {
                    XP_LOG_TRACE(xp, CXAuditFormatter::Build("WATCHER-SPAWN", xp, "SKIP: SID is already active."));
                    skipped++;
                }
                SAFE_DELETE(sig); 
                continue;
            }

            // [v14.29 Logic Restoration] 
            sig.SetStatus(XE_READY);
            sig.SetStatusMsg("Spawning Initiation");

            //-- 1. 세션 동적 생성 (v15.9 Param-injected)
            CXParam sp;
            sp.SetSignal(sig);
            ICXTradingSession* session = session_mgr.CreateSession(GetPointer(sp));
            if(IS_VALID(session)) {
                IRepository* repo = CX_GET_OBJ(ctx, "repo", IRepository);
                bool locked = false;
                if(IS_VALID(repo)) {
                    sig.SetStatus(XE_PENDING_REQ);
                    sig.SetStatusMsg("Session Spawned (Pre-lock)");
                    locked = repo.UpdateStatus(sig);

                    XP_LOG_TRACE(xp, CXAuditFormatter::Build("WATCHER-SPAWN", xp, "Pre-lock end. Result:" + (locked?"OK":"FAIL") + ", Status:" + IntegerToString(sig.GetStatus())));
                }

                if(locked) {
                    //-- 2. 세션 기동
                    session.Start(GetPointer(sp));

                    // [v16.14 Fix] Changed to XP_LOG_INFO to enable deduplication (LOG_POLICY_ON_CHANGE)
                    XP_LOG_INFO(xp, CXAuditFormatter::Build("WATCHER-SPAWN", xp, "SUCCESS: Session spawned and started."));
                    success++;
                } else {
                    XP_LOG_ERROR(xp, CXAuditFormatter::Build("WATCHER-SPAWN", xp, "FAILED: DB Pre-lock failed."));
                    failed++;
                    SAFE_DELETE(sig);
                }
            } else {
                XP_LOG_ERROR(xp, CXAuditFormatter::Build("WATCHER-SPAWN", xp, "FAILED: Session creation failed."));
                failed++;
                SAFE_DELETE(sig); 
            }
        }

        if(total > 0) {
            XP_LOG_TRACE(xp, StringFormat("[WATCHER-SPAWN] Complete. Total:%d, Success:%d, Skipped:%d, Failed:%d", total, success, skipped, failed));
        }

        // 3. 작업 완료 후 리스트 정리
        while(activeList.Total() > 0) activeList.Detach(0); 

        return WATCHER_DISCOVERY;
    }

    virtual void OnEnter(ICXContext* ctx) override {}
    virtual void OnExit(ICXContext* ctx) override {}
};

#endif
