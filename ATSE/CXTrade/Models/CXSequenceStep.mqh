#ifndef CXSEQUENCESTEP_MQH
#define CXSEQUENCESTEP_MQH

#include <Object.mqh>
#include <Generic\HashMap.mqh>
#include "..\Interfaces\CXDefine.mqh"

#include <Arrays\ArrayInt.mqh>

/**
 * @class CXSequenceStep
 * @brief 시퀀스 구성을 위한 노드 데이터 클래스 (분기 및 태스크 리스트 지원)
 */
class CXSequenceStep : public CObject {
private:
    int                 m_state_id;
    ENUM_STEP_TYPE      m_step_type;
    int                 m_next_id;
    int                 m_fail_id;
    int                 m_timeout;
    int                 m_retries;
    string              m_name;
    CHashMap<int, int>* m_branches;
    CArrayInt*          m_tasks;

public:
    CXSequenceStep(int id, ENUM_STEP_TYPE type, int next, int fail, int timeout = 0, int retries = 0, string name = "") 
        : m_state_id(id), m_step_type(type), m_next_id(next), m_fail_id(fail), m_timeout(timeout), m_retries(retries), m_name(name) {
        m_branches = new CHashMap<int, int>();
        m_tasks = new CArrayInt();
    }

    ~CXSequenceStep() {
        SAFE_DELETE(m_branches);
        SAFE_DELETE(m_tasks);
    }

    CXSequenceStep* Case(int code, int next_state) {
        if(IS_VALID(m_branches)) m_branches.Add(code, next_state);
        return GetPointer(this);
    }

    CXSequenceStep* AddTask(ENUM_TASK_TYPE task) {
        if(IS_VALID(m_tasks)) m_tasks.Add((int)task);
        return GetPointer(this);
    }

    int             GetStateId()  const { return m_state_id; }
    ENUM_STEP_TYPE  GetStepType() const { return m_step_type; }
    int             GetNextId()   const { return m_next_id; }
    int             GetFailId()   const { return m_fail_id; }
    int             GetTimeout()  const { return m_timeout; }
    int             GetRetries()  const { return m_retries; }
    string          GetName()     const { return m_name; }
    
    CHashMap<int, int>* GetBranches() const { return m_branches; }
    CArrayInt*          GetTasks()    const { return m_tasks; }
};

#endif
