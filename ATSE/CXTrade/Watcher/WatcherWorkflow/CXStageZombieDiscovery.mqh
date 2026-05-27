#ifndef CXSTAGEZOMBIEDISCOVERY_MQH
#define CXSTAGEZOMBIEDISCOVERY_MQH

#include "..\..\Platform\Core\Interfaces\IXStage.mqh"
#include "..\..\Platform\Core\Interfaces\IRepository.mqh"
#include "..\..\Platform\Core\Interfaces\ICXConfig.mqh"
#include "..\..\Platform\Core\Interfaces\ICXSessionManager.mqh"
#include "..\..\Platform\Core\Models\CXSignal.mqh"
#include "..\..\Platform\Core\Models\CXTerminalAsset.mqh"
#include "..\..\Platform\Core\Macros\CXMacros.mqh"
#include "..\..\Platform\Core\Sequence\CXSequenceOrchestrator.mqh"
#include "..\..\App\Logic\CXTerminalScanner.mqh"

#include <Arrays\ArrayObj.mqh>

/**
 * @class CXStageZombieDiscovery
 * @brief 터미널 실물 자산 중 세션 또는 DB 상에 활성 상태가 없는 좀비(고아) 자산을 검색하는 단계
 */
class CXStageZombieDiscovery : public IXStage {
public:
    CXStageZombieDiscovery() {}
    virtual ~CXStageZombieDiscovery() {}

    virtual string Name() override { return "Stage_ZombieDiscovery"; }

    virtual bool OnCondition(ICXParam* xp, ICXContext* ctx, int current_state) override {
        return true; 
    }

    virtual int OnProcess(ICXParam* xp, ICXContext* ctx) override {
        IRepository* repo = CX_GET_OBJ(ctx, "repo", IRepository);
        ICXConfig* config = CX_GET_OBJ(ctx, "config", ICXConfig);
        ICXSessionManager* session_mgr = CX_GET_OBJ(ctx, "session_mgr", ICXSessionManager);

        if(IS_INVALID(repo) || IS_INVALID(config) || IS_INVALID(session_mgr)) {
            CXSequenceOrchestrator* orchestrator = CX_GET_OBJ(ctx, "orchestrator", CXSequenceOrchestrator);
            return IS_VALID(orchestrator) ? orchestrator.ResolveId("WATCHER_ENTRY_DISCOVERY") : STATE_UNCHANGED;
        }

        CXTerminalScanner scanner;
        CArrayObj* terminalAssets = new CArrayObj();
        int assetCount = scanner.ScanAll(terminalAssets);
        
        CArrayObj* zombieList = new CArrayObj();

        for(int i = 0; i < terminalAssets.Total(); i++) {
            CXTerminalAsset* asset = CX_CAST(CXTerminalAsset, terminalAssets.At(i));
            if(IS_INVALID(asset)) continue;

            string sid = asset.sid;
            int magic = asset.magic;

            // [Tier 1] 매직넘버 격리 원칙 (내 관리 대상이 아니면 무시)
            if(!config.IsTargetMagic(magic)) continue;

            // 0. 이미 해당 SID가 세션 풀에서 관리 중인지 확인 (중복 주입 방지)
            ICXTradingSession* existing = session_mgr.FindSessionBySid(sid);
            if(IS_VALID(existing)) continue;

            // 1. DB에서 해당 SID의 신호 정보 조회
            ICXSignal* sig = repo.GetSignalBySid(sid);

            // [Tier 2] 좀비 판별 (DB에 없거나 이미 종료된 신호인데 터미널에 실물이 있는 경우)
            if(IS_INVALID(sig) || sig.GetStatus() >= XE_CLOSED_SIGNAL) {
                // 좀비 자산 검출 완료! 임시 객체로 리스트에 추가
                terminalAssets.Detach(i);
                zombieList.Add(asset);
                i--; // Detach 했으므로 인덱스 보정
            }
            
            if(IS_VALID(sig)) delete sig;
        }

        // 스캔 전체 임시 자산 리스트 삭제
        terminalAssets.Clear();
        delete terminalAssets;

        int zombieCount = zombieList.Total();
        if(zombieCount > 0) {
            XP_LOG_WARN(xp, StringFormat("[WATCHER-ZOMBIE-DISCOVERY] Found %d zombie/orphan assets", zombieCount));
            ctx.Set("zombie_assets", zombieList);

            CXSequenceOrchestrator* orchestrator = CX_GET_OBJ(ctx, "orchestrator", CXSequenceOrchestrator);
            if(IS_VALID(orchestrator)) {
                return orchestrator.ResolveId("WATCHER_REVERSE_INJECT");
            }
        }

        SAFE_DELETE(zombieList);
        CXSequenceOrchestrator* orchestrator = CX_GET_OBJ(ctx, "orchestrator", CXSequenceOrchestrator);
        return IS_VALID(orchestrator) ? orchestrator.ResolveId("WATCHER_ENTRY_DISCOVERY") : STATE_UNCHANGED;
    }

    virtual void OnEnter(ICXContext* ctx) override {}
    virtual void OnExit(ICXContext* ctx) override {}
};

#endif
