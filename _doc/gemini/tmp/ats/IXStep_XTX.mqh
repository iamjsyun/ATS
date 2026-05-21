//+------------------------------------------------------------------+
//|                                                       IXStep.mqh |
//|                                  Copyright 2026, Gemini CLI      |
//| [v7.3] Shared Step Interface for Sequence Orchestrators          |
//+------------------------------------------------------------------+
#ifndef IX_STEP_MQH
#define IX_STEP_MQH

#include "CXResult.mqh"
#include "CXContext.mqh"
#include "..\Common\CXDefine.mqh"
#include "IXGuard.mqh"

#include <Generic\HashMap.mqh>

/**
 * @class IXStep
 * @brief 시퀀스의 각 단계를 정의하는 추상 클래스
 */
class IXStep : public CObject {
public:
   virtual string    Name() = 0;
   virtual int       TargetState() = 0;
   virtual bool      OnCondition(CXParam* xp, CXContext* ctx, int current_state) = 0;
   virtual CXResult  OnProcess(CXParam* xp, CXContext* ctx) = 0;
   
   // 생명주기 훅
   virtual void      OnEnter(CXContext* ctx) {}
   virtual void      OnExit(CXContext* ctx)  {}
};

/**
 * @class CXStepNode
 * @brief 시나리오 노드 (분기, 제약 조건, 재시도, 가드 및 다중 분기 포함)
 */
class CXStepNode : public CObject {
public:
    IXStep*             step;
    IXGuard*            guard; 
    int                 trigger_state;
    int                 if_true;
    int                 if_false;
    int                 timeout_sec;
    int                 max_retries;
    int                 current_retries;
    CHashMap<int, int>* branches; // [Phase 3] 다중 분기 맵 (ErrorCode -> NextState)

    CXStepNode(IXStep* s, int trigger, int t_path, int f_path, int timeout = 0, int retries = 0, IXGuard* g = NULL) 
        : step(s), trigger_state(trigger), if_true(t_path), if_false(f_path), 
          timeout_sec(timeout), max_retries(retries), current_retries(0), guard(g) {
        branches = new CHashMap<int, int>();
    }
          
    ~CXStepNode() { 
        SAFE_DELETE(step); 
        SAFE_DELETE(guard); 
        SAFE_DELETE(branches);
    }
    
    void AddBranch(int code, int target_state) {
        branches.Add(code, target_state);
    }
    
    int GetBranch(int code) {
        int target = -1;
        if(branches.TryGetValue(code, target)) return target;
        return -1;
    }
};

#endif
