# ATSE Internal Sequence & Process Flow (v1.0)
**Date**: 2026-05-19
**Architecture**: ATS Master Architecture v1.0
**Project**: ATSE (ATS Engine / MQL5)

---

## 1. 개요
본 문서는 ATS 시스템의 핵심 엔진인 ATSE의 신호 감지부터 청산 완료까지의 내부 시퀀스와 프로세스 흐름을 정의한다. 모든 로직은 **1 Task 1 Responsibility (1T1R)** 원칙에 따라 원자화되었으며, **L-P-R-V-P** 레이어링을 통해 안정성을 극대화하였다.

---

## 2. ATSE 상세 실행 흐름 (Process Flow Tree)

`	ext
ATSE Expert Advisor (ATS.mq5)
┃
┣━ [0] Initialization (OnInit)
┃  ┗━ 🏗️ CXAppService::Initialize()
┃     ┣━ 📂 CXDatabase: Open ATS.db (SQLite)
┃     ┣━ 🛡️ CXGuard: Load Broker Limits (StopsLevel, LotStep)
┃     ┗━ 🏊 CXTradingSessionPool: Warm-up (Pre-create sessions)
┃
┣━ [1] Discovery Phase (OnTimer / OnTick)
┃  ┗━ 🔍 CXSignalWatcher::Pulse()
┃     ┣━ 📡 SQL: SELECT * FROM signals WHERE xa_entry=1 AND xe_status=0
┃     ┗━ 🚀 CXAppService::OnNewSignal()
┃        ┗━ 🏁 Pool.BorrowSession() ➔ Session.Start(sig)
┃
┣━ [2] Execution: Entry Pipeline (Step_EntryComposite)
┃  ┗━ 🟢 SESSION_READY (State)
┃     ┣━ 🧩 Task_Entry_L_Validate: IXGuard 기반 증거금/규격 체크 (Decision)
┃     ┣━ 🧩 Task_Entry_P_Lock: DB를 XE_PENDING_REQ로 업데이트 (Intent)
┃     ┣━ 🧩 Task_Entry_R_Order: IXOrderManager::OrderSend 호출 (Request)
┃     ┣━ 🧩 Task_Entry_V_Ticket: 응답 패킷에서 Ticket ID 추출 (Verification)
┃     ┣━ 🧩 Task_Entry_V_Real: Terminal 실물 오더 존재 확인 (L3 Verification)
┃     ┗━ 🧩 Task_Entry_P_Finalize: DB 최종 상태 확정 ➔ Next State 전이 (Commit)
┃
┣━ [3] Monitoring: Pending Pipeline (Step_PendingComposite)
┃  ┗━ 🟡 STATE_ENTRY_TRAILING (State)
┃     ┣━ 🧩 Task_Pending_V_Sync: 터미널 실물 상태 동기화 (Verify)
┃     ┣━ 🧩 Task_Pending_L_Rebound: 반등 시 Market 전환 판단 (Logic)
┃     ┣━ 🧩 Task_Pending_L_Improve: 트레일링 진입가 계산 (Logic)
┃     ┗━ 🧩 Task_Pending_R_Apply: OrderModify 송신 및 DB 기록 (Action)
┃
┣━ [4] Management: Active Pipeline (Step_ActiveComposite)
┃  ┗━ 🔵 SESSION_ACTIVE (State)
┃     ┣━ 🧩 Task_Active_V_Terminal: 포지션 생존 여부 확인 (Verify)
┃     ┣━ 🧩 Task_Active_P_Align: SL/TP 히트 시 DB 강제 동기화 (Sync)
┃     ┣━ 🧩 Task_Active_L_Status: 세션 유지/청산 여부 판단 (Logic)
┃     ┣━ 🧩 Task_IntentWatch: 외부 청산 명령(XA_EXIT) 감시 (Intent)
┃     ┣━ 🧩 Task_AlphaCalc: 익절 트레일링(Ik-Te) 계산 (Alpha Logic)
┃     ┗━ 🧩 Task_AlphaApply: PositionModify 송신 및 DB 기록 (Action)
┃
┣━ [5] Liquidation: Exit Pipeline (Step_ExitComposite)
┃  ┗━ 🟠 SESSION_LIQUIDATING (State)
┃     ┣━ 🧩 Task_Exit_L_Prepare: 청산 시나리오 검증 (Logic)
┃     ┣━ 🧩 Task_Exit_P_Lock: DB 청산 진행 중 잠금 (Persistence)
┃     ┣━ 🧩 Task_Exit_R_Order: IXExitManager::CloseByTicket 호출 (Request)
┃     ┣━ 🧩 Task_Exit_V_Terminal: 터미널 내 자산 소멸 최종 확인 (L3 Verify)
┃     ┗━ 🧩 Task_Exit_P_Finalize: DB XE_CLOSED_XXX 확정 (Commit)
┃
┗━ [6] Termination (OnDeinit)
   ┗━ ⚫ SESSION_CLOSED (Lifecycle End)
      ┣━ ♻️ Session.Reset(): 모든 Task 상태 초기화
      ┗━ 📥 Pool.ReturnSession(): 세션을 유휴 풀로 반환
`

---

## 3. 핵심 설계 원칙 (Engineering Principles)

### 3.1 L-P-R-V-P 레이어링
모든 트랜잭션은 다음의 5단계를 엄격히 준수한다:
1.  **L (Logic)**: 메모리 내 데이터 기반 순수 판단.
2.  **P (Persistence)**: 실행 전 DB에 "의도" 기록 및 Race Condition 방지 잠금.
3.  **R (Request)**: 브로커/터미널에 대한 물리적 명령 송신.
4.  **V (Verify)**: 명령 후 터미널 상태 재조회를 통한 결과 검증 (Post-Action Verification).
5.  **P (Persistence)**: 검증 완료된 결과의 최종 DB 확정.

### 3.2 Sandbox Isolation
각 CXTradingSession은 독립된 컨텍스트를 가지며, 세션 간 데이터 오염을 방지하기 위해 SID(Signal ID) 경계 검증 가드가 Pulse 단계에서 작동한다.

### 3.3 Non-blocking Fault Tolerance
TASK_YIELD 메커니즘을 통해 I/O 지연 시 전체 시스템 루프를 멈추지 않고 다음 틱에서 해당 단계부터 재시도하여 안정성을 확보한다.

---
**작성자**: Gemini CLI (cli-agent)
**보관경로**: G:\내 드라이브\_Doc\ATS_ATSE_Process_Flow_v1.0.md
