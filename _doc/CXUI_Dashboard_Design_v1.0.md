# CXUI Dashboard Design Specification (v1.0)

## 1. 개요 (Executive Summary)
본 문서는 MT5 (MetaTrader 5) 차트 상에 ATSE의 활성 거래 세션 상태를 실시간으로 모니터링하고 가시화하기 위한 **대시보드 클래스 `CXUI`**의 정밀 설계 규격을 정의한다.

`CXUI`는 SQLite DB 및 메모리 내 활성 세션 정보와 동기화되어 각 신호(Signal)의 핵심 Trailing 파라미터(TE Start, TE Step, TE Limit)와 실시간 계산된 임계 가격들, 그리고 현재 실행 상태(`state`)를 격자 형태 또는 리스트 카드로 차트 화면 위에 렌더링하는 역할을 전담한다.

---

## 2. 대시보드 UI/UX 레이아웃 설계

차트 화면 좌측 상단(또는 지정된 앵커)에 카드 리스트 형태로 최대 7개(또는 동적 개수)의 세션을 동시에 모니터링한다.

```
+-----------------------------------------------------------------------------------------+
|  [ATSE Dashboard - Live Session Status]                                                 |
|                                                                                         |
|  0001-26052615-01-00-1-9  100 | 020 | 1000  [ACTIVE] 
|   ┗━ Price: 1.08370      TEPrice: 1.08420   TE_StepPrice: 1.08500     
|                                                                       
|                                                                                         |
|  0001-26052615-01-00-1-9  100 | 020 | 1000  [ACTIVE] 
|   ┗━ Price: 1.08370      TEPrice: 1.08420   TE_StepPrice: 1.08500     

|                                                                                         |
|  0001-26052615-01-00-1-9  100 | 020 | 1000  [ACTIVE] 
|   ┗━ Price: 1.08370      TEPrice: 1.08420   TE_StepPrice: 1.08500     
 
 10개 정보 출력
```

### 2.1. 세션별 2라인 텍스트 구성 포맷

```text
{SID} {te_start:0000} {te_step:000} {te_limit:0000} {state}
 -- {order price:0000.00} {te price:0000.00} {te step price:0000.00}
```

* **Line 1 (정수 설정값 & 엔진 상태)**:
  * `{SID}`: 신호 고유 식별 키 (23자).
  * `{te_start}`, `{te_step}`, `{te_limit}`: DB 신호 모델에 입력된 원본 정수 포인트(Point) 값.
  * `{state}`: 세션의 현재 물리적 실행 상태 이름 (READY, TRANSIT, PENDING, ACTIVE, CLOSED 등).
* **Line 2 (실시간 포인트 ➔ 가격 환산값)**:
  * `--`: 라인 구분용 뎁스 표시 마커.
  * `{order price}`: 대기 주문 진입 가격 (시장가 +/- `te_limit`을 가격으로 환산한 값).
    * **특이 조건**: 진입 전 1분봉이 완성(마감)될 때마다 현재가와의 가격 갭을 모니터링하여 가까워지면 `te_limit` 간격만큼 대기 오더 가격을 동적 갱신 및 수정 연동하여 출력.
  * `{te price}`: 리바운드 활성화 개시 가격 (시장가 +/- `te_start`를 가격으로 환산한 값).
  * `{te step price}`: 실시간 추적을 위한 반등 스텝 단위 가격 (시장가 +/- `te_step`을 가격으로 환산한 값).
  * *주의*: 모든 가격 필드는 각 통화쌍 심볼의 소수점 자릿수(Digits) 규격에 맞추어 포매팅된다.

퐅튼는 Consolas 11 clrGOld,
시작 좌쵸는 x= 20, y = 20
label object에 데이터가 없는경우 ""강 아니고 " " 문자령 길이 1로 출력


---

## 3. CXUI 클래스 아키텍처 (MQL5)

메모리 안전성 확보를 위해 `CObject`를 상속하여 표준 컨트롤 레이어와의 결합성을 보장하며, 차트 리소스를 누수 없이 파괴하기 위한 생명주기 관리 구조를 갖춘다.

### 3.1. 클래스 인터페이스 정의 (`CXUI.mqh`)

```mql5
#ifndef CXUI_MQH
#define CXUI_MQH

#include <Object.mqh>
#include <ChartObjects\ChartObjectsTxtControls.mqh>
#include "..\Platform\Core\Interfaces\ICXContext.mqh"
#include "..\Platform\Core\Interfaces\ICXSignal.mqh"

// 렌더링에 사용되는 행별 UI 객체 구조체
struct MqlUIElement {
    CChartObjectRectLabel  Background;  // 개별 카드 배경
    CChartObjectLabel      Line1;       // SID, 정수 설정값, 상태 표시
    CChartObjectLabel      Line2;       // 계산된 가격값들
};

/**
 * @class CXUI
 * @brief ATSE 차트 화면 내 실시간 세션 정보 대시보드 가시화 컴포넌트
 */
class CXUI : public CObject {
private:
    ICXContext*       m_ctx;              // 서비스 컨텍스트 의존성
    MqlUIElement      m_elements[7];      // 최대 7개 세션 슬롯 관리
    int               m_max_slots;        // 활성화된 최대 슬롯 개수
    
    // UI 스타일 구성
    color             m_color_bg;
    color             m_color_text1;
    color             m_color_text2;
    int               m_font_size;
    string            m_font_name;

    // 차트 레이아웃 오프셋
    int               m_x_offset;
    int               m_y_offset;
    int               m_card_height;
    int               m_card_width;

public:
                      CXUI(ICXContext* ctx);
                     ~CXUI() override;

    //--- 생명주기 API
    bool              Initialize();
    void              Deinitialize();
    
    //--- 렌더링 트리거 (OnTick, OnTimer에서 호출)
    void              Refresh();

private:
    //--- 내부 헬퍼 연산
    void              UpdateSlot(int slotIdx, ICXSignal* sig);
    void              ClearSlot(int slotIdx);
    
    //--- 실시간 실가격 환산 연산 (SSOC: PriceManager 활용)
    double            CalculateOrderPrice(ICXSignal* sig, double currentPrice, double point, double dirSign);
    double            CalculateTEPrice(ICXSignal* sig, double currentPrice, double point, double dirSign);
    double            CalculateTEStepPrice(ICXSignal* sig, double currentPrice, double point, double dirSign);
};

#endif
```

---

## 4. 핵심 기능 구현 설계

### 4.1. OnTick / OnTimer 실시간 연산 및 갱신 프로세스 (`Refresh`)
1. `CXUI::Refresh()` 호출 시, `ICXContext`를 통해 현재 활성화된 세션의 리스트(`active_signals` 등)를 획득한다.
2. 상위 7개의 우선순위 신호(특히 Entry 또는 Active 단계의 신호)를 순차적으로 추출하여 UI 슬롯에 할당한다.
3. 활성 세션 개수가 7개 미만일 경우, 미사용 슬롯은 투명화 처리(`ClearSlot`)를 거쳐 화면에서 감춘다.

### 4.2. 실시간 포인트 가격 환산 공식
* **방향에 따른 부호 적용**: `double dirSign = (sig.GetDir() == CX_DIR_BUY) ? -1.0 : 1.0;`
* **포인트 크기**: `double point = SymbolInfoDouble(symbol, SYMBOL_POINT);`
* **기준가**: Ask (Buy 신호 기준) 또는 Bid (Sell 신호 기준)를 사용하며, 이는 컨텍스트 내 `ICXPriceManager`를 통해 안전하게 수급한다.

```mql5
//--- te start price (te price) 환산 예시
double CXUI::CalculateTEPrice(ICXSignal* sig, double currentPrice, double point, double dirSign) {
    if(sig.GetTEStart() <= 0) return 0.0;
    return NormalizeDouble(currentPrice + (sig.GetTEStart() * point * dirSign), (int)SymbolInfoInteger(sig.GetSymbol(), SYMBOL_DIGITS));
}
```

### 4.3. Order Price 동적 마감 갱신 알고리즘
`order price`는 단순 수식 출력이 아닌 시간 마감 조건에 연동한다.
1. 진입 전 대기 상태인 경우 1분봉 완성 여부를 감시한다 (`iBars(symbol, PERIOD_M1)` 또는 시간 플래그 체크).
2. 새로운 1분봉이 생성되고 현재 마감 가격 기준 현재가와의 간격이 한계 범위에 수렴할 경우, 가격을 `te_limit` 간격만큼 더 유리한 방향으로 이동 보정하여 UI에 갱신 출력한다.
3. 이 수정 연산은 ATSE 백엔드 수정 태스크(`CXTaskPending_R_Apply`)의 물리 오더 변경 명령과 동기화되어 대시보드 상에 오차 없이 일치하는 가격을 표기한다.

---

## 5. UI 제어 및 그래픽 리소스 생명주기 관리

* **리소스 명명 규칙 (Naming Convention)**: 
  차트 내 리소스 충돌 방지를 위해 모든 Label 객체의 이름은 `CXUI_{SLOT_INDEX}_{LINE_NUMBER}` 형식으로 유일하게 생성한다.
  * 예: `CXUI_0_L1`, `CXUI_0_L2`, `CXUI_0_BG`
* **누수 방지 (Garbage Collection)**:
  `Deinitialize()` 또는 클래스 소멸자(`~CXUI`)가 호출될 때 모든 생성된 `CChartObject` 인스턴스의 `Delete()` 메서드를 명시적으로 실행하여 EA 언로드 시 차트 위에 찌꺼기 라벨이 남는 오류를 방지한다.

---
**문서 버전**: v1.0 (PDCA/Design Storage Standard 준수)
**작성 주체**: Antigravity AI Coding System
**승인 상태**: 최초 작성 및 검토 대기
