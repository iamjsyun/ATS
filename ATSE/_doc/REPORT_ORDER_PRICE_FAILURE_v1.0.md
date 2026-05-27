# 장애 분석 보고서: 추적 진입 시 OrderOpen 10015 에러 분석 및 해결 방안 (v1.0)

본 보고서는 `GOLD#` 심볼에 대한 추적 진입(BUY Limit) 주문 전송 시 브로커로부터 `10015 (invalid price)` 에러가 발생하며 진입에 실패하는 장애 현상의 원인을 소스코드 수준에서 분석하고 해결 방안을 제시합니다.

---

## 1. 장애 현상 요약

* **대상 신호**: `1001-26052712-01-00-1-1` (Symbol: `GOLD#`, Dir: `BUY`, Vol: `0.01`)
* **에러 코드**: `10015 (invalid price)`
* **로그 요약**:
  ```
  [FUNC:AUDIT-RECEPTION] [READY] [ESTART:500, ELIMIT:1000...] [P:0.00, SL:0.00, TP:0.00, Mkt:4502.84] {OrderOpen Result: FAILED (Code:10015)}
  [FUNC:EXEC-ENTRY-FAIL] {OrderOpen FAIL. Code:10015(invalid price)}
  ```

---

## 2. 장애 원인 분석 (Root Cause Analysis)

### 2.1 0.00 가격 전송 규격 오류
* **현상**: 로그 블록 3번의 파라미터 `[P:0.00, SL:0.00, TP:0.00, Mkt:4502.84]`를 보면, 브로커에게 요청한 진입 지정가(`P`), 손절가(`SL`), 익절가(`TP`)가 모두 **`0.00`**으로 전송되었습니다.
* **이유**: 지정가 대기 주문(`ORDER_LIMIT`, Type 2)은 무조건 유효한 가격 지정을 필요로 합니다. 가격을 `0.00`으로 전송할 경우 브로커 서버(MT5)는 즉시 `10015 (invalid price)` 에러를 발생시키며 주문을 거절합니다.

### 2.2 가격 계산 태스크의 우회 (Bypass)
* **설계 구조**:
  진입 가격(`PriceOpen`) 및 SL/TP를 실시간 시장가와 포인트 거리 기준(`ESTART`/`ELIMIT`/`SL`/`TP`)으로 계산하여 모델에 바인딩하는 책임은 **`CXTaskEntry_L_Price`** 태스크에 있습니다.
* **코드상 원인**:
  1. 신규 진입 신호가 인입되면 통합 워처 상태(`WATCHER_ENTRY_EXECUTE`)에서 [CXStageEntryExecute.mqh](file:///d:/Projects/ATS/ATSE/CXTrade/Watcher/WatcherWorkflow/CXStageEntryExecute.mqh#L92)가 실행됩니다.
  2. 이 스테이지는 **세션을 생성하거나 가격 계산 단계를 거치지 않고**, DB에서 방금 로드되어 가격이 초기값 `0.00`인 신호 객체(`sig`)에 대해 곧바로 `orderMgr.ExecuteEntry(xp)`를 호출합니다.
  3. 결과적으로 가격 계산 로직(`CXTaskEntry_L_Price`)이 생략되어 지정가 `0.00`으로 주문이 나가게 되었습니다.

```
[현재 장애 흐름]
신규 신호 감지 (DB) ──> 워처 실행 (Stage_EntryExecute) ──> OrderManager.ExecuteEntry (PriceOpen=0.00) ──> [에러 10015 발생]
                                                            ▲ (가격 계산 로직인 CXTaskEntry_L_Price가 수행되지 않음)
```

---

## 3. 해결 방안 (Proposed Resolutions)

이 장애를 해결하기 위한 아키텍처적 대안은 크게 두 가지입니다.

### 방안 A. 워처 실행 단계 내에서 진입 가격 계산 추가 (추천 - 최소 변경)
`CXStageEntryExecute`가 직접 주문을 전송하는 현재 설계를 유지하면서, 주문을 넣기 전 `PriceManager`를 호출해 가격 계산 및 바인딩을 선행하도록 수정하는 방안입니다.

#### [CXStageEntryExecute.mqh](file:///d:/Projects/ATS/ATSE/CXTrade/Watcher/WatcherWorkflow/CXStageEntryExecute.mqh) 수정 제안:
```cpp
            // 2. 최초 대기 오더 접수 진행
            sig.SetStatus(XE_READY);
            sig.SetStatusMsg("Initial Execute Placement");
            repo.UpdateStatus(sig);

            //--- [추가] 주문 전송 전 지정가/SL/TP 계산 선행
            ICXPriceManager* priceMgr = factory.CreatePriceManager(ctx);
            if(IS_VALID(priceMgr)) {
                string symbol = sig.GetSymbol();
                int dir = sig.GetDir();
                double marketPrice = priceMgr.GetMarketPrice(symbol, dir);
                double offset = (sig.GetType() == ORDER_MARKET) ? 0 : sig.GetTELimit();
                
                double execPrice = priceMgr.CalculateExecPrice(xp, symbol, dir, sig.GetType(), offset);
                double basePrice = (sig.GetType() == ORDER_MARKET) ? marketPrice : execPrice;
                double finalSL = priceMgr.CalculateSL(xp, symbol, dir, basePrice, sig.GetSL());
                double finalTP = priceMgr.CalculateTP(xp, symbol, dir, basePrice, sig.GetTP());
                
                sig.SetPriceOpen(execPrice);
                sig.SetPriceSL(finalSL);
                sig.SetPriceTP(finalTP);
                
                SAFE_DELETE(priceMgr);
            }

            XP_LOG_INFO(xp, StringFormat("[WATCHER-ENTRY-EXECUTE] Plunging Initial Order for SID:%s", sid));
            if(orderMgr.ExecuteEntry(xp)) { ... }
```

---

### 방안 B. 오더 진입 전 세션 생성 구조로 전환 (구조적 해결책)
워처는 신호 감색 및 "세션 생성"까지만 담당하고, 실제 오더 계산과 송신은 세션(`CXSessionEntry`)의 라이프사이클(`ORD_READY` $\rightarrow$ `Stage_OrderValidation` $\rightarrow$ `ORD_EXECUTING` $\rightarrow$ `Stage_OrderPlacement`)에 위임하는 방식입니다.

1. `CXStageEntryExecute` 내부의 `orderMgr.ExecuteEntry(xp)` 호출 로직을 제거하고, `session_mgr.CreateSession(sp)`을 호출하여 세션을 먼저 시작합니다.
2. 세션의 첫 단계인 `Stage_OrderValidation`에서 `TASK_E_L_PRICE`가 안전하게 구동되어 가격 계산을 마친 후, `Stage_OrderPlacement`에서 `TASK_E_R_ORDER`가 실행되면서 `orderMgr.ExecuteEntry(xp)`를 수행하게 됩니다.
3. *장점*: 세션 라이프사이클과의 정합성이 완벽하게 맞아떨어지며, 중복 코드가 제거됩니다.
