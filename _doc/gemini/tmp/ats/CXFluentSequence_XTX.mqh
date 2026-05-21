//+------------------------------------------------------------------+
//|                                            CXFluentSequence.mqh |
//|                                  Copyright 2026, Gemini CLI      |
//| [v7.3] High-Performance Fluent Sequence Orchestrator             |
//+------------------------------------------------------------------+
#ifndef CX_FLUENT_SEQUENCE_MQH
#define CX_FLUENT_SEQUENCE_MQH

#include "IXStep.mqh"
#include <Generic\HashMap.mqh>

/**
 * @class CXFluentSequence
 * @brief O(1) 상태 매핑 및 가독성 높은 Fluent API를 제공하는 시퀀스 엔진
 */
class CXFluentSequence : public CObject {
private:
    CXContext*                      m_ctx;
    int                             m_current_state;
    datetime                        m_state_entered;
    CHashMap<int, CXStepNode*>      m_map;
    string                          m_name;
    string                          m_storage_key;
    bool                            m_use_persistence;

    // Builder용 임시 상태
    int                             m_tmp_from;
    IXStep*                         m_tmp_step;
    IXGuard*                        m_tmp_guard;
    int                             m_tmp_success;
    int                             m_tmp_fail;
    int                             m_tmp_timeout;
    int                             m_tmp_retries;
    CHashMap<int, int>*             m_tmp_branches; 
    bool                            m_snapshot_enabled; 
    string                          m_snapshot_path;

public:
    CXFluentSequence(CXContext* ctx, string name, bool use_save = true) 
        : m_ctx(ctx), m_name(name), m_use_persistence(use_save),
          m_current_state(-1),
          m_tmp_from(-1), m_tmp_step(NULL), m_tmp_guard(NULL), m_tmp_success(-1), 
          m_tmp_fail(-1), m_tmp_timeout(0), m_tmp_retries(0),
          m_snapshot_enabled(false), m_snapshot_path("") {
        
        m_tmp_branches = new CHashMap<int, int>();
        m_storage_key = "XFSEQ_" + name + "_" + _Symbol;
        m_state_entered = TimeCurrent();
        
        if(m_use_persistence && GlobalVariableCheck(m_storage_key)) {
            m_current_state = (int)GlobalVariableGet(m_storage_key);
        }
    }
    
    ~CXFluentSequence() {
        int keys[];
        CXStepNode* values[];
        m_map.CopyTo(keys, values);
        for(int i = 0; i < ArraySize(values); i++) {
            if(IS_VALID(values[i])) SAFE_DELETE(values[i]);
        }
        m_map.Clear();
        SAFE_DELETE(m_tmp_branches);
    }

    static CXFluentSequence* Create(CXContext* ctx, string name, bool use_save = true) {
        return new CXFluentSequence(ctx, name, use_save);
    }

    CXFluentSequence* From(int state) { 
        CommitCurrent(); 
        m_tmp_from = state; 
        if(m_current_state == -1) m_current_state = state;
        return GetPointer(this); 
    }

    CXFluentSequence* Execute(IXStep* step) { 
        m_tmp_step = step; 
        return GetPointer(this); 
    }

    CXFluentSequence* Guard(IXGuard* guard) { 
        m_tmp_guard = guard;
        return GetPointer(this);
    }

    CXFluentSequence* OnSuccess(int next_state) { 
        m_tmp_success = next_state; 
        return GetPointer(this); 
    }

    CXFluentSequence* Case(int result_code, int target_state) { 
        m_tmp_branches.Add(result_code, target_state);
        return GetPointer(this);
    }

    CXFluentSequence* OnFail(int error_state) { 
        m_tmp_fail = error_state; 
        return GetPointer(this); 
    }

    CXFluentSequence* Timeout(int sec) { 
        m_tmp_timeout = sec; 
        return GetPointer(this); 
    }

    CXFluentSequence* Retries(int count) { 
        m_tmp_retries = count; 
        return GetPointer(this); 
    }

    CXFluentSequence* EnableSnapshot(string path="") { 
        m_snapshot_enabled = true;
        m_snapshot_path = (path == "") ? StringFormat("XFSEQ_SNAP_%s.log", m_name) : path;
        return GetPointer(this);
    }

    CXFluentSequence* Build() {
        CommitCurrent();
        Validate();
        TriggerOnEnter(m_current_state);
        return GetPointer(this);
    }

    CXResult Pulse(CXParam* xp) {
        CXStepNode* node = NULL;
        if(!m_map.TryGetValue(m_current_state, node) || node == NULL) {
            if(m_current_state != SESSION_CLOSED && m_current_state != SESSION_ERROR) {
                IXLogService* log_svc = (xp != NULL) ? xp.log_svc : NULL;
                if(log_svc != NULL) log_svc.Error(xp, StringFormat("[XFSEQ-DEADEND] Current state %d has no definition!", m_current_state));
                UpdateState(SESSION_ERROR);
            }
            return CXResult::Pending("Idle");
        }

        IXLogService* log_svc = (xp != NULL) ? xp.log_svc : NULL;

        if(IS_VALID(node.guard) && !node.guard.Check(xp, m_ctx)) {
            return CXResult::Pending(node.guard.Message());
        }

        if(node.timeout_sec > 0 && (TimeCurrent() - m_state_entered > node.timeout_sec)) {
            int next = (node.if_false != -1) ? node.if_false : SESSION_ERROR;
            UpdateState(next);
            return CXResult::Failed("Timeout");
        }

        if(node.step.OnCondition(xp, m_ctx, m_current_state)) {
            CXResult res = node.step.OnProcess(xp, m_ctx);
            
            int target_via_branch = node.GetBranch(res.ErrorCode());
            if(target_via_branch != -1) {
                node.current_retries = 0;
                UpdateState(target_via_branch);
                return res;
            }

            if(res.IsFailed()) {
                if(node.max_retries > 0 && node.current_retries < node.max_retries) {
                    node.current_retries++;
                    return res; 
                }
                UpdateState((node.if_false != -1) ? node.if_false : SESSION_ERROR);
            }
            else if(res.IsSuccess()) {
                node.current_retries = 0;
                UpdateState(node.if_true);
            }
            return res;
        }

        return CXResult::Pending("Waiting Condition");
    }

    int State() const { return m_current_state; }

    void ForceState(int next_state) {
        UpdateState(next_state);
    }

private:
    void CommitCurrent() {
        if(m_tmp_from != -1 && m_tmp_step != NULL) {
            CXStepNode* node = new CXStepNode(m_tmp_step, m_tmp_from, m_tmp_success, m_tmp_fail, m_tmp_timeout, m_tmp_retries, m_tmp_guard);
            
            int b_keys[];
            int b_values[];
            m_tmp_branches.CopyTo(b_keys, b_values);
            for(int i = 0; i < ArraySize(b_keys); i++) {
                node.AddBranch(b_keys[i], b_values[i]);
            }
            m_tmp_branches.Clear();

            m_map.Add(m_tmp_from, node);
            
            m_tmp_step = NULL;
            m_tmp_guard = NULL;
            m_tmp_success = -1;
            m_tmp_fail = -1;
            m_tmp_timeout = 0;
            m_tmp_retries = 0;
        }
    }

    void UpdateState(int new_state) {
        if(m_current_state == new_state) return;
        TriggerOnExit(m_current_state);
        int old_state = m_current_state;
        m_current_state = new_state;
        m_state_entered = TimeCurrent();
        if(m_use_persistence) GlobalVariableSet(m_storage_key, (double)m_current_state);
        TriggerOnEnter(m_current_state);
    }

    void TriggerOnEnter(int state) {
        CXStepNode* node = NULL;
        if(m_map.TryGetValue(state, node) && node != NULL) node.step.OnEnter(m_ctx);
    }

    void TriggerOnExit(int state) {
        CXStepNode* node = NULL;
        if(m_map.TryGetValue(state, node) && node != NULL) node.step.OnExit(m_ctx);
    }
    
    void Validate() {
        int errors = 0;
        int warnings = 0;

        if(!m_map.ContainsKey(m_current_state)) {
            errors++;
        }

        int keys[];
        CXStepNode* values[];
        m_map.CopyTo(keys, values);
        for(int i = 0; i < ArraySize(keys); i++) {
            CXStepNode* node = values[i];
            if(node == NULL) continue;

            if(!IsStateValid(node.if_true)) {
                warnings++;
            }

            if(node.if_false != -1 && !IsStateValid(node.if_false)) {
                warnings++;
            }
            
            if(node.if_true == keys[i] && node.timeout_sec == 0) {
                warnings++;
            }
        }
    }
    
    bool IsStateValid(int state) {
        if(state == SESSION_CLOSED || state == SESSION_ERROR || state == -1) return true;
        return m_map.ContainsKey(state);
    }
};
#endif
