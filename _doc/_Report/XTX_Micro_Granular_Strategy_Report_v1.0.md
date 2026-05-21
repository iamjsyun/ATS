# [보고서] 초정밀(Granular) Partial Class 설계 및 구조화 방안

## 1. 개요
이전 제안된 표준 4분할(Core, Seq, Logic, Events) 구조를 넘어, **수천~수만 라인 단위의 초대형 서비스나 복잡한 상태 머신**을 극도로 세분화하여 관리하는 "초정밀(Micro-Granular)" 설계 방안입니다. 
AI가 코드 문맥(Context)을 100~300라인 수준으로만 유지하며 초고속/초저비용으로 코딩할 수 있도록 최적화되었습니다.

## 2. 초정밀 파일명 규칙 (Micro-Granular Suffixes)

단일 서비스(`XTradePolicyService`)를 예시로 한 세분화 모델입니다.

| 그룹 | 접미사 패턴 | 포함 내용 | AI 로드 목적 |
| :--- | :--- | :--- | :--- |
| **기반** | `.cs` | 클래스 선언, 의존성 주입(DI), 상수, 멤버 변수 | 의존성 및 상태 데이터 확인 |
| | `.Models.cs` | 해당 클래스 전용 내부 모델 (DTO, Struct, Enum) | 자료 구조 확인 |
| **흐름** | `.Seq.cs` | FluentSeq 파이프라인 뼈대 설정 | 전체 처리 흐름 파악 |
| **단일 상태**| `.State.[StateName].cs` | 특정 상태(State)의 진입(OnEntry), 이탈(OnExit) 로직 | 특정 상태 단독 수정 시 |
| **정책** | `.Validations.cs` | 조건 검사, Rule 기반 거부/승인 로직 (Guard) | 정책 위반/방어 로직 수정 |
| **데이터** | `.Db.cs` | DB 쿼리, Repository 호출 및 영속성 처리 | 스키마 맵핑 및 저장 방식 변경 |
| **인터페이스**| `.Ui.cs` | UI와의 바인딩 헬퍼, ViewModel 연계 로직 | 뷰/표현 계층 인터페이스 수정 |
| | `.Events.cs` | 콜백, TTS 출력, 로그, 외부 시스템 통지 | 외부 파급 효과(Side Effect) 제어 |

---

## 3. 구체적 예시: `XTradePolicyService` 초정밀 분리

복잡한 트레이딩 정책을 검증하고 실행하는 서비스를 다음과 같이 분할합니다.

### A. 기반 및 시퀀스
- `XTradePolicyService.cs` : 서비스 기본 껍데기
- `XTradePolicyService.Models.cs` : 내부 판정용 임시 객체 (`PolicyResult`, `TradeLimitInfo` 등)
- `XTradePolicyService.Seq.cs` : `InitSequence()` - Idle -> CheckLimit -> MarginCalc -> Confirm

### B. 상태별 완전 독립 (가장 강력한 강점)
시퀀스의 각 단계가 복잡할 경우, 상태 하나당 파일을 하나씩 부여합니다.
- `XTradePolicyService.State.CheckLimit.cs` : 진입 제한(Limit) 도달 여부만 전문적으로 판정
- `XTradePolicyService.State.MarginCalc.cs` : 증거금/로트 계산 수식만 전담
- `XTradePolicyService.State.Confirm.cs` : 최종 승인 처리 로직

### C. 횡단 관심사 분리
- `XTradePolicyService.Validations.cs` : `IsSnoValid()`, `IsMarginSafe()` 등 순수 검증용 bool 함수들 모음
- `XTradePolicyService.Db.cs` : `SavePolicyLog()`, `LoadUserMargin()` 등 저장소 접근 로직
- `XTradePolicyService.Events.cs` : `OnPolicyRejected` 이벤트, 알림 발송

---

## 4. 장단점 심층 분석

### 장점 (Pros)
1. **극강의 AI 토큰 효율 (S-Tier)**: "증거금 계산 로직 오류 수정" 요청 시, AI는 오직 `...State.MarginCalc.cs`와 `...Models.cs` 두 개만 읽으면 완벽하게 작업 가능.
2. **SRP (단일 책임 원칙) 강제**: 파일이 기능별로 나뉘어 있어 개발자/AI 모두 실수로 다른 로직을 오염시킬 확률이 0%에 수렴.
3. **독립 테스트 용이**: 특정 Validations 파일에 있는 순수 함수들만 떼어서 유닛 테스트하기 매우 좋음.

### 단점 (Cons)
1. **파일 파편화 극대화**: 1개의 클래스가 8~10개의 파일로 쪼개짐. 솔루션 탐색기가 매우 길어질 수 있음. (Visual Studio의 "파일 중첩(File Nesting)" 기능으로 해결 가능)
2. **코드 추적 비용**: 변수의 선언부(`.cs`)와 사용부(`.State.XXX.cs`)가 달라 인간 개발자가 코드를 추적할 때 여러 탭을 열어야 함.

## 5. 최종 결론
이 **"초정밀(Micro-Granular)"** 설계는 **"복잡도가 매우 높은 엔진 코어 (XTX 핵심 모듈)"**에만 선택적으로 적용하는 것을 권장합니다.
- **표준 4분할 (이전 제안)**: 일반적인 UI 뷰모델, 단순 CRUD 서비스
- **초정밀 다중 분할 (본 제안)**: `XSyncWorker`, `XGatewayService`, `XTradePolicyService` 등 1,000라인 이상의 핵심 파이프라인 클래스

이 구조를 채택하면, AI는 마치 메스(Scalpel)처럼 정확하게 필요한 로직의 맹점만 수술할 수 있게 됩니다.