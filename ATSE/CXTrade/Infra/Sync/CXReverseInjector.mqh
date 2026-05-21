#ifndef CXREVERSEINJECTOR_MQH
#define CXREVERSEINJECTOR_MQH

#include "..\..\Interfaces\ICXContext.mqh"
#include "..\..\Interfaces\ICXParam.mqh"
#include "..\..\Interfaces\IRepository.mqh"
#include "..\..\Interfaces\ICXTradingSessionPool.mqh"
#include "..\..\Interfaces\CXMacros.mqh"
#include "CXTerminalScanner.mqh"

/**
 * @class CXReverseInjector
 * @brief 터미널-DB-세션 간의 상태 불일치를 해결하고 세션에 자산을 역주입함
 */
class CXReverseInjector {
private:
    IRepository*           m_repo;
    ICXTradingSessionPool* m_pool;
    CXTerminalScanner*     m_scanner;
    
public:
    CXReverseInjector(IRepository* repo, ICXTradingSessionPool* pool) 
        : m_repo(repo), m_pool(pool) {
        m_scanner = new CXTerminalScanner();
    }
    
    ~CXReverseInjector() {
        SAFE_DELETE(m_scanner);
    }
    
    /**
     * @brief 스캔 및 역주입 실행 (Zombie Recovery)
     */
    void Pulse(ICXParam* xp) {
        if(IS_INVALID(m_scanner) || IS_INVALID(m_repo) || IS_INVALID(m_pool)) return;
        
        CArrayObj terminalAssets;
        if(m_scanner.ScanAll(GetPointer(terminalAssets)) <= 0) return;

        XP_LOG_DEBUG(xp, StringFormat("[REVERSE-INJECT] Scanning %d terminal assets...", terminalAssets.Total()));

        for(int i = 0; i < terminalAssets.Total(); i++) {
            CXParam* asset = CX_CAST(CXParam, terminalAssets.At(i));
            if(IS_INVALID(asset)) continue;

            string sid = asset.GetString();
            
            // 0. 이미 해당 SID가 세션 풀에서 관리 중인지 확인 (중복 주입 방지)
            ICXTradingSession* existing = m_pool.FindSessionBySid(sid);
            if(IS_VALID(existing)) {
                XP_LOG_DEBUG(xp, StringFormat("[REVERSE-INJECT-SKIP] SID:%s is already active in pool.", sid));
                continue;
            }

            // 1. DB에서 해당 SID의 신호 정보 조회
            ICXSignal* sig = m_repo.GetSignalBySid(sid);
            if(IS_INVALID(sig)) {
                XP_LOG_WARN(xp, StringFormat("[REVERSE-INJECT] Unknown SID found in terminal: %s. Ignoring.", sid));
                continue;
            }

            // 2. 세션 풀에 해당 자산이 이미 관리되고 있는지 Pulse를 통해 간접 확인하거나, 
            //    여기서는 '강제 주입' 정책을 수행 (Pool 내부에서 중복 체크 필요)
            ICXTradingSession* session = m_pool.BorrowSession();
            if(IS_VALID(session)) {
                XP_LOG_INFO(xp, StringFormat("[REVERSE-INJECT] Restoring session for SID: %s", sid));
                session.InjectState(CX_CAST(CXSignal, sig));
            } else {
                XP_LOG_ERROR(xp, StringFormat("[REVERSE-INJECT] Failed to borrow session for recovery of SID: %s", sid));
                SAFE_DELETE(sig);
            }
        }
    }
};

#endif
