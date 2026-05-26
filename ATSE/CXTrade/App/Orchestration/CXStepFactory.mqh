#ifndef CXSTEPFACTORY_MQH
#define CXSTEPFACTORY_MQH

#include "..\..\Platform\Core\Interfaces\IXStep.mqh"
#include "..\..\Platform\Core\Macros\CXMacros.mqh"
#include "..\..\Watcher\WatcherWorkflow\CXStepEntryDiscovery.mqh"
#include "..\..\Watcher\WatcherWorkflow\CXStepEntryExecute.mqh"
#include "..\..\Watcher\WatcherWorkflow\CXStepExitDiscovery.mqh"
#include "..\..\Watcher\WatcherWorkflow\CXStepExitExecute.mqh"

#include "CXTaskFactory.mqh"
#include "..\..\Session\Workflow\CXCompositeStep.mqh"
#include <Arrays\ArrayString.mqh>

/**
 * @class CXStepFactory
 * @brief [v16.6] 문자열 명칭을 기반으로 IXStep 객체를 생성하는 팩토리 (Enum-less)
 */
class CXStepFactory {
public:
    /**
     * @brief [v16.6] 스텝 이름의 존재 여부를 확인
     */
    static bool Exists(string name) {
        if(name == "EntryDiscovery") return true;
        if(name == "EntryExecute")   return true;
        if(name == "ExitDiscovery")  return true;
        if(name == "ExitExecute")    return true;
        if(name == "Composite")      return true;
        if(StringFind(name, "Step_") == 0) return true;
        return false;
    }

    /**
     * @brief [v16.6] 문자열 이름을 기반으로 IXStep 객체 생성
     */
    static IXStep* CreateStep(string typeName, string alias = "", CArrayString* taskNames = NULL) {
        if(typeName == "EntryDiscovery") return new CXStepEntryDiscovery();
        if(typeName == "EntryExecute")   return new CXStepEntryExecute();
        if(typeName == "ExitDiscovery")  return new CXStepExitDiscovery();
        if(typeName == "ExitExecute")    return new CXStepExitExecute();
        if(typeName == "Composite" || StringFind(typeName, "Step_") == 0) {
            return CreateCompositeStep(alias == "" ? typeName : alias, taskNames);
        }
        return NULL;
    }

private:
    /**
     * @brief [v16.6] 복합 태스크 스텝 생성 (문자열 리스트 기반)
     */
    static IXStep* CreateCompositeStep(string name, CArrayString* taskList) {
        CXCompositeStep* step = new CXCompositeStep(name);
        if(IS_INVALID(step)) return NULL;

        if(IS_VALID(taskList)) {
            for(int i = 0; i < taskList.Total(); i++) {
                IXTask* task = CXTaskFactory::CreateTask(taskList.At(i));
                if(IS_VALID(task)) step.AddTask(task);
            }
        }

        return step;
    }
};

#endif
