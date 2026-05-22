#ifndef CXCOMPOSITESTEP_MQH
#define CXCOMPOSITESTEP_MQH

#include "..\..\Interfaces\IXStep.mqh"
#include "..\..\Interfaces\IXTask.mqh"
#include "..\..\Interfaces\CXMacros.mqh"
#include <Arrays\ArrayObj.mqh>

/**
 * @class CXCompositeStep
 * @brief 여러 개의 IXTask(마이크로 태스크)를 조립하여 순차 실행하는 복합 시퀀스 스텝
 */
class CXCompositeStep : public IXStep {
private:
    string      m_name;
    CArrayObj   m_tasks;
    int         m_currentTaskIndex; // [Refinement 1] Resume Pointer
    bool        m_hasConditionFunc;

public:
    CXCompositeStep(string name) : m_name(name), m_currentTaskIndex(0), m_hasConditionFunc(false) {}
    virtual ~CXCompositeStep() {
        m_tasks.Clear();
    }

    virtual string Name() override { return m_name; }

    /**
     * @brief 실행할 태스크를 체인에 추가합니다.
     */
    CXCompositeStep* AddTask(IXTask* task) {
        if(IS_VALID(task)) {
            m_tasks.Add(task);
        }
        return GetPointer(this);
    }

    /**
     * @brief 기본적으로 true를 반환하며, 태스크 내부 로직에서 조건을 필터링합니다.
     */
    virtual bool OnCondition(ICXParam* xp, ICXContext* ctx, int current_state) override {
        return true; 
    }

    /**
     * @brief 등록된 태스크들을 순차적으로 실행
     */
    virtual int OnProcess(ICXParam* xp, ICXContext* ctx) override {
        // [v11.9 Fix] Persist current index across ticks by retrieving it from Context
        string indexKey = StringFormat("CompositeIndex_%s", m_name);
        ICXParam* pIdx = dynamic_cast<ICXParam*>(ctx.Get(indexKey));
        int startIndex = IS_VALID(pIdx) ? pIdx.GetInt() : 0;
        
        for(int i = 0; i < m_tasks.Total(); i++) {
            // [v14.3 Priority Execution] 
            // 인덱스 0번 태스크(보통 IntentWatch)는 이전의 Yield 지점과 상관없이 "매 틱 무조건 실행"
            if(i > 0 && i < startIndex) continue; 

            IXTask* task = dynamic_cast<IXTask*>(m_tasks.At(i));
            if(IS_VALID(task)) {
                // [v9.9.2] 타임아웃 검증
                if(task.IsTimedOut()) {
                    string timeoutErr = StringFormat("[%s] Task Timeout. Moving to SESSION_ERROR.", task.Name());
                    XP_LOG_ERROR(xp, timeoutErr);
                    if(IS_VALID(xp)) xp.SetString(timeoutErr);
                    if(IS_VALID(pIdx)) pIdx.SetInt(0);
                    return SESSION_ERROR;
                }

                int res = task.Execute(xp, ctx);
                
                // 1. 특정 상태로 전이 지시 시 즉시 반환 (성공/상태변경)
                if(res >= 0) {
                    task.ResetRetry(); 
                    if(IS_VALID(pIdx)) pIdx.SetInt(0);
                    return res;
                }
                // 2. 실행 중지(Break) 지시 시 남은 태스크 무시하고 현재 상태 유지
                else if(res == TASK_BREAK) {
                    if(IS_VALID(pIdx)) pIdx.SetInt(0);
                    return STATE_UNCHANGED;
                }
                // 3. 비차단 대기(Yield) 시 인덱스 유지하고 다음 틱 대기
                else if(res == TASK_YIELD) {
                    if(IS_INVALID(pIdx)) {
                        pIdx = new CXParam();
                        ctx.Set(indexKey, pIdx);
                    }
                    pIdx.SetInt(i); // 현재 지점 저장
                    
                    task.IncrementRetry();
                    if(task.IsMaxRetriesExceeded()) {
                        string retryErr = StringFormat("[%s] Max Retries Exceeded. Moving to SESSION_ERROR.", task.Name());
                        XP_LOG_ERROR(xp, retryErr);
                        if(IS_VALID(xp)) xp.SetString(retryErr);
                        pIdx.SetInt(0);
                        return SESSION_ERROR;
                    }
                    // Yield 발생 시 0번(감시자)은 다음 틱에도 실행되어야 하므로 루프 종료
                    return STATE_UNCHANGED;
                }
                // 4. TASK_CONTINUE(-1) 시 다음 태스크로 진행
                else if(res == TASK_CONTINUE) {
                    task.ResetRetry(); 
                }
            }
        }
        
        if(IS_VALID(pIdx)) pIdx.SetInt(0);
        return STATE_UNCHANGED; 
    }

    virtual void OnEnter(ICXContext* ctx) override {
        string indexKey = StringFormat("CompositeIndex_%s", m_name);
        ICXParam* pIdx = dynamic_cast<ICXParam*>(ctx.Get(indexKey));
        if(IS_INVALID(pIdx)) {
            pIdx = new CXParam();
            ctx.Set(indexKey, pIdx);
        }
        pIdx.SetInt(0);
        XP_LOG_DEBUG(NULL, StringFormat("[%s] Composite Step Entered (%d tasks)", m_name, m_tasks.Total()));
    }
    
    virtual void OnExit(ICXContext* ctx) override {
        string indexKey = StringFormat("CompositeIndex_%s", m_name);
        ICXParam* pIdx = dynamic_cast<ICXParam*>(ctx.Get(indexKey));
        if(IS_VALID(pIdx)) pIdx.SetInt(0);
        XP_LOG_DEBUG(NULL, StringFormat("[%s] Composite Step Exited", m_name));
    }
};

#endif
