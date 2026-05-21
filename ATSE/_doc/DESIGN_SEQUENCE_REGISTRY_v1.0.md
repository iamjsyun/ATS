# [Design] Sequence-Step Class Registry (v1.1)

## 1. 개요 (Overview)
기존의 단순 구조체(`SC_PAIR`) 방식을 **클래스(`CXSequenceStep`)** 기반 설계로 고도화한다. 이를 통해 데이터 캡슐화, 초기화 로직 내재화, 그리고 향후 확장성(상속 및 가상 함수)을 확보한다.

## 2. 클래스 설계 (Class Design)

### 2.1 정의 클래스 (`CXSequenceStep`)
객체 지향적 접근을 위해 `CObject`를 상속받거나 독립 클래스로 정의한다.
```cpp
class CXSequenceStep : public CObject {
private:
    string m_seq_name;
    string m_step_name;
    int    m_timeout;

public:
    CXSequenceStep(string seq, string step, int timeout = 0) 
        : m_seq_name(seq), m_step_name(step), m_timeout(timeout) {}

    string GetSequenceName() const { return m_seq_name; }
    string GetStepName() const     { return m_step_name; }
    int    GetTimeout() const      { return m_timeout; }
};
```

### 2.2 설정 메트릭스 (Registry Array)
구조체 리스트 대신 포인터 배열을 사용하여 동적 구성을 지원한다.
```cpp
CArrayObj* GetWorkflowMap() {
    CArrayObj* map = new CArrayObj();
    map.Add(new CXSequenceStep("Watcher", "Discovery"));
    map.Add(new CXSequenceStep("Watcher", "Validation"));
    map.Add(new CXSequenceStep("Session", "EntryLogic", 30)); // 타임아웃 추가 가능
    return map;
}
```

## 3. 조립 엔진 고도화

### 3.1 클래스 기반 필터링
클래스 메서드를 사용하여 더 안전하게 데이터를 추출한다.
```cpp
class CXSequenceRegistry {
public:
    static void BuildSequence(CXFluentSequence* seq, string target_seq, CArrayObj* map) {
        int state_id = 0;
        for(int i = 0; i < map.Total(); i++) {
            CXSequenceStep* item = dynamic_cast<CXSequenceStep*>(map.At(i));
            if(IS_VALID(item) && item.GetSequenceName() == target_seq) {
                IXStep* step = CXStepFactory::CreateStep(item.GetStepName());
                if(IS_VALID(step)) {
                    seq.From(state_id)
                       .Execute(step)
                       .Timeout(item.GetTimeout()) // 클래스화로 인한 속성 확장
                       .OnSuccess(state_id + 1);
                    state_id++;
                }
            }
        }
        seq.Build();
    }
};
```

## 4. 클래스 전환의 이점 (Advantages)

1.  **캡슐화 (Encapsulation)**: 멤버 변수에 대한 접근 제어가 가능하며, 데이터 오염을 방지한다.
2.  **생성자 활용 (Constructors)**: 객체 생성 시 필수 파라미터 검증 및 기본값 설정을 자동화한다.
3.  **속성 확장성**: 단순히 이름뿐만 아니라 `Timeout`, `RetryCount`, `Condition` 등 단계별 특화 속성을 필드로 추가하기 용이하다.
4.  **다형성 (Polymorphism)**: 특정 단계만 다르게 동작해야 할 경우 `CXSequenceStep`을 상속받아 특수화된 클래스를 만들 수 있다.
