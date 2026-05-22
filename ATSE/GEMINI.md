# ATSE Project Directive
<!-- Import: D:\Projects\ATS\GEMINI.md -->

## Mandate
This agent is the **Executor**.

## Constraints
- **Architecture**: Interface-First Mandate (IX*).
- **No Magic Numbers**: Raw numbers (state IDs, types, timeouts) are PROHIBITED. Use `enum` or named constants.
- **ID Safety**: SIDs/GIDs are IMMUTABLE. Do NOT modify them.
- **Log Standard**: Use `_log/` directory. Use MQL5 `FILE_COMMON`.
- **Validation**: Post-Action Verification (MT5 re-check) is MANDATORY.
- **Remote Logger**: DO NOT modify `CXRemoteLogger.mqh` or its related logic unless explicitly requested by the user (Stability Mandate).

## Responsibilities
- Trading signal execution.
- Signal status tracking.
- Position/Order management.

## Trading Logging Standard (v13.5 - UAF Unified)
모든 트레이딩 함수 호출 및 로그 출력은 다음의 강화된 규칙을 엄격히 준수한다.

1.  **Universal Audit Format (UAF)**
    - 모든 `m_trade` 호출 전후에 명시적 함수명과 표준 파라미터를 기록한다.
    - 형식: `[FUNC:Name] [SID] [Sym, Lot, Dir, Status] [TE:Pts TS:Pts SL:Pts TP:Pts] [P:Open, SL:Price, TP:Price, Mkt:Price] {SPEC:Extra}`
    - `Print()` 함수를 병행 사용하여 터미널 전문가 탭의 영구 가시성을 확보한다.

2.  **Architectural Mandates (v13.5 Resilience)**
    - **Atomic Binding**: 세션 할당 즉시 DB 상태를 `XE_PENDING_REQ(1)`로 잠금하여 중복 생성을 원천 차단한다.
    - **Exit-First Priority**: `xa_exit=1` 발견 시 모든 진입 시퀀스를 즉시 Abort하고 청산으로 전이한다.
    - **Sync Latency Guard**: 실물 부재 시 즉시 종료하지 않고 최대 5틱 동안 히스토리를 재조회(Retry)한다.

3.  **High-Frequency Muting**
    - `[PRICE-MGR]`, `[GUARD-V-SPREAD]` 등 단순 상태 보고 로그는 출력을 금지한다. (에러 시 예외)
    - 지능형 중복 방지 로직(10회당 1회 출력)을 기본 적용한다.
