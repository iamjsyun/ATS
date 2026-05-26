#ifndef TEST_SEQUENCE_DSL_MQH
#define TEST_SEQUENCE_DSL_MQH

#include "..\..\CXTrade\Platform\Core\Sequence\CXSequenceOrchestrator.mqh"
#include "..\..\CXTrade\Platform\Core\Sequence\CXFluentSequence.mqh"
#include "..\..\CXTrade\Session\CXContext.mqh"

class TestSequenceDSL {
public:
    static bool Run() {
        Print("--- Running TestSequenceDSL ---");
        bool allPassed = true;
        
        CXSequenceOrchestrator orchestrator;
        CXContext ctx;
        CXFluentSequence seq(GetPointer(ctx), "TestSeq");

        // Test Case 1: Session Sequence Build from DSL (Implicitly calls InitPendingMap, InitActiveMap, InitExitMap)
        orchestrator.BuildSessionSequence(GetPointer(seq));
        
        // Check node count (Should match the total number of nodes in session maps)
        // Entry(3) + Pending(1) + Active(1) + Exit(3) = 8 nodes
        if (seq.GetNodeCount() == 8) {
            Print("  [PASS] Session sequence built with 8 nodes.");
        } else {
            PrintFormat("  [FAIL] Expected 8 nodes, got %d", seq.GetNodeCount());
            allPassed = false;
        }

        // Test Case 2: Custom DSL Build
        CArrayObj customMap;
        string customDsl[] = {
            "0|Composite:TestStep:TASK_E_L_VALIDATE|1|99|10|5|10=10"
        };
        orchestrator.BuildFromDSL(customDsl, GetPointer(customMap));
        
        if (customMap.Total() == 1) {
            CXSequenceStep* step = CX_CAST(CXSequenceStep, customMap.At(0));
            if (step.GetStateId() == 0 && step.GetName() == "TestStep" && step.GetTimeout() == 10 && step.GetRetries() == 5) {
                Print("  [PASS] Custom DSL parsed correctly.");
            } else {
                Print("  [FAIL] Custom DSL node data mismatch.");
                allPassed = false;
            }
        } else {
            PrintFormat("  [FAIL] Expected 1 custom node, got %d", customMap.Total());
            allPassed = false;
        }

        return allPassed;
    }
};

#endif
