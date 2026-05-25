#ifndef CXSEQUENCEREGISTRY_MQH
#define CXSEQUENCEREGISTRY_MQH

#include <Arrays\ArrayObj.mqh>
#include <Arrays\ArrayString.mqh>
#include "CXFluentSequence.mqh"
#include "CXSequenceStep.mqh"
#include "CXStepFactory.mqh"

/**
 * @class CXSequenceRegistry
 * @brief [v16.6] CXSequenceStep 리스트를 기반으로 CXFluentSequence를 조립 (Enum-less)
 */
class CXSequenceRegistry {
public:
    static void BuildSequence(CXFluentSequence* seq, CArrayObj* map) {
        if(IS_INVALID(seq) || IS_INVALID(map)) return;

        for(int i = 0; i < map.Total(); i++) {
            CXSequenceStep* cfg = CX_CAST(CXSequenceStep, map.At(i));
            if(IS_INVALID(cfg)) continue;

            // [v16.6] StepFactory에 문자열 명칭을 직접 전달
            IXStep* step = CXStepFactory::CreateStep(cfg.GetStepTypeStr(), cfg.GetName(), cfg.GetTasks());
            if(IS_VALID(step)) {
                seq.From(cfg.GetStateId())
                   .Execute(step)
                   .OnSuccess(cfg.GetNextId())
                   .OnFail(cfg.GetFailId())
                   .Timeout(cfg.GetTimeout())
                   .Retries(cfg.GetRetries());

                //--- [Branches] Case 분기 적용
                CHashMap<int, int>* branches = cfg.GetBranches();
                if(IS_VALID(branches)) {
                    int b_keys[]; int b_values[];
                    branches.CopyTo(b_keys, b_values);
                    for(int k = 0; k < ArraySize(b_keys); k++) {
                        seq.Case(b_keys[k], b_values[k]);
                    }
                }
            }
        }
        seq.Build();
    }
};

#endif
