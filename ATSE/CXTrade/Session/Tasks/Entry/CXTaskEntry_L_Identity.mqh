#ifndef CX_TASK_ENTRY_L_IDENTITY_MQH
#define CX_TASK_ENTRY_L_IDENTITY_MQH

#include "..\..\..\Interfaces\IXTask.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"
#include "..\..\..\Interfaces\IXGuard.mqh"

/**
 * @class CXTaskEntry_L_Identity
 * @brief [Logic] 신호의 정합성(Magic, SID) 검증
 */
class CXTaskEntry_L_Identity : public IXTask {
public:
    virtual string Name() override { return "Entry_L_Identity"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        IXGuard* guard = CX_GET_OBJ(ctx, "guard", IXGuard);

        if(IS_INVALID(sig)) return TASK_BREAK;
        if(IS_INVALID(guard)) return TASK_CONTINUE; // Guard 없으면 통과

        if(!guard.ValidateMagic(sig.GetMagic())) {
            XP_LOG_ERROR(xp, StringFormat("[ENTRY-L] Identity Violation: Invalid Magic %I64u", sig.GetMagic()));
            return TASK_BREAK;
        }

        if(!guard.ValidateSID(sig.GetSid())) {
            XP_LOG_ERROR(xp, StringFormat("[ENTRY-L] Identity Violation: Invalid SID %s", sig.GetSid()));
            return TASK_BREAK;
        }

        return TASK_CONTINUE;
    }
};

#endif
