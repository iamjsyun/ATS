#ifndef CXSEQUENCEORCHESTRATOR_MQH
#define CXSEQUENCEORCHESTRATOR_MQH

#include <Arrays\ArrayObj.mqh>
#include <Generic\HashMap.mqh>
#include "..\..\Core\Defines\CXDefine.mqh"
#include "CXSequenceRegistry.mqh"

/**
 * @class CXSequenceOrchestrator
 * @brief [v14.8] ATSE 전체 시퀀스 및 태스크 구성을 전담 관리 (Semantic DSL 지원)
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
        m_auto_id_counter = 1000;
        
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
     * @brief [v14.8] 시맨틱 기호 기반 DSL 파서 (Whitespace-Free)
     */
    void BuildFromDSL(string &SEQS[], CArrayObj* map) {
        if(IS_INVALID(map)) return;

        // [Pass 1] 모든 노드의 Identity 등록
        for(int i = 0; i < ArraySize(SEQS); i++) {
            string nodeStr = SEQS[i];
            int firstDelim = FindFirstDelimiter(nodeStr);
            string idName = (firstDelim == -1) ? nodeStr : StringSubstr(nodeStr, 0, firstDelim);
            RegisterStateName(Clean(idName));
        }

        // [Pass 2] 기호 기반 상세 파싱
        for(int i = 0; i < ArraySize(SEQS); i++) {
            string s = SEQS[i];
            
            // 1. Identity
            int firstDelim = FindFirstDelimiter(s);
            int id = ResolveId(Clean(StringSubstr(s, 0, firstDelim)));
            
            // 2. Logic (|) & Tasks (:)
            string logicPart = GetSegment(s, "|", "?!@*");
            string stepParts[];
            StringSplit(logicPart, StringGetCharacter(":", 0), stepParts);
            
            string typeStr = Clean(stepParts[0]);
            string alias   = (ArraySize(stepParts) > 1) ? Clean(stepParts[1]) : "";
            string taskStr = (ArraySize(stepParts) > 2) ? Clean(stepParts[2]) : "";
            
            ENUM_STEP_TYPE type = CXStepFactory::GetStepTypeByName(typeStr);
            if(type == STEP_NONE) continue;

            // 3. Success (?) & Fail (!)
            int next = ResolveId(GetSegment(s, "?", "|!@*"));
            int fail = ResolveId(GetSegment(s, "!", "|?@*"));
            
            // 4. Constraints (@)
            string constStr = GetSegment(s, "@", "|?!*");
            string constParts[];
            StringSplit(constStr, StringGetCharacter(",", 0), constParts);
            int timeout = (ArraySize(constParts) > 0) ? ParseSuffixValue(constParts[0]) : 0;
            int retries = (ArraySize(constParts) > 1) ? ParseSuffixValue(constParts[1]) : 0;

            CXSequenceStep* node = new CXSequenceStep(id, type, next, fail, timeout, retries, alias);
            
            // 5. Tasks 등록
            string tasks[];
            if(StringSplit(taskStr, StringGetCharacter(",", 0), tasks) > 0) {
                for(int t = 0; t < ArraySize(tasks); t++) {
                    ENUM_TASK_TYPE taskType = CXTaskFactory::GetTaskTypeByName(Clean(tasks[t]));
                    if(taskType != TASK_NONE) node.AddTask(taskType);
                }
            }
            
            // 6. Branches (*)
            string branchStr = GetSegment(s, "*", "|?!@");
            string cases[];
            if(StringSplit(branchStr, StringGetCharacter(",", 0), cases) > 0) {
                for(int c = 0; c < ArraySize(cases); c++) {
                    string kv[];
                    if(StringSplit(cases[c], StringGetCharacter("=", 0), kv) == 2) {
                        node.Case(ResolveId(Clean(kv[0])), ResolveId(Clean(kv[1])));
                    }
                }
            }
            
            map.Add(node);
        }
    }

private:
    int FindFirstDelimiter(string s) {
        string delims = "|?!@*";
        int minPos = -1;
        for(int i=0; i<StringLen(delims); i++) {
            int pos = StringFind(s, StringSubstr(delims, i, 1));
            if(pos != -1 && (minPos == -1 || pos < minPos)) minPos = pos;
        }
        return minPos;
    }

    string GetSegment(string nodeStr, string startMarker, string endMarkers) {
        int start = StringFind(nodeStr, startMarker);
        if(start == -1) return "";
        start += StringLen(startMarker);
        
        int end = -1;
        for(int i=0; i<StringLen(endMarkers); i++) {
            int pos = StringFind(nodeStr, StringSubstr(endMarkers, i, 1), start);
            if(pos != -1 && (end == -1 || pos < end)) end = pos;
        }
        
        return (end == -1) ? StringSubstr(nodeStr, start) : StringSubstr(nodeStr, start, end - start);
    }

    string Clean(string s) {
        string res = s;
        StringReplace(res, "\n", "");
        StringReplace(res, "\r", "");
        StringReplace(res, "\t", "");
        StringTrimLeft(res);
        StringTrimRight(res);
        return res;
    }

    void RegisterStandardNames() {
        m_registry.Add("READY",        (int)XE_READY);
        m_registry.Add("PENDING",      (int)XE_PENDING_REQ);
        m_registry.Add("TRANSIT",      (int)XE_IN_TRANSIT);
        m_registry.Add("EXECUTED",     (int)XE_EXECUTED);
        m_registry.Add("CLOSED_SIG",   (int)XE_CLOSED_SIGNAL);
        m_registry.Add("CLOSED_SL",    (int)XE_CLOSED_SL);
        m_registry.Add("CLOSED_TP",    (int)XE_CLOSED_TP);
        m_registry.Add("ERROR",        (int)XE_ERROR);
        m_registry.Add("TERMINAL",     (int)SESSION_CLOSED);
        m_registry.Add("FAIL",         (int)SESSION_ERROR);
    }

    void RegisterStateName(string name) {
        if(name == "" || IsDigit(name)) return;
        int dummy;
        if(!m_registry.TryGetValue(name, dummy)) m_registry.Add(name, m_auto_id_counter++);
    }

    int ResolveId(string value) {
        string val = Clean(value);
        if(val == "") return -1;
        if(IsDigit(val)) return (int)StringToInteger(val);
        int id;
        if(m_registry.TryGetValue(val, id)) return id;
        RegisterStateName(val);
        m_registry.TryGetValue(val, id);
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
        string clean = Clean(val);
        StringReplace(clean, "s", "");
        StringReplace(clean, "x", "");
        return (int)StringToInteger(clean);
    }

    void InitWatcherMap() {
        string dsl[] = {
            "DISCOVERY  | Discovery:Step_Discovery   ? VALIDATION ! DISCOVERY @ 0s, 0x",
            "VALIDATION | Validation:Step_Validation ? BINDING    ! DISCOVERY @ 0s, 0x",
            "BINDING    | Binding:Step_Binding       ? DISCOVERY  ! DISCOVERY @ 0s, 0x"
        };
        BuildFromDSL(dsl, m_watcher_map);
    }

    void InitSessionMap() {
        string dsl[] = {
            "ENTRY_LOGIC                                                                   "
            "| Composite:Step_Entry_Logic                                                  "
            "  : TASK_A_INTENT_WATCH, TASK_E_L_REDIRECT, TASK_E_L_IDENTITY,                "
            "    TASK_E_L_RISK,       TASK_E_L_PRICE,    TASK_E_G_SPREAD,                  "
            "    TASK_E_P_INTENT,     TASK_E_R_ORDER                                       "
            "? ENTRY_TRANSIT                                                               "
            "! ERROR                                                                       "
            "@ 300s, 0x                                                                    "
            "* EXECUTED=ACTIVE, CLOSED_SIG=EXIT_LOGIC                                     ",

            "ENTRY_TRANSIT                                                                 "
            "| Composite:Step_Entry_Transit                                                "
            "  : TASK_A_INTENT_WATCH, TASK_E_V_ERROR, TASK_E_V_TICKET, TASK_E_V_REAL       "
            "? ENTRY_VERIFY                                                                "
            "! ERROR                                                                       "
            "@ 60s, 0x                                                                     "
            "* CLOSED_SIG=EXIT_LOGIC                                                       ",

            "ENTRY_VERIFY                                                                  "
            "| Composite:Step_Entry_Verify                                                 "
            "  : TASK_A_INTENT_WATCH, TASK_E_V_DOUBLECHECK, TASK_E_P_FINALIZE              "
            "? ACTIVE                                                                      "
            "! ERROR                                                                       "
            "@ 30s, 0x                                                                     "
            "* CLOSED_SIG=EXIT_LOGIC                                                       ",

            "PENDING                                                                       "
            "| Composite:Step_Pending                                                      "
            "  : TASK_A_INTENT_WATCH, TASK_P_V_TERMINAL, TASK_P_P_ALIGN, TASK_P_V_SYNC,    "
            "    TASK_P_L_REBOUND, TASK_P_L_IMPROVE, TASK_P_R_APPLY                        "
            "? ACTIVE                                                                      "
            "! ERROR                                                                       "
            "@ 3600s, 0x                                                                   "
            "* EXECUTED=ACTIVE, CLOSED_SIG=EXIT_LOGIC                                     ",

            "ACTIVE                                                                        "
            "| Composite:Step_Active                                                       "
            "  : TASK_A_INTENT_WATCH, TASK_A_V_STATUS, TASK_A_V_STALE, TASK_A_V_TERMINAL,  "
            "    TASK_A_P_ALIGN, TASK_A_L_STATUS, TASK_A_ALPHA_CALC, TASK_A_ALPHA_APPLY    "
            "? ACTIVE                                                                      "
            "! ERROR                                                                       "
            "@ 72000s, 0x                                                                  "
            "* CLOSED_SIG=EXIT_LOGIC                                                       ",

            "EXIT_LOGIC                                                                    "
            "| Composite:Step_Exit_Logic                                                   "
            "  : TASK_A_INTENT_WATCH, TASK_X_L_PREPARE, TASK_X_P_LOCK, TASK_X_R_ORDER      "
            "? EXIT_TRANSIT                                                                "
            "! ERROR                                                                       "
            "@ 300s, 3x                                                                    ",

            "EXIT_TRANSIT                                                                  "
            "| Composite:Step_Exit_Transit                                                 "
            "  : TASK_X_V_ERROR, TASK_X_V_TERMINAL                                         "
            "? EXIT_VERIFY                                                                 "
            "! ERROR                                                                       "
            "@ 60s, 0x                                                                     ",

            "EXIT_VERIFY                                                                   "
            "| Composite:Step_Exit_Verify                                                  "
            "  : TASK_X_P_FINALIZE                                                         "
            "? TERMINAL                                                                    "
            "! ERROR                                                                       "
            "@ 30s, 0x                                                                     "
        };
        BuildFromDSL(dsl, m_session_map);
    }
};
#endif
