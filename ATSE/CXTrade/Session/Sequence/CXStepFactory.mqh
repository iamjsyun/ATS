#ifndef CXSTEPFACTORY_MQH
#define CXSTEPFACTORY_MQH

#include "..\..\Core\Interfaces\IXStep.mqh"
#include "..\..\Core\Macros\CXMacros.mqh"
#include "..\Workflow\Watcher\CXStepDiscovery.mqh"
#include "..\Workflow\Watcher\CXStepValidation.mqh"
#include "..\Workflow\Watcher\CXStepSpawning.mqh"

#include "CXTaskFactory.mqh"
#include "..\Workflow\CXCompositeStep.mqh"
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
        if(name == "Discovery")  return true;
        if(name == "Validation") return true;
        if(name == "Spawning")   return true;
        if(name == "Composite")  return true;
        return false;
    }

    /**
     * @brief [v16.6] 문자열 이름을 기반으로 IXStep 객체 생성
     */
    static IXStep* CreateStep(string typeName, string alias = "", CArrayString* taskNames = NULL) {
        if(typeName == "Discovery")  return new CXStepDiscovery();
        if(typeName == "Validation") return new CXStepValidation();
        if(typeName == "Spawning")   return new CXStepSpawning();
        if(typeName == "Composite")  return CreateCompositeStep(alias == "" ? typeName : alias, taskNames);
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
