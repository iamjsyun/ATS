# [DESIGN] 진트/익트 자산 정보 수정 파이프라인 설계 보고서 (v1.0)

본 보고서는 진입 트레일링(Trailing Entry, 진트) 및 익절 트레일링(Trailing Stop, 익트) 과정에서 발생하는 오더 및 포지션 정보 수정 요청을 안전하고 체계적으로 처리하기 위한 **'수정 실행 파이프라인(Modification Pipeline)'**을 설계합니다.

---

## 1. 개요
트레일링은 시장 가격의 움직임에 따라 지정가 오더의 가격(Price)이나 포지션의 손절가(SL)를 지속적으로 갱신하는 고빈도 작업입니다. 이를 단순히 함수 호출로 처리하지 않고, **[판단 -> 검증 -> 실행 -> 확인]**의 4단계 파이프라인으로 구조화하여 실행의 무결성을 보장합니다.

---

## 2. 파이프라인 4단계 아키텍처 (L-G-R-V)

| 단계 | 역할 | 주요 태스크 (예시) |
| :--- | :--- | :--- |
| **1. 판단 (Logic)** | 현재가와 극점을 비교하여 수정 필요성 결정 및 목표가 산출 | `L_Improve`, `Alpha_Calc` |
| **2. 검증 (Guard)** | 브로커 제한 사항(StopsLevel, 최소 이격 거리) 준수 여부 확인 | `V_Spread`, `V_Volatility` |
| **3. 실행 (Request)** | 관리자(Manager)를 통해 브로커 서버에 수정 명령 전송 | `R_Apply`, `Alpha_Apply` |
| **4. 확인 (Verify)** | 터미널 자산 정보를 재조회하여 수정 반영 여부 최종 확정 | `V_Sync`, `P_Align` |

---

## 3. 진입 트레일링 (진트) 파이프라인 흐름
오더의 `LIMIT` 가격을 시장가 방향으로 개선하는 흐름입니다.

1.  **[L] Improvement Detection**:
    *   현재 시장가가 극점 대비 `TE_STEP` 이상 유리한 방향으로 이동했는지 감시.
    *   새로운 목표가(`targetPrice`)를 산출하여 `ICXParam`에 저장.
2.  **[G] StopsLevel Guard**:
    *   목표가가 현재 시장가와 너무 가까워 브로커가 거부할 위험이 있는지 확인 (StopsLevel + 1pt).
3.  **[R] Order Modification**:
    *   `CXOrderManager::ModifyOrder` 호출.
    *   **UAF 로그 기록**: `[AUDIT-CALL:OrderModify] [SID] [P:NewPrice, Old:OldPrice]`
4.  **[V] Terminal Sync**:
    *   `OrderGetDouble(ORDER_PRICE_OPEN)`을 통해 실제 수정된 가격이 터미널에 반영되었는지 대조.

---

## 4. 익절 트레일링 (익트) 파이프라인 흐름
포지션의 `SL`을 이익 방향으로 전진시키는 흐름입니다.

1.  **[L] Alpha Calculation**:
    *   현재 수익 상태와 트레일링 파라미터를 계산하여 최적의 SL 목표가 산출.
2.  **[G] Price Reversion Guard**:
    *   새로운 SL이 현재 SL보다 후퇴(손실 방향 이동)하지 않도록 '전진 전용(Forward-Only)' 검증.
3.  **[R] Position Modification**:
    *   `CXPositionManager::ModifyPosition` 호출.
    *   **UAF 로그 기록**: `[POS-MODIFY] [SID] [SL:NewSL, Old:OldSL, Profit:Curr]`
4.  **[V] Position Alignment**:
    *   터미널의 포지션 정보를 읽어 세션 객체(`ICXSignal`)의 SL 값을 동기화.

---

## 5. 파이프라인의 핵심 안정성 설계 (Resilience)

### 5.1 원자적 상태 전달 (Atomic Handoff)
*   태스크 간 데이터 전달은 `ICXParam` 객체를 통하며, `SetDouble()`로 목표 가격을, `SetInt(1)`로 실행 트리거를 전달하여 루프 내에서 상태 오염을 방지합니다.

### 5.2 지능형 재시도 및 Throttling
*   브로커 응답 지연 시 즉시 에러 처리를 하지 않고, `TASK_YIELD`를 통해 다음 틱에서 재시도합니다.
*   네트워크 장애(10018 등) 발생 시 일정 시간 동안 수정을 중단하는 Throttling 메커니즘을 가동합니다.

### 5.3 로깅 및 감사 (UAF Standard)
*   수정 전/후의 원본 파라미터를 모두 기록하여, 예외 발생 시 브로커 로그와 엔진 로그를 1:1로 매칭할 수 있도록 합니다.

---

## 6. 결론
본 수정 파이프라인 설계는 트레일링의 복잡한 가격 계산 로직과 실제 브로커 실행 로직을 명확히 분리합니다. 이를 통해 로직 수정 시 실행 안정성을 해치지 않으며, 모든 수정 시도가 엄격한 검증과 사후 확인을 거치게 되어 자산 관리의 신뢰도를 극대화합니다.
