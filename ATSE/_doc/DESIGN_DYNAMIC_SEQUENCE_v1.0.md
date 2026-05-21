# [Design] String-Array Based Dynamic Sequence Orchestration (v1.0)

## 1. 개요 (Overview)
현재 `CXTradingSession` 및 `CXSignalWatcher` 내에서 하드코딩된 Fluent API 방식의 시퀀스 구성을 문자열 배열(`string SEQS[]`) 기반으로 동적 조립 가능하도록 변경한다. 이를 통해 컴파일 타임의 결합도를 낮추고 설정(JSON) 기반의 워크플로우 제어를 가능하게 한다.

## 2. 핵심 설계 아키텍처 (Core Architecture)

### 2.1 계층 구조
1.  **Step Factory (매핑 계층)**: 문자열 키값을 실제 `IXStep` 구현체 객체로 변환.
2.  **Sequence Assembler (조립 계층)**: 문자열 배열을 순회하며 `CXFluentSequence`의 `From().Execute().OnSuccess()`를 자동 호출.
3.  **Orchestrator (운영 계층)**: 조립된 시퀀스의 생명주기 관리.

## 3. 세부 구현 전략

### 3.1 Step Factory (`CXStepFactory.mqh`)
모든 가용 스텝을 등록하고 문자열로 인스턴스를 생성한다.
```cpp
class CXStepFactory {
public:
    static IXStep* CreateStep(string name) {
        if(name == "Initialize") return new CXStepInitialize();
        if(name == "LoadData")   return new CXStepLoadData();
        if(name == "Analyze")    return new CXStepAnalyze();
        if(name == "Trade")      return new CXStepTrade();
        if(name == "Report")     return new CXStepReport();
        return NULL;
    }
};
```

### 3.2 Dynamic Assembler 로직
문자열 배열을 순차적으로 연결하여 Linear(선형) 파이프라인을 자동 구축한다.
```cpp
void AssembleSequence(CXFluentSequence* seq, string SEQS[]) {
    int total = ArraySize(SEQS);
    for(int i = 0; i < total; i++) {
        int current_state = i;             // 상태 ID를 인덱스로 활용 가능
        int next_state = (i < total - 1) ? (i + 1) : TERMINAL_STATE;

        IXStep* step = CXStepFactory::CreateStep(SEQS[i]);
        if(IS_VALID(step)) {
            seq.From(current_state)
               .Execute(step)
               .OnSuccess(next_state)
               .OnFail(ERROR_STATE);
        }
    }
    seq.Build();
}
```

## 4. 기대 효과 및 활용
- **유연성**: `SEQS = ["Init", "Analyze", "Trade"]` 에서 `SEQS = ["Init", "Filter", "Analyze", "Trade"]`로 배열만 수정하면 로직 삽입 완료.
- **가독성**: `CXTradingSession`의 복잡한 Builder 코드가 사라지고 명확한 순서 배열만 남음.
- **확장성**: 추후 SQLite나 JSON에서 `SEQS` 배열을 불러오도록 구현하면 바이너리 변경 없이 전략 변경 가능.

## 5. 제약 사항
- 각 스텝은 독립적이어야 하며, 데이터 공유는 `ICXContext`를 통해 수행해야 함.
- 분기(Branch)나 루프(Loop)가 필요한 복잡한 시퀀스의 경우, 별도의 맵핑 규칙(`Case` 등) 정의가 필요함.
