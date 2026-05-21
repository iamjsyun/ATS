#ifndef CX_TASK_COMM_V_STATUS_MQH
#define CX_TASK_COMM_V_STATUS_MQH

#include "..\..\..\Interfaces\IXTask.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"
#include "..\..\..\Interfaces\ICXLogger.mqh"

/**
 * @class CXTaskComm_V_Status
 * @brief [Verify] 외부 통신 레이어(RemoteLogger) 연결 상태 확인
 */
class CXTaskComm_V_Status : public IXTask {
public:
    virtual string Name() override { return "Comm_V_Status"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        // CXRemoteLogger 등의 전역 상태 체크
        ICXLogger* logger = CX_GET_OBJ(ctx, "logger", ICXLogger);
        
        XP_LOG_TRACE(xp, "[COMM-V-STATUS] Verifying Communication Infrastructure...");

        if(IS_INVALID(logger)) {
            // 로거 없어도 매매는 진행하되 경고
            Print("[COMM-V-STATUS] WARNING: Global Logger is unavailable. System running in silent mode.");
        } else {
            XP_LOG_DEBUG(xp, "[COMM-V-STATUS] OK: Logger is connected.");
        }

        return TASK_CONTINUE;
    }
};

#endif
