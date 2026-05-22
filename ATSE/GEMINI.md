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

## Trading Logging Standard (v12.5 - Explicit Function Audit)
모든 트레이딩 함수 호출 및 로그 출력은 다음의 강화된 규칙을 엄격히 준수해야 한다.

1.  **Full-Audit Trading Log (m_trade 호출 시)**
    - 모든 `m_trade` 함수 호출 직전/직후에 **실제 호출된 함수명(PositionOpen, OrderOpen, OrderDelete, PositionClose, OrderModify, PositionModify)**을 명확히 포함한다.
    - 당시 주입된 **모든 파라미터**를 기록한다.
    - 트레일링 진입(TE)의 경우, 원본 포인트(`Sta`, `Ste`, `Lim`)와 당시 시장가 기준 변환된 가격(`TEPri`)을 모두 포함해야 한다.
    - 형식: `[FUNC:{name}] [Sym:{symbol}, Lot:{lot}, Price:{price}, TEPts:[Sta,Ste,Lim], TEPri:[Sta,Ste,Lim], Mkt:{mkt}, SID:{sid}]`
... (나머지 규칙 유지) ...
2.  **High-Frequency Category Muting (금지 카운터)**
    - 주기적으로 반복되는 시퀀스 중 다음 카테고리의 일반 상태 로그는 출력을 금지한다.
    - **금지 대상**: `[PRICE-MGR]` (가격 보정 로그), `[GUARD-V-SPREAD]` (PASSED 로그)
    - **예외**: 치명적 에러(`LOG_LVL_ERROR`) 상황인 경우에만 예외적으로 출력을 허용한다.

3.  **지능형 중복 방지 (Deduplication)**
    - 동일 메시지 또는 A-B-A-B 교차 패턴 발생 시 10회당 1회만 출력(Heartbeat)하는 로직을 로거 베이스 레이어에서 수행한다.
