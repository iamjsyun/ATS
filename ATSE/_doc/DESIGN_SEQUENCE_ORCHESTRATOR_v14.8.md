# [Design] Advanced Sequence Orchestration (v14.8)

## 1. 개요 (Overview)
기존의 숫자 기반 DSL(Domain Specific Language)을 인간 중심의 시맨틱(Semantic) 구조로 고도화한다. 모든 상태 ID는 문자열로 관리되며, 성공(`?`), 실패(`!`), 제약(`@`), 분기(`*`)를 나타내는 전용 델리미터를 도입하여 시퀀스 설계의 가시성과 안정성을 극대화한다.

## 2. 핵심 설계 원칙 (Core Principles)
1.  **Semantic Visibility**: 기호(`?`, `!`, `@`)만 보고도 워크플로우의 논리 구조를 즉시 파악할 수 있어야 한다.
2.  **Zero-Magic Numbers**: 모든 상태 식별은 문자열 이름을 통해 수행되며, 파서가 이를 내부 ID로 자동 변환한다.
3.  **Whitespace-Free Parsing**: 멀티라인 및 자유로운 인덴트를 지원하여 코드 자체가 아키텍처 명세서 역할을 수행한다.

## 3. DSL 문법 표준 (v14.8 Standard)

### 3.1 델리미터(Delimiter) 정의
| 기호 | 명칭 | 의미 | 상세 설명 |
| :---: | :--- | :--- | :--- |
| `|` | **Logic** | 스텝 및 태스크 정의 | 실행할 Step 타입과 Atomic Task 리스트를 정의 |
| `:` | **Task** | 태스크 구분자 | Composite 스텝 내의 개별 태스크들을 나열 |
| `?` | **Success** | 성공(True) 경로 | 모든 태스크 완료 시 이동할 다음 상태 이름 |
| `!` | **Failure** | 실패(False) 경로 | 에러 발생 시 이동할 상태 이름 (주로 ERROR) |
| `@` | **Constraint** | 제약 조건 | 타임아웃(`s`) 및 재시도 횟수(`x`) 통합 정의 |
| `*` | **Branch** | 예외 분기 | 특정 상태 코드 반환 시 즉시 이동할 지름길 주소 |

### 3.2 작성 예시 (Hierarchy Structure)
```cpp
"ENTRY_LOGIC                                   " // 현재 주소
"| Composite:Step_Entry_Logic                  " // 실행 로직
"  : TASK_A_INTENT_WATCH, TASK_E_L_RISK, ...   " // 태스크 목록
"? ENTRY_TRANSIT                               " // 성공 시 이동
"! ERROR                                       " // 실패 시 이동
"@ 300s, 0x                                    " // 제약 조건 (5분, 0회)
"* EXECUTED=ACTIVE, CLOSED_SIG=EXIT_LOGIC     "; // 분기 조건
```

## 4. 파서 구현 메커니즘 (Internal Logic)

### 4.1 State Registry (ID Resolution)
- **1-Pass**: DSL 문자열을 순회하며 모든 고유 상태 이름(예: `"ENTRY_LOGIC"`)을 추출하여 고유한 정수 ID를 자동 할당한다.
- **2-Pass**: 등록된 ID 맵을 바탕으로 `Next`, `Fail`, `Case` 주소를 실제 정수 ID로 치환하여 `CXFluentSequence` 엔진에 주입한다.

### 4.2 Suffix Parser
- `s` : 초(Seconds) 단위로 인식하여 정수형으로 변환.
- `x` : 횟수(Times) 단위로 인식하여 정수형으로 변환.

## 5. 기대 효과 (Advantages)
1.  **유지보수 혁신**: 새로운 상태 추가 시 전역 헤더(`CXDefine.mqh`) 수정 없이 DSL 배열 수정만으로 즉시 적용 가능하다.
2.  **휴먼 에러 차단**: 성공(`?`)과 실패(`!`) 경로가 시각적으로 명확히 분리되어 논리 오류를 사전에 방지한다.
3.  **아키텍처 가시성**: 시퀀스 정의부 자체가 시스템의 실시간 설계도(Living Documentation) 역할을 수행한다.

---
**Last Updated**: 2026-05-24 (v14.8)
