#ifndef CXSTEPFACTORY_MQH
#define CXSTEPFACTORY_MQH

#include "..\Interfaces\IXStep.mqh"
#include "..\Interfaces\CXDefine.mqh"
#include "..\Module\Steps\Watcher\CXStepDiscovery.mqh"
#include "..\Module\Steps\Watcher\CXStepValidation.mqh"
#include "..\Module\Steps\Watcher\CXStepBinding.mqh"
#include "..\Session\Steps\CXCompositeStep.mqh"
#include "..\Session\Steps\CXStepMonitor.mqh"

#include "..\Infra\CXTaskFactory.mqh"
#include <Arrays\ArrayInt.mqh>

/**
 * @class CXStepFactory
 * @brief Enum 타입을 기반으로 IXStep 객체를 생성하는 팩토리
 */
class CXStepFactory {
public:
    static IXStep* CreateStep(ENUM_STEP_TYPE type, string name = "", CArrayInt* tasks = NULL) {
        switch(type) {
            case STEP_W_DISCOVERY:  return new CXStepDiscovery();
            case STEP_W_VALIDATION: return new CXStepValidation();
            case STEP_W_BINDING:    return new CXStepBinding();
            case STEP_S_COMPOSITE:  return CreateCompositeStep(name, tasks);
            case STEP_S_MONITOR:    return new CXStepMonitor();
            default:                return NULL;
        }
    }

private:
    static IXStep* CreateCompositeStep(string name, CArrayInt* taskList) {
        CXCompositeStep* step = new CXCompositeStep(name);
        if(IS_INVALID(step)) return NULL;

        if(IS_VALID(taskList)) {
            for(int i = 0; i < taskList.Total(); i++) {
                IXTask* task = CXTaskFactory::CreateTask((ENUM_TASK_TYPE)taskList.At(i));
                if(IS_VALID(task)) step.AddTask(task);
            }
        }

        return step;
    }
};

#endif
