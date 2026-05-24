#ifndef CXENTRYMANAGER_MQH
#define CXENTRYMANAGER_MQH

#include "..\..\Core\Interfaces\IXEntryManager.mqh"
#include "..\..\Core\Interfaces\ICXContext.mqh"
#include "..\..\Core\Interfaces\ICXParam.mqh"
#include "..\..\Core\Macros\CXMacros.mqh"
#include "..\..\Core\Interfaces\IXGuard.mqh"
#include "..\..\Shared\Logging\CXAuditFormatter.mqh"

/**
 * @class CXEntryManager
 * @brief 진입 로직 전반을 총괄하는 도메인 서비스
 */
class CXEntryManager : public IXEntryManager {
private:
    ICXContext*         m_ctx;

public:
    CXEntryManager(ICXContext* ctx) : m_ctx(ctx) {}
    virtual ~CXEntryManager() override {}

    /**
     * @brief 진입 전 파라미터 최적화 및 검증
     */
    virtual void Pulse(ICXParam* xp) override {
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig)) return;

        // 1. [v11.8] Identity Validation (Double-check)
        IXGuard* guard = CX_GET_OBJ(m_ctx, "guard", IXGuard);
        if(IS_VALID(guard)) {
            if(!guard.ValidateSID(sig.GetSid())) {
                XP_LOG_ERROR(xp, CXAuditFormatter::Build("ENTRY-GUARD-BLOCK", xp, guard.GetLastError()));
                return;
            }
        }

        // 진입 전략 설정 조정 로직
        XP_LOG_INFO(xp, CXAuditFormatter::Build("SANDBOX-ENTRY", xp));
    }
};

#endif
