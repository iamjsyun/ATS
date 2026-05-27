#ifndef CXSTAGEFACTORY_MQH
#define CXSTAGEFACTORY_MQH

#include "..\..\Platform\Core\Interfaces\IXStage.mqh"
#include "..\..\Platform\Core\Macros\CXMacros.mqh"
#include "..\..\Watcher\WatcherWorkflow\CXStageEntryDiscovery.mqh"
#include "..\..\Watcher\WatcherWorkflow\CXStageEntryExecute.mqh"
#include "..\..\Watcher\WatcherWorkflow\CXStageExitDiscovery.mqh"
#include "..\..\Watcher\WatcherWorkflow\CXStageExitExecute.mqh"
#include "..\..\Watcher\WatcherWorkflow\CXStageZombieDiscovery.mqh"
#include "..\..\Watcher\WatcherWorkflow\CXStageReverseInject.mqh"

#include "CXTaskFactory.mqh"
#include "..\..\Session\Workflow\CXCompositeStage.mqh"
#include <Arrays\ArrayString.mqh>

/**
 * @class CXStageFactory
 * @brief [v16.6] 문자열 명칭을 기반으로 IXStage 객체를 생성하는 팩토리 (Enum-less)
 */
class CXStageFactory {
public:
    /**
     * @brief [v16.6] 스테이지 이름의 존재 여부를 확인
     */
    static bool Exists(string name) {
        if(name == "EntryDiscovery") return true;
        if(name == "EntryExecute")   return true;
        if(name == "ExitDiscovery")  return true;
        if(name == "ExitExecute")    return true;
        if(name == "ZombieDiscovery") return true;
        if(name == "ReverseInject")   return true;
        if(name == "Composite")      return true;
        if(StringFind(name, "Stage_") == 0) return true;
        return false;
    }

    /**
     * @brief [v16.6] 문자열 이름을 기반으로 IXStage 객체 생성
     */
    static IXStage* CreateStage(string typeName, string alias = "", CArrayString* taskNames = NULL) {
        if(typeName == "EntryDiscovery") return new CXStageEntryDiscovery();
        if(typeName == "EntryExecute")   return new CXStageEntryExecute();
        if(typeName == "ExitDiscovery")  return new CXStageExitDiscovery();
        if(typeName == "ExitExecute")    return new CXStageExitExecute();
        if(typeName == "ZombieDiscovery") return new CXStageZombieDiscovery();
        if(typeName == "ReverseInject")   return new CXStageReverseInject();
        if(typeName == "Composite" || StringFind(typeName, "Stage_") == 0) {
            return CreateCompositeStage(alias == "" ? typeName : alias, taskNames);
        }
        return NULL;
    }

private:
    /**
     * @brief [v16.6] 복합 태스크 스테이지 생성 (문자열 리스트 기반)
     */
    static IXStage* CreateCompositeStage(string name, CArrayString* taskList) {
        CXCompositeStage* stage = new CXCompositeStage(name);
        if(IS_INVALID(stage)) return NULL;

        if(IS_VALID(taskList)) {
            for(int i = 0; i < taskList.Total(); i++) {
                IXTask* task = CXTaskFactory::CreateTask(taskList.At(i));
                if(IS_VALID(task)) stage.AddTask(task);
            }
        }

        return stage;
    }
};

#endif
