# Architectural Standardization Report: IXStep Unification

## 1. 개요
시스템의 복잡성을 제거하고 일관된 설계 표준을 유지하기 위해, 모든 시퀀스 로직을 `IXStep` 인터페이스 기반으로 단일화(Unification)하는 전략을 채택함.

## 2. 단일화 전략의 핵심 원칙
- **All-in-IXStep**: 모든 매매 로직(진입, 감시, 청산, 그리드 등)은 반드시 `IXStep`을 구현하는 독립 클래스로 작성한다.
- **No Direct Call**: `CXTradingSession`이나 Manager 클래스 간의 직접적인 로직 호출을 금지하며, 오직 `CXFluentSequence`의 `Pulse`를 통해 인터페이스 기반으로 실행한다.
- **Context-Only Data**: 각 단계 간의 모든 데이터 공유 및 상태 전달은 `ICXContext`를 통해서만 수행한다.

## 3. 정량적 기대 효과
- **일관성(Consistency)**: 100% 인터페이스 기반 코드로 통일되어 코드 가독성 및 신규 개발자 온보딩 속도 향상.
- **안정성(Stability)**: 구체 클래스 간 결합도가 0이 되어 순환 참조 발생 가능성을 원천 차단.
- **테스트 효율**: 모든 단계를 개별적으로 Mocking하여 단위 테스트가 가능한 구조 확보.

## 4. 실행 로드맵
1. **Manager 클래스의 역할 재정의**: Manager는 로직을 직접 수행하지 않고, `IXStep`이 공통으로 사용하는 '기능 라이브러리(Service)' 역할로 축소.
2. **표준 Step 클래스군 생성**: `CXStepEntry`, `CXStepMonitor`, `CXStepExit`, `CXStepGrid` 등을 순차적으로 구현.
3. **세션 파이프라인 구성**: `CXTradingSession`에서 이들을 Fluent API로 엮어 전체 프로세스 완성.

*Date: 2026-05-13*
