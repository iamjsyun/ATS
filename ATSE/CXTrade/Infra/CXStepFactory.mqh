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
    /**
     * @brief [v11.4] 문자열 이름을 기반으로 ENUM_STEP_TYPE 반환
     */
    static ENUM_STEP_TYPE GetStepTypeByName(string name) {
        if(name == "Discovery")  return STEP_W_DISCOVERY;
        if(name == "Validation") return STEP_W_VALIDATION;
        if(name == "Binding")    return STEP_W_BINDING;
        if(name == "Composite")  return STEP_S_COMPOSITE;
        if(name == "Monitor")    return STEP_S_MONITOR;
        return STEP_NONE;
    }

    /**
     * @brief 스텝 이름의 존재 여부를 확인 (Pre-validation용)
     */
    static bool Exists(string name) {
        if(name == "Discovery")  return true;
        if(name == "Validation") return true;
        if(name == "Binding")    return true;
        if(name == "Composite")  return true;
        if(name == "Monitor")    return true;
        return false;
    }

    /**
     * @brief [v11.4] 문자열 이름을 기반으로 IXStep 객체 생성
     */
    static IXStep* CreateStepByName(string name, string alias = "", CArrayInt* tasks = NULL) {
        if(name == "Discovery")  return new CXStepDiscovery();
        if(name == "Validation") return new CXStepValidation();
        if(name == "Binding")    return new CXStepBinding();
        if(name == "Composite")  return CreateCompositeStep(alias == "" ? name : alias, tasks);
        if(name == "Monitor")    return new CXStepMonitor();
        return NULL;
    }

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
