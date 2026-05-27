# ATSE Orchestration 시퀀스 정의 논리 분석 및 위험성 정량 보고서 (v1.0)

## 1. 개요 (Executive Summary)
본 보고서는 ATSE(Active Trading Session Engine)의 핵심 오케스트레이션 프레임워크인 `CXSequenceOrchestrator`와 비즈니스 시퀀스를 선언하는 `AppOrchestrator` 간의 DSL(Domain Specific Language) 파싱 정합성 및 실행 안정성을 분석한 보고서입니다. 
분석 결과, **DSL 선언 형식과 파서 논리 간의 불일치로 인해 런타임 시 개별 태스크(Task)들이 실제로 로드되거나 실행되지 않는 치명적인 오작동 결함**이 감지되었습니다. 본 문서에서는 결함의 기술적 메커니즘을 규명하고 위험성을 정량적으로 평가하며 이에 대한 해결 방안을 제시합니다.

---

## 2. 시퀀스 정의 및 DSL 파서 논리 분석

### 2.1 DSL 파서 작동 메커니즘 (`CXSequenceOrchestrator.mqh`)
`CXSequenceOrchestrator::BuildFromDSL`은 문자열 배열을 파싱하여 단계(Stage)와 태스크(Task)를 매핑합니다.
구체적으로 콜론(`:`) 구분자를 기준으로 스테이지 정보를 분할합니다:

```cpp
string logicPart = GetSegment(s, delim, "?!@*");
string stageParts[];
StringSplit(logicPart, StringGetCharacter(":", 0), stageParts);

string typeStr = Clean(stageParts[0]);
string alias   = (ArraySize(stageParts) > 1) ? Clean(stageParts[1]) : "";
string taskStr = (ArraySize(stageParts) > 2) ? Clean(stageParts[2]) : "";
```

위 파서의 설계 사상(v14.8 Standard)은 다음과 같이 **3개의 파트(2개의 콜론)**로 구성된 문자열 구조를 가정합니다:
`"상태주소 > [Step타입(1)] : [Alias명칭(2)] : [Task목록(3)] ? 성공경로 ! 실패경로 ..."`

### 2.2 AppOrchestrator 내 DSL 정의의 모순 (`AppOrchestrator.mqh`)
그러나 현재 실무 비즈니스 로직을 구성하는 `AppOrchestrator.mqh`에서는 다음과 같이 **2개의 파트(1개의 콜론)**로 시퀀스를 정의하고 있습니다:

```cpp
// A. 대기 주문 관리 태스크 (Pending)
string pendingDsl[] = {
    "ORD_TRACKING                                                                  "
    "> Stage_OrderOptimization                                                     "
    "  : TASK_A_INTENT_WATCH, TASK_P_L_EXTREME, TASK_P_L_REBOUND, TASK_P_L_IMPROVE,  "
    "    TASK_P_R_APPLY, TASK_P_V_SYNC                                             "
    "? ORD_TRACKING                                                                "
    "! SYS_ERROR                                                                   "
    "@ 300s, 0x"
};
```

* **파서의 데이터 해석 흐름 추적**:
  1. `logicPart` 추출 결과: `"Stage_OrderOptimization : TASK_A_INTENT_WATCH, TASK_P_L_EXTREME, ..."`
  2. `:` 기준 분할 (`stageParts` 크기 = 2):
     * `stageParts[0]` = `"Stage_OrderOptimization"`
     * `stageParts[1]` = `"TASK_A_INTENT_WATCH, TASK_P_L_EXTREME, TASK_P_L_REBOUND, TASK_P_L_IMPROVE, TASK_P_R_APPLY, TASK_P_V_SYNC"`
  3. 변수 바인딩:
     * `typeStr` = `"Stage_OrderOptimization"`
     * `alias` = `"TASK_A_INTENT_WATCH, TASK_P_L_EXTREME, ..."` (태스크 목록 전체가 별칭 문자열로 주입됨)
     * `taskStr` = `""` (빈 문자열)
  4. 태스크 파싱 및 등록 결과:
     * `taskStr`이 비어 있으므로 `node.AddTask(...)` 루프가 단 한 번도 실행되지 않으며, 해당 스테이지 노드는 **0개의 태스크**를 보유하게 됩니다.

---

## 3. 코드 흐름 추적 및 영향 분석 (Data Flow & Impact)

태스크가 등록되지 않은 노드가 실제 런타임에 미치는 영향은 다음과 같습니다.

### 3.1 Composite Stage 생성 오류 (`CXStageFactory.mqh`)
`CXSequenceRegistry::BuildSequence`가 실행될 때, 아래와 같이 팩토리를 통해 스테이지 객체를 생성합니다:
```cpp
IXStage* stage = CXStageFactory::CreateStage(cfg.GetStageTypeStr(), cfg.GetName(), cfg.GetTasks());
```
이때 매개변수는 다음과 같습니다:
* `typeName` = `"Stage_OrderOptimization"`
* `alias` = `"TASK_A_INTENT_WATCH, TASK_P_L_EXTREME, ..."`
* `taskNames` = `CArrayString` (크기 = 0)

`CXStageFactory::CreateStage`는 `typeName`이 `"Stage_"`로 시작하므로 `CreateCompositeStage`를 호출합니다:
```cpp
static IXStage* CreateCompositeStage(string name, CArrayString* taskList) {
    CXCompositeStage* stage = new CXCompositeStage(name); // 이름이 태스크 목록으로 지정됨
    if(IS_VALID(taskList)) {
        for(int i = 0; i < taskList.Total(); i++) {
            IXTask* task = CXTaskFactory::CreateTask(taskList.At(i));
            if(IS_VALID(task)) stage.AddTask(task);
        }
    }
    return stage;
}
```
* **결과**: `CXCompositeStage` 객체 내부의 실제 태스크 리스트(`m_tasks`)에는 아무것도 추가되지 않으며, 스테이지의 디버그 이름만 태스크 나열 문자열로 설정됩니다.

### 3.2 런타임 실행 제어권 상실
트레이딩 엔진이 기동하여 `ORD_TRACKING` 상태 또는 `POS_MONITORING` 상태에 진입하면:
1. `CXCompositeStage::Execute`가 호출되나, 실행할 자식 태스크가 없으므로 아무런 비즈니스 로직(인텐트 감시, 트레일링 스탑, 극점 반등 보정 등)을 실행하지 않고 즉시 성공(`true`)을 반환합니다.
2. 시스템은 무한 루프 상태로 다음 주기까지 대기하지만, 실질적으로는 어떠한 상태 모니터링이나 리스크 관리 기능도 작동하지 않는 **"좀비 상태(Silent Failure)"**가 유지됩니다.

---

## 4. 오류 가능성 및 위험성 정량 평가 (Quantitative Risk Assessment)

| 평가 항목 | 위험 수준 | 정량적 지표 / 근거 | 상세 영향 분석 |
| :--- | :---: | :---: | :--- |
| **태스크 누락율** | **Critical (100%)** | 0 / 10 Tasks Loaded | `ORD_TRACKING` 및 `POS_MONITORING` 단계의 모든 태스크가 누락됨. |
| **오류 탐지 실패율** | **High (100%)** | 0% Alerts Triggered | 비즈니스 로직 실행 자체가 스킵되므로, 시스템 수준의 소프트웨어 크래시는 없지만 트레이딩 실패가 보고되지 않음. |
| **테스트 빌드 정합성** | **Fail (100%)** | 62 Compilation Errors | 단위 테스트 프레임워크인 `ATSTestRunner.mq5` 빌드 시 구형 명칭(`CXSequenceStep`) 참조로 인해 컴파일 자체가 불가능함. |
| **재정적 위험성 (Financial Drawdown)** | **Catastrophic** | Limitless | 포지션 모니터링 단계의 `TASK_A_INTENT_WATCH` 및 `TASK_A_V_TERMINAL` 미작동으로 손절(SL)/익절(TP) 감시 불능. 시장 급변 시 오더 오작동 및 강제 청산 위험 노출. |

---

## 5. 해결 방안 및 권고 사항 (Mitigation & Recommendations)

### 방안 A. 파서 유연성 향상 (추천 - Parser Level)
`CXSequenceOrchestrator.mqh` 내 파서를 수정하여 콜론(`:`) 개수가 1개(2-Part)일 때와 2개(3-Part) 이상일 때를 자동으로 구별하도록 개선합니다. 이 방식은 기존 선언 스타일의 하위 호환성을 완벽하게 보장합니다.

```diff
-            string typeStr = Clean(stageParts[0]);
-            string alias   = (ArraySize(stageParts) > 1) ? Clean(stageParts[1]) : "";
-            string taskStr = (ArraySize(stageParts) > 2) ? Clean(stageParts[2]) : "";
+            string typeStr = Clean(stageParts[0]);
+            string alias   = "";
+            string taskStr = "";
+            if(ArraySize(stageParts) == 2) {
+                // 1개의 콜론만 존재할 경우: 두 번째 파트를 태스크 목록으로 인식하고, 별칭은 타입명으로 기본 설정
+                taskStr = Clean(stageParts[1]);
+                alias = typeStr;
+            } else if(ArraySize(stageParts) > 2) {
+                // 2개 이상의 콜론이 존재할 경우 (v14.8 규격)
+                alias = Clean(stageParts[1]);
+                taskStr = Clean(stageParts[2]);
+            }
```

### 방안 B. DSL 선언 수정 (DSL Level)
`AppOrchestrator.mqh` 내의 DSL 선언부를 공식 3-Part 규격(콜론 2개)에 맞게 강제 수정합니다.

```diff
         string pendingDsl[] = {
             "ORD_TRACKING                                                                  "
-            "> Stage_OrderOptimization                                                     "
-            "  : TASK_A_INTENT_WATCH, TASK_P_L_EXTREME, TASK_P_L_REBOUND, TASK_P_L_IMPROVE,  "
+            "> Composite : Stage_OrderOptimization                                         "
+            "  : TASK_A_INTENT_WATCH, TASK_P_L_EXTREME, TASK_P_L_REBOUND, TASK_P_L_IMPROVE,  "
             "    TASK_P_R_APPLY, TASK_P_V_SYNC                                             "
```

### 방안 C. 테스트 코드 정합성 복구
`TestSequenceDSL.mqh` 등 테스트 시나리오 파일 내의 구형 심볼 지정을 복구합니다.
1. `CXSequenceStep` $\rightarrow$ `CXSequenceStage`로 치환.
2. `CXContext.mqh` 인클루드 경로 수정:
   `#include "..\..\CXTrade\Session\CXContext.mqh"` $\rightarrow$ `#include "..\..\CXTrade\Platform\Core\Models\CXContext.mqh"`
