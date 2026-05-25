#ifndef CXSEQUENCEORCHESTRATOR_MQH
#define CXSEQUENCEORCHESTRATOR_MQH

#include <Arrays\ArrayObj.mqh>
#include <Generic\HashMap.mqh>
#include "..\..\Core\Defines\CXDefine.mqh"
#include "CXSequenceRegistry.mqh"

/**
 * @class CXSequenceOrchestrator
 * @brief [v14.6] ATSE 전체 시퀀스 및 태스크 구성을 전담 관리 (String-Based DSL 지원)
 */
class CXSequenceOrchestrator : public CObject {
private:
    CArrayObj*             m_watcher_map;
    CArrayObj*             m_session_map;
    CHashMap<string, int>* m_registry;
    int                    m_auto_id_counter;

public:
    CXSequenceOrchestrator() {
        m_watcher_map = new CArrayObj();
        m_session_map = new CArrayObj();
        m_registry = new CHashMap<string, int>();
        m_auto_id_counter = 1000; // 자동 발급 ID 시작점 (표준 Enum과 겹치지 않게)
        
        RegisterStandardNames();
        InitWatcherMap();
        InitSessionMap();
    }

    ~CXSequenceOrchestrator() {
        SAFE_DELETE(m_watcher_map);
        SAFE_DELETE(m_session_map);
        SAFE_DELETE(m_registry);
    }

    void BuildWatcherSequence(CXFluentSequence* seq) {
        CXSequenceRegistry::BuildSequence(seq, m_watcher_map);
    }

    void BuildSessionSequence(CXFluentSequence* seq) {
        CXSequenceRegistry::BuildSequence(seq, m_session_map);
    }

    /**
     * @brief [v14.6] DSL 문자열 배열을 기반으로 시퀀스 맵 구성 (String -> Int 자동 변환)
     */
    void BuildFromDSL(string &SEQS[], CArrayObj* map) {
        if(IS_INVALID(map)) return;
        
        ushort node_delim = StringGetCharacter(SEQ_NODE_DELIMITER, 0);
        ushort step_delim = StringGetCharacter(SEQ_STEP_DELIMITER, 0);

        // [Pass 1] 모든 노드의 ID/이름을 먼저 등록 (Forward Reference 해결용)
        for(int i = 0; i < ArraySize(SEQS); i++) {
            string parts[];
            if(StringSplit(SEQS[i], node_delim, parts) < 1) continue;
            RegisterStateName(parts[0]);
        }

        // [Pass 2] 상세 파싱 및 연결
        for(int i = 0; i < ArraySize(SEQS); i++) {
            string parts[];
            int totalParts = StringSplit(SEQS[i], node_delim, parts);
            if(totalParts < 4) continue;
            
            int id = ResolveId(parts[0]);
            string stepInfo = parts[1];
            int next = ResolveId(parts[2]);
            int fail = ResolveId(parts[3]);
            
            // Suffix 처리 (60s -> 60, 3x -> 3)
            int timeout = (totalParts > 4) ? ParseSuffixValue(parts[4]) : 0;
            int retries = (totalParts > 5) ? ParseSuffixValue(parts[5]) : 0;
            
            string stepParts[];
            StringSplit(stepInfo, step_delim, stepParts);
            string typeStr = stepParts[0];
            string alias = (ArraySize(stepParts) > 1) ? stepParts[1] : "";
            string taskStr = (ArraySize(stepParts) > 2) ? stepParts[2] : "";
            
            ENUM_STEP_TYPE type = CXStepFactory::GetStepTypeByName(typeStr);
            if(type == STEP_NONE) {
                PrintFormat("[ORCH-ERROR] Invalid Step Type: %s in DSL Node: %s", typeStr, SEQS[i]);
                continue;
            }

            CXSequenceStep* node = new CXSequenceStep(id, type, next, fail, timeout, retries, alias);
            
            // Tasks 파싱
            string tasks[];
            if(StringSplit(taskStr, ',', tasks) > 0) {
                for(int t = 0; t < ArraySize(tasks); t++) {
                    ENUM_TASK_TYPE taskType = CXTaskFactory::GetTaskTypeByName(tasks[t]);
                    if(taskType != TASK_NONE) node.AddTask(taskType);
                }
            }
            
            // Branches (Case) 파싱 - "EXECUTED=ACTIVE" 형태 지원
            if(totalParts > 6 && parts[6] != "") {
                string cases[];
                if(StringSplit(parts[6], ',', cases) > 0) {
                    for(int c = 0; c < ArraySize(cases); c++) {
                        string kv[];
                        if(StringSplit(cases[c], '=', kv) == 2) {
                            node.Case(ResolveId(kv[0]), ResolveId(kv[1]));
                        }
                    }
                }
            }
            
            map.Add(node);
        }
    }

private:
    /**
     * @brief 표준 시스템 상태 및 결과 코드들을 레지스트리에 사전 등록
     */
    void RegisterStandardNames() {
        // XE_STATUS (Task Return Codes)
        m_registry.Add("READY",        (int)XE_READY);
        m_registry.Add("PENDING",      (int)XE_PENDING_REQ);
        m_registry.Add("TRANSIT",      (int)XE_IN_TRANSIT);
        m_registry.Add("EXECUTED",     (int)XE_EXECUTED);
        m_registry.Add("CLOSED_SIG",   (int)XE_CLOSED_SIGNAL);
        m_registry.Add("CLOSED_SL",    (int)XE_CLOSED_SL);
        m_registry.Add("CLOSED_TP",    (int)XE_CLOSED_TP);
        m_registry.Add("ERROR",        (int)XE_ERROR);

        // ST_ID (Common State Targets)
        m_registry.Add("TERMINAL",     (int)SESSION_CLOSED);
        m_registry.Add("FAIL",         (int)SESSION_ERROR);
    }

    void RegisterStateName(string name) {
        if(name == "" || IsDigit(name)) return;
        int dummy;
        if(!m_registry.TryGetValue(name, dummy)) {
            m_registry.Add(name, m_auto_id_counter++);
        }
    }

    int ResolveId(string value) {
        if(value == "") return -1;
        if(IsDigit(value)) return (int)StringToInteger(value);
        
        int id;
        if(m_registry.TryGetValue(value, id)) return id;
        
        PrintFormat("[ORCH-WARN] Unresolved State Name: %s. Using Auto-ID.", value);
        RegisterStateName(value);
        m_registry.TryGetValue(value, id);
        return id;
    }

    bool IsDigit(string str) {
        if(str == "") return false;
        for(int i = 0; i < StringLen(str); i++) {
            ushort c = StringGetCharacter(str, i);
            if(c < '0' || c > '9') return false;
        }
        return true;
    }

    int ParseSuffixValue(string val) {
        if(val == "") return 0;
        string clean = val;
        StringReplace(clean, "s", ""); // seconds
        StringReplace(clean, "x", ""); // retries
        return (int)StringToInteger(clean);
    }

    void InitWatcherMap() {
        string dsl[] = {
            "DISCOVERY  | Discovery:Step_Discovery   | VALIDATION | DISCOVERY | 0s | 0x",
            "VALIDATION | Validation:Step_Validation | BINDING    | DISCOVERY | 0s | 0x",
            "BINDING    | Binding:Step_Binding       | DISCOVERY  | DISCOVERY | 0s | 0x"
        };
        BuildFromDSL(dsl, m_watcher_map);
    }

    void InitSessionMap() {
        string dsl[] = {
            // [v14.6] Human-Readable Hyper-Atomized Entry Pipeline
            "ENTRY_LOGIC   | Composite:Step_Entry_Logic:TASK_A_INTENT_WATCH,TASK_E_L_REDIRECT,TASK_E_L_IDENTITY,TASK_E_L_RISK,TASK_E_L_PRICE,TASK_E_G_SPREAD,TASK_E_P_INTENT,TASK_E_R_ORDER | ENTRY_TRANSIT | ERROR | 300s | 0x | EXECUTED=ACTIVE,CLOSED_SIG=EXIT_LOGIC",
            "ENTRY_TRANSIT | Composite:Step_Entry_Transit:TASK_A_INTENT_WATCH,TASK_E_V_ERROR,TASK_E_V_TICKET,TASK_E_V_REAL | ENTRY_VERIFY | ERROR | 60s | 0x | CLOSED_SIG=EXIT_LOGIC",
            "ENTRY_VERIFY  | Composite:Step_Entry_Verify:TASK_A_INTENT_WATCH,TASK_E_V_DOUBLECHECK,TASK_E_P_FINALIZE | ACTIVE | ERROR | 30s | 0x | CLOSED_SIG=EXIT_LOGIC",
            
            // Pending Pipeline
            "PENDING       | Composite:Step_Pending:TASK_A_INTENT_WATCH,TASK_P_V_TERMINAL,TASK_P_P_ALIGN,TASK_P_V_SYNC,TASK_P_L_REBOUND,TASK_P_L_IMPROVE,TASK_P_R_APPLY | ACTIVE | ERROR | 3600s | 0x | EXECUTED=ACTIVE,CLOSED_SIG=EXIT_LOGIC",
            
            // Active Pipeline
            "ACTIVE        | Composite:Step_Active:TASK_A_INTENT_WATCH,TASK_A_V_STATUS,TASK_A_V_STALE,TASK_A_V_TERMINAL,TASK_A_P_ALIGN,TASK_A_L_STATUS,TASK_A_ALPHA_CALC,TASK_A_ALPHA_APPLY | ACTIVE | ERROR | 72000s | 0x | CLOSED_SIG=EXIT_LOGIC",
            
            // Liquidation Pipeline
            "EXIT_LOGIC    | Composite:Step_Exit_Logic:TASK_A_INTENT_WATCH,TASK_X_L_PREPARE,TASK_X_P_LOCK,TASK_X_R_ORDER | EXIT_TRANSIT | ERROR | 300s | 3x",
            "EXIT_TRANSIT  | Composite:Step_Exit_Transit:TASK_X_V_ERROR,TASK_X_V_TERMINAL | EXIT_VERIFY | ERROR | 60s | 0x",
            "EXIT_VERIFY   | Composite:Step_Exit_Verify:TASK_X_P_FINALIZE | TERMINAL | ERROR | 30s | 0x"
        };
        BuildFromDSL(dsl, m_session_map);
    }
};

#endif
