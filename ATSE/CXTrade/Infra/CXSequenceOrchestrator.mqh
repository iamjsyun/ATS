#ifndef CXSEQUENCEORCHESTRATOR_MQH
#define CXSEQUENCEORCHESTRATOR_MQH

#include <Arrays\ArrayObj.mqh>
#include "..\Interfaces\CXDefine.mqh"
#include "..\Infra\CXSequenceRegistry.mqh"

/**
 * @class CXSequenceOrchestrator
 * @brief ATSE 전체 시퀀스 및 태스크 구성을 전담 관리 (SSOT/SSOC 완성)
 */
class CXSequenceOrchestrator : public CObject {
private:
    CArrayObj* m_watcher_map;
    CArrayObj* m_session_map;

public:
    CXSequenceOrchestrator() {
        m_watcher_map = new CArrayObj();
        m_session_map = new CArrayObj();
        InitWatcherMap();
        InitSessionMap();
    }

    ~CXSequenceOrchestrator() {
        SAFE_DELETE(m_watcher_map);
        SAFE_DELETE(m_session_map);
    }

    void BuildWatcherSequence(CXFluentSequence* seq) {
        CXSequenceRegistry::BuildSequence(seq, m_watcher_map);
    }

    void BuildSessionSequence(CXFluentSequence* seq) {
        CXSequenceRegistry::BuildSequence(seq, m_session_map);
    }

    /**
     * @brief [v11.4] DSL 문자열 배열을 기반으로 시퀀스 맵 구성
     */
    void BuildFromDSL(string &SEQS[], CArrayObj* map) {
        if(IS_INVALID(map)) return;
        
        ushort node_delim = StringGetCharacter(SEQ_NODE_DELIMITER, 0);
        ushort step_delim = StringGetCharacter(SEQ_STEP_DELIMITER, 0);

        for(int i = 0; i < ArraySize(SEQS); i++) {
            string parts[];
            int totalParts = StringSplit(SEQS[i], node_delim, parts);
            if(totalParts < 4) continue;
            
            int id = (int)StringToInteger(parts[0]);
            string stepInfo = parts[1];
            int next = (int)StringToInteger(parts[2]);
            int fail = (int)StringToInteger(parts[3]);
            int timeout = (totalParts > 4) ? (int)StringToInteger(parts[4]) : 0;
            int retries = (totalParts > 5) ? (int)StringToInteger(parts[5]) : 0;
            
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
            
            // Tasks
            string tasks[];
            if(StringSplit(taskStr, ',', tasks) > 0) {
                for(int t = 0; t < ArraySize(tasks); t++) {
                    ENUM_TASK_TYPE taskType = CXTaskFactory::GetTaskTypeByName(tasks[t]);
                    if(taskType != TASK_NONE) node.AddTask(taskType);
                }
            }
            
            // Branches (Optional Case)
            if(totalParts > 6 && parts[6] != "") {
                string cases[];
                if(StringSplit(parts[6], ',', cases) > 0) {
                    for(int c = 0; c < ArraySize(cases); c++) {
                        string kv[];
                        if(StringSplit(cases[c], '=', kv) == 2) {
                            node.Case((int)StringToInteger(kv[0]), (int)StringToInteger(kv[1]));
                        }
                    }
                }
            }
            
            map.Add(node);
        }
    }

private:
    void InitWatcherMap() {
        string dsl[] = {
            "0|Discovery|1|0|0|0",
            "1|Validation|2|0|0|0",
            "2|Binding|0|0|0|0"
        };
        BuildFromDSL(dsl, m_watcher_map);
    }

    void InitSessionMap() {
        string dsl[] = {
            // 1. Entry Pipeline (v11.5: Hyper-Atomized)
            "0|Composite:Step_Entry_Logic:TASK_E_L_REDIRECT,TASK_E_L_IDENTITY,TASK_E_L_RISK,TASK_E_L_PRICE,TASK_E_G_SPREAD,TASK_E_G_VOLATILITY,TASK_E_P_INTENT,TASK_E_R_ORDER|1|99|300|0|10=10,20=20",
            "1|Composite:Step_Entry_Transit:TASK_A_INTENT_WATCH,TASK_E_V_ERROR,TASK_E_V_TICKET,TASK_E_V_REAL|2|99|60|0|20=20",
            "2|Composite:Step_Entry_Verify:TASK_E_V_DOUBLECHECK,TASK_E_P_FINALIZE|10|99|30|0|20=20",
            
            // 2. Pending Pipeline
            "5|Composite:Step_Pending:TASK_A_INTENT_WATCH,TASK_P_V_TERMINAL,TASK_P_P_ALIGN,TASK_P_V_SYNC,TASK_P_L_REBOUND,TASK_P_L_IMPROVE,TASK_P_R_APPLY|10|99|3600|0|20=20",
            
            // 3. Active Pipeline
            "10|Composite:Step_Active:TASK_A_INTENT_WATCH,TASK_A_V_STATUS,TASK_A_V_STALE,TASK_A_V_TERMINAL,TASK_A_P_ALIGN,TASK_A_L_STATUS,TASK_A_ALPHA_CALC,TASK_A_ALPHA_APPLY|10|99|72000|0|20=20",
            
            // 4. Liquidation Pipeline
            "20|Composite:Step_Exit_Logic:TASK_X_L_PREPARE,TASK_X_P_LOCK,TASK_X_R_ORDER|21|99|300|3",
            "21|Composite:Step_Exit_Transit:TASK_X_V_ERROR,TASK_X_V_TERMINAL|23|99|60|0",
            "23|Composite:Step_Exit_Verify:TASK_X_P_FINALIZE|30|99|30|0"
        };
        BuildFromDSL(dsl, m_session_map);
    }
};

#endif
