# [Design] Centralized Sequence Orchestrator (v1.0)

## 1. 개요 (Overview)
ATSE 프로젝트 내의 모든 워크플로우(Watcher, Session 등) 조립을 전담하는 중앙 관리 클래스 `CXSequenceOrchestrator`를 도입한다. 기존 개별 모듈(`CXTradingSession`, `CXSignalWatcher`) 내부에 하드코딩되어 있던 `InitSequence()` 로직을 완전히 제거하고, Orchestrator가 데이터(Enum Matrix)를 기반으로 시퀀스를 조립하여 주입(Inject)하는 구조로 전환한다.

## 2. 설계 원칙 (Design Principles)
1.  **Single Responsibility**: 시퀀스의 생성 및 조립 책임만 가진다.
2.  **No Magic Numbers**: 모든 상태 식별자, 스텝 유형, 타임아웃은 `enum`으로 정의된다.
3.  **Decoupling**: 시퀀스 실행기(`CXFluentSequence`)와 비즈니스 로직을 분리한다.

## 3. 구조 설계 (Architecture)

### 3.1 전역 Enum 정의 (`CXSequenceDefine.mqh`)
마법의 숫자를 제거하기 위한 전역 열거형 집합이다.
```cpp
//--- 스텝 유형 정의 (StepFactory 용)
enum ENUM_STEP_TYPE {
    STEP_NONE = 0,
    // Watcher Steps
    STEP_DISCOVERY,
    STEP_VALIDATION,
    STEP_BINDING,
    // Session Steps (Entry)
    STEP_ENTRY_LOGIC,
    STEP_ENTRY_ORDER,
    // Session Steps (Active/Exit)
    STEP_ACTIVE_MONITOR,
    STEP_EXIT_LOGIC,
    STEP_ERROR_HANDLER
};

//--- 공통 상태 주소 정의 (State ID)
enum ENUM_STATE_ID {
    ST_DISCOVERY = 10,
    ST_VALIDATION = 20,
    ST_BINDING = 30,
    ST_ENTRY_LOGIC = 100,
    ST_ENTRY_ORDER = 110,
    ST_ACTIVE_MONITOR = 200,
    ST_EXIT_LOGIC = 300,
    ST_ERROR = 999,
    ST_TERMINAL = 1000
};

//--- 타임아웃 정의
enum ENUM_TIMEOUT {
    T_NONE = 0,
    T_SHORT = 30,
    T_NORMAL = 3600,
    T_LONG = 72000
};
```

### 3.2 조립 전담 클래스 (`CXSequenceOrchestrator.mqh`)
모든 시퀀스 맵을 관리하고 `CXFluentSequence` 인스턴스에 주입하는 역할을 수행한다.

```cpp
class CXSequenceOrchestrator {
private:
    CArrayObj* m_watcher_map;
    CArrayObj* m_session_map;

    void InitWatcherMap() {
        m_watcher_map = new CArrayObj();
        //                현재 상태,        실행 스텝 유형,      성공 시 이동,    실패 시 이동,  타임아웃
        m_watcher_map.Add(new CXSequenceStep(ST_DISCOVERY,  STEP_DISCOVERY,  ST_VALIDATION, ST_DISCOVERY,  T_NONE));
        m_watcher_map.Add(new CXSequenceStep(ST_VALIDATION, STEP_VALIDATION, ST_BINDING,    ST_DISCOVERY,  T_NONE));
        m_watcher_map.Add(new CXSequenceStep(ST_BINDING,    STEP_BINDING,    ST_DISCOVERY,  ST_DISCOVERY,  T_NONE));
    }

    void InitPendingMap() { /* Phase 1 mapping */ }
    void InitActiveMap()  { /* Phase 2 mapping */ }
    void InitExitMap()    { /* Phase 3 mapping */ }

public:
    CXSequenceOrchestrator() {
        InitWatcherMap();
        InitPendingMap();
        InitActiveMap();
        InitExitMap();
    }
    ~CXSequenceOrchestrator() { /* 메모리 정리 */ }

    //--- Watcher 시퀀스 조립
    bool BuildWatcherSequence(CXFluentSequence* seq) {
        if(IS_INVALID(seq)) return false;
        CXSequenceRegistry::BuildSequence(seq, m_watcher_map);
        return true;
    }

    //--- Session 시퀀스 조립
    bool BuildSessionSequence(CXFluentSequence* seq) {
        if(IS_INVALID(seq)) return false;
        CXSequenceRegistry::BuildSequence(seq, m_session_map);
        return true;
    }
};
```

### 3.3 기존 모듈의 변화 (Integration)
`CXSignalWatcher`나 `CXTradingSession`은 시퀀스를 직접 조립하지 않고 Orchestrator에게 위임한다.

**Before (`CXSignalWatcher` 내부):**
```cpp
seq.From(WATCHER_DISCOVERY).Execute(new CXStepDiscovery()).OnSuccess(WATCHER_VALIDATION);
// ... 수작업 조립
seq.Build();
```

**After (`CXSignalWatcher` 내부):**
```cpp
CXSequenceOrchestrator* orchestrator = CX_GET_OBJ(m_ctx, "orchestrator", CXSequenceOrchestrator);
orchestrator.BuildWatcherSequence(m_sequence);
```

## 4. 기대 효과 (Advantages)
1.  **관심사의 분리 (Separation of Concerns)**: 비즈니스 로직(Watcher, Session)은 "무엇을 감시할지", "무엇을 매매할지"에만 집중하며, "어떤 순서로 실행할지"는 Orchestrator가 전담한다.
2.  **가시성 (Visibility)**: 프로젝트 전체의 실행 흐름이 `CXSequenceOrchestrator` 클래스 하나에 완벽하게 시각화(Matrix 형태)되어 있어 아키텍처 파악이 매우 쉽다.
3.  **변경 최소화**: 파이프라인의 단계를 추가/삭제/변경해야 할 때 `CXSequenceOrchestrator` 내부의 Map 선언부 한 줄만 수정하면 되므로 사이드 이펙트가 없다.
