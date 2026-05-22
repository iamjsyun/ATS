#ifndef CXFLUENTSEQUENCE_MQH
#define CXFLUENTSEQUENCE_MQH

#include "..\Interfaces\ICXFluentSequence.mqh"
#include "..\Interfaces\IXStep.mqh"
#include "..\Interfaces\IXGuard.mqh"
#include "..\Interfaces\CXDefine.mqh"
#include "..\Interfaces\CXMacros.mqh"
#include <Generic\HashMap.mqh>

/**
 * @class CXStepNode
 * @brief 시퀀스 노드 데이터 관리용 (Infra 전용)
 */
class CXStepNode : public CObject {
public:
    IXStep*             step;
    IXGuard*            guard; 
    int                 if_true;
    int                 if_false;
    int                 timeout_sec;
    int                 max_retries;
    int                 current_retries;
    CHashMap<int, int>* branches;

    CXStepNode(IXStep* s, int t_path, int f_path, int timeout = 0, int retries = 0, IXGuard* g = NULL) 
        : step(s), if_true(t_path), if_false(f_path), 
          timeout_sec(timeout), max_retries(retries), current_retries(0), guard(g) {
        branches = new CHashMap<int, int>();
        if(IS_INVALID(branches)) { /* Critical Error */ }
    }
          
    ~CXStepNode() { 
        SAFE_DELETE(step); 
        SAFE_DELETE(guard); 
        SAFE_DELETE(branches);
    }
};

/**
 * @class CXFluentSequence
 * @brief ATSE 고도화 로직을 반영한 인터페이스 기반 시퀀스 엔진
 */
class CXFluentSequence : public ICXFluentSequence {
private:
    ICXContext*                 m_ctx;
    int                         m_current_state;
    datetime                    m_state_entered;
    CHashMap<int, CXStepNode*>  m_map;
    string                      m_name;
    int                         m_first_state;
    
    // Log Suppression
    int                         m_last_log_from;
    int                         m_last_log_to;

    // Builder State
    int                         m_tmp_from;
    IXStep*                     m_tmp_step;
    IXGuard*                    m_tmp_guard;
    int                         m_tmp_success;
    int                         m_tmp_fail;
    int                         m_tmp_timeout;
    int                         m_tmp_retries;
    CHashMap<int, int>*         m_tmp_branches;

public:
    CXFluentSequence(ICXContext* ctx, string name) 
        : m_ctx(ctx), m_name(name), m_current_state(-1), m_tmp_from(-1), m_first_state(-1),
          m_tmp_step(NULL), m_tmp_guard(NULL), m_tmp_success(-1), m_tmp_fail(-1),
          m_tmp_timeout(0), m_tmp_retries(0), m_last_log_from(-1), m_last_log_to(-1) {
        m_tmp_branches = new CHashMap<int, int>();
        if(IS_VALID(m_tmp_branches)) {
            m_state_entered = TimeCurrent();
        }
    }
    
    ~CXFluentSequence() {
        int keys[];
        CXStepNode* values[];
        m_map.CopyTo(keys, values);
        for(int i = 0; i < ArraySize(values); i++) if(IS_VALID(values[i])) SAFE_DELETE(values[i]);
        m_map.Clear();
        SAFE_DELETE(m_tmp_branches);
    }

    //-- Fluent API
    CXFluentSequence* From(int state) { 
        CommitCurrent(); 
        m_tmp_from = state; 
        if(m_first_state == -1) m_first_state = state; 
        return GetPointer(this); 
    }
    CXFluentSequence* Execute(IXStep* step) { m_tmp_step = step; return GetPointer(this); }
    CXFluentSequence* Guard(IXGuard* guard) { m_tmp_guard = guard; return GetPointer(this); }
    CXFluentSequence* OnSuccess(int next) { m_tmp_success = next; return GetPointer(this); }
    CXFluentSequence* OnFail(int next) { m_tmp_fail = next; return GetPointer(this); }
    CXFluentSequence* Timeout(int sec) { m_tmp_timeout = sec; return GetPointer(this); }
    CXFluentSequence* Retries(int count) { m_tmp_retries = count; return GetPointer(this); }
    CXFluentSequence* Case(int code, int state) { m_tmp_branches.Add(code, state); return GetPointer(this); }

    virtual void Build() override {
        CommitCurrent();
        if(m_current_state == -1) {
            m_current_state = m_first_state;
            XP_LOG_SEQ_INFO(m_ctx.GetParam(), StringFormat("[SEQ:%s] Sequence Started at State: %d", m_name, m_current_state));
        }
        TriggerOnEnter(m_current_state);
    }

    virtual void Pulse(ICXParam* xp) override {
        CXStepNode* node = NULL;
        if(!m_map.TryGetValue(m_current_state, node) || IS_INVALID(node)) {
            return;
        }

        if(IS_VALID(node.guard) && !node.guard.Check(xp, m_ctx)) return;

        if(node.timeout_sec > 0 && (TimeCurrent() - m_state_entered > node.timeout_sec)) {
            int next = (node.if_false != -1) ? node.if_false : SESSION_ERROR;
            XP_LOG_SEQ_WARN(xp, StringFormat("[SEQ:%s] State %d Timeout (%d sec). Moving to %d", m_name, m_current_state, node.timeout_sec, next));
            UpdateState(next);
            return;
        }

        if(node.step.OnCondition(xp, m_ctx, m_current_state)) {
            int next_state = node.step.OnProcess(xp, m_ctx);
            
            if(next_state == m_current_state || next_state == -1) {
                return;
            }

            if(next_state == node.if_false && node.max_retries > 0) {
                node.current_retries++;
                if(node.current_retries <= node.max_retries) {
                    XP_LOG_SEQ_WARN(xp, StringFormat("[SEQ:%s] Step '%s' failed. Retry %d/%d...", 
                        m_name, node.step.Name(), node.current_retries, node.max_retries));
                    return;
                } else {
                    XP_LOG_SEQ_ERROR(xp, StringFormat("[SEQ:%s] Step '%s' exhausted retries. Moving to terminal fail state %d.", 
                        m_name, node.step.Name(), node.if_false));
                    node.current_retries = 0;
                    UpdateState(node.if_false);
                    return;
                }
            }

            int branch_state = -1;
            if(node.branches.TryGetValue(next_state, branch_state)) {
                XP_LOG_SEQ_DEBUG(xp, StringFormat("[SEQ:%s] Branch match: %d -> %d", m_name, next_state, branch_state));
                node.current_retries = 0;
                UpdateState(branch_state);
                return;
            }

            if(next_state != m_current_state && next_state != -1) {
                // [v11.0] Duplicate Transition Log Suppression
                if(m_current_state != m_last_log_from || next_state != m_last_log_to) {
                    XP_LOG_SEQ_TRACE(xp, StringFormat("[SEQ:%s] Transition: %d -> %d (Step: %s)", m_name, m_current_state, next_state, node.step.Name()));
                    m_last_log_from = m_current_state;
                    m_last_log_to = next_state;
                }
                
                node.current_retries = 0;
                UpdateState(next_state);
            }
        }
    }

    virtual void AddStep(int state_id, IXStep* step) override {
        CXStepNode* node = new CXStepNode(step, -1, -1);
        if(IS_VALID(node)) m_map.Add(state_id, node);
    }

    virtual int State() const override { return m_current_state; }
    virtual void ForceState(int state) override { UpdateState(state); }

    string GetSequenceName() const { return m_name; }
    int    GetNodeCount() { return m_map.Count(); }
    string GetStateSummary() {
        int keys[]; CXStepNode* values[];
        m_map.CopyTo(keys, values);
        string summary = "";
        for(int i=0; i<ArraySize(keys); i++) {
            string stateName = (string)keys[i];
            if(m_name == "SessionSeq") stateName = EnumToString((ENUM_SESSION_STATE)keys[i]);
            else if(m_name == "WatcherSeq") stateName = EnumToString((ENUM_WATCHER_STATE)keys[i]);
            summary += (summary == "" ? "" : ", ") + StringFormat("%d:%s", keys[i], stateName);
        }
        return summary;
    }

private:
    void CommitCurrent() {
        if(m_tmp_from == -1 || IS_INVALID(m_tmp_step)) return;
        CXStepNode* node = new CXStepNode(m_tmp_step, m_tmp_success, m_tmp_fail, m_tmp_timeout, m_tmp_retries, m_tmp_guard);
        if(IS_INVALID(node)) return;
        
        int b_keys[]; int b_values[];
        m_tmp_branches.CopyTo(b_keys, b_values);
        for(int i = 0; i < ArraySize(b_keys); i++) node.branches.Add(b_keys[i], b_values[i]);
        m_tmp_branches.Clear();

        m_map.Add(m_tmp_from, node);
        m_tmp_from = -1; m_tmp_step = NULL; m_tmp_guard = NULL; m_tmp_success = -1; m_tmp_fail = -1;
    }

    void UpdateState(int next) {
        if(m_current_state == next) return;
        if(!ValidateTransition(m_current_state, next)) {
            XP_LOG_SEQ_ERROR(m_ctx.GetParam(), StringFormat("[SEQ:%s] CRITICAL: Illegal Transition Blocked (%d -> %d)", m_name, m_current_state, next));
            return;
        }
        TriggerOnExit(m_current_state);
        m_current_state = next;
        m_state_entered = TimeCurrent();
        TriggerOnEnter(m_current_state);
    }

    bool ValidateTransition(int from, int to) {
        if(to == SESSION_ERROR || to == 99) return true;
        if(from == -1) return true;
        if(m_name != "SessionSeq") return true;
        if(from == SESSION_CLOSED || from == SESSION_ERROR) return false;
        if(from == SESSION_READY) return (to == STATE_ENTRY_TRAILING || to == SESSION_ACTIVE || to == SESSION_LIQUIDATING || to == 3 || to == 4);
        if(from == STATE_ENTRY_TRAILING) return (to == SESSION_ACTIVE || to == SESSION_LIQUIDATING);
        if(from == SESSION_ACTIVE) return (to == SESSION_LIQUIDATING || to == STATE_EXIT_TRAILING || to == 12 || to == 15);
        if(from == SESSION_LIQUIDATING) return (to == STATE_EXIT_SWEEP || to == STATE_EXIT_VERIFY || to == SESSION_CLOSED || to == 21 || to == 22 || to == 23);
        return true; 
    }

    void TriggerOnEnter(int state) {
        CXStepNode* node = NULL;
        if(m_map.TryGetValue(state, node) && IS_VALID(node)) node.step.OnEnter(m_ctx);
    }

    void TriggerOnExit(int state) {
        CXStepNode* node = NULL;
        if(m_map.TryGetValue(state, node) && IS_VALID(node)) node.step.OnExit(m_ctx);
    }
};

#endif
