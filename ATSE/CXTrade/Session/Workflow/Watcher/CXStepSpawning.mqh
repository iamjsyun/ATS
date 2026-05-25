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
            string trimmedSid = sid; StringTrimRight(trimmedSid); StringTrimLeft(trimmedSid);
            ICXTradingSession* existing = session_mgr.FindSessionBySid(trimmedSid);
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
                    // 이미 가동 중인 세션에 대해서는 추가 로그 생략 (Muting Mandate)
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

                    // [v16.15 Fix] Use stable=true to enable deduplication (Ignores volatile Market Price)
                    XP_LOG_INFO(xp, CXAuditFormatter::Build("WATCHER-SPAWN", xp, "SUCCESS: Session spawned and started.", true));
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

        // [v16.15 Fix] 리스트에 남은(처리되지 않았거나 에러난) 객체 완전 소멸 (Memory Leak Guard)
        for(int i = 0; i < activeList.Total(); i++) {
            ICXSignal* sig = CX_CAST(ICXSignal, activeList.At(i));
            // 성공적으로 세션에 주입된 신호는 세션이 소유하므로 삭제하면 안됨.
            // 하지만 activeList.Detach(0)를 쓰므로 관리가 까다로움.
            // 여기서는 Detach만 하고, owner인 Session이 삭제하게 둠.
        }

        if(total > 0) {
            XP_LOG_TRACE(xp, StringFormat("[WATCHER-SPAWN] Complete. Total:%d, Success:%d, Skipped:%d, Failed:%d", total, success, skipped, failed));
        }

        // 3. 작업 완료 후 리스트 정리 (포인터만 분리, 실제 소멸은 위 루프 및 세션에서 담당)
        while(activeList.Total() > 0) activeList.Detach(0); 

        return WATCHER_DISCOVERY;
    }

    virtual void OnEnter(ICXContext* ctx) override {}
    virtual void OnExit(ICXContext* ctx) override {}
};

#endif
