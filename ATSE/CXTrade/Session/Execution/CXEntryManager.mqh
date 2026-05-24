#ifndef CXENTRYMANAGER_MQH
#define CXENTRYMANAGER_MQH

#include "..\..\Interfaces\IXEntryManager.mqh"
#include "..\..\Interfaces\ICXContext.mqh"
#include "..\..\Interfaces\ICXParam.mqh"
#include "..\..\Interfaces\CXDefine.mqh"
#include "..\..\Interfaces\CXMacros.mqh"
#include "..\..\Interfaces\IXTrailingStrategy.mqh"
#include "..\..\Interfaces\IXGuard.mqh"
#include "..\..\Infra\CXAuditFormatter.mqh"

/**
 * @class CXEntryManager
 * @brief 신규 진입 전략 및 파라미터 조정 담당 (Sandboxed)
 */
class CXEntryManager : public IXEntryManager {
private:
    ICXContext*         m_ctx;
    IXTrailingStrategy* m_entryTrl; // 진입 트레일링 (Pluggable)

public:
    CXEntryManager(ICXContext* ctx) : m_ctx(ctx), m_entryTrl(NULL) {}
    virtual ~CXEntryManager() override { SAFE_DELETE(m_entryTrl); }

    void SetTrailingStrategy(IXTrailingStrategy* strategy) {
        SAFE_DELETE(m_entryTrl);
        m_entryTrl = strategy;
    }

    /**
     * @brief 진입 전 파라미터 최적화 및 검증
     */
    virtual void Pulse(ICXParam* xp) override {
        if(IS_NULL(m_ctx) || IS_NULL(xp)) return;
        
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig)) return;

        //--- [Point 4] 중앙 집중형 검증 가드 (CXGuard) 적용
        IXGuard* guard = CX_GET_OBJ(m_ctx, "guard", IXGuard);
        if(IS_VALID(guard)) {
            if(!guard.ValidateMagic(sig.GetMagic()) || !guard.ValidateSID(sig.GetSid())) {
                XP_LOG_ERROR(xp, CXAuditFormatter::Build("ENTRY-GUARD-BLOCK", xp, guard.GetLastError()));
                return;
            }
        }

        // 진입 전략 설정 조정 로직
        XP_LOG_INFO(xp, CXAuditFormatter::Build("SANDBOX-ENTRY", xp));
    }
};

#endif



