# ATS 실전 매매 시나리오 가이드 (v1.0)
**Date**: 2026-05-19
**Scenario**: GOLD# 매수 트레일링 및 청산 프로세스

---

## 1. 신호 감지 및 주입 (ATSA)
*   **상황**: 외부 채널(텔레그램 등)에서 "GOLD# BUY LIMIT 2350.00" 신호 발생.
*   **프로세스**:
    1.  **ATSA Parser**: 메시지 수신 및 XSignal 객체화.
    2.  **DataManager**: DB(signals) 저장. (xa_entry:1, xe_status:0 [READY])

## 2. 엔진 감지 및 세션 할당 (ATSE)
*   **상황**: ATSE가 DB에서 신규 신호 포착.
*   **프로세스**:
    1.  **CXSignalWatcher**: READY 상태 신호 검색.
    2.  **SessionPool**: 유휴 세션 할당 및 시퀀스 구동.

## 3. 진입 시퀀스 (Entry Pipeline: L-P-R-V-P)
1.  **판단 (L)**: Task_Entry_L_Validate - 증거금 및 StopLevel 체크.
2.  **잠금 (P)**: Task_Entry_P_Lock - DB 상태를 2(PENDING_REQ)로 잠금.
3.  **요청 (R)**: Task_Entry_R_Order - 브로커 OrderSend 송신.
4.  **검증 (V)**: Task_Entry_V_Ticket - 티켓 ID(1234567) 획득 및 V_Real 실물 확인.
5.  **확정 (P)**: Task_Entry_P_Finalize - DB 1(PENDING_PLACED) 최종 확정.

## 4. 대기 및 트레일링 (Pending Pipeline)
*   **상황**: 금 가격 하락에 따른 진입가 개선.
*   **프로세스**:
    1.  Task_Pending_L_Improve: 개선된 가격(2347.00) 계산.
    2.  Task_Pending_R_Apply: OrderModify 송신 및 DB 업데이트.
    3.  **체결**: 가격 도달 시 포지션으로 전환 ➔ SESSION_ACTIVE 전이.

## 5. 활성 관리 및 알파 (Active Pipeline)
*   **상황**: 수익 구간 진입에 따른 익절가 추적.
*   **프로세스**:
    1.  Task_AlphaCalc: Trailing-Stop 계산, SL을 2355.00으로 상향.
    2.  Task_Active_V_Terminal: 포지션 생존 상태 실시간 동기화.

## 6. 청산 시퀀스 (Liquidation Pipeline: 3-Layer Guard)
*   **상황**: 사용자 강제 청산 요청 (xa_exit: 1).
*   **프로세스**:
    1.  **잠금 (P)**: Task_Exit_P_Lock - 청산 중 상태 기록.
    2.  **요청 (R)**: Task_Exit_R_Order - OrderClose 명령 송신.
    3.  **검증 (V)**: Task_Exit_V_Terminal - 터미널 내 자산 소멸 최종 확인 (L3).
    4.  **확정 (P)**: Task_Exit_P_Finalize - DB 20(CLOSED) 업데이트.

## 7. 종료 및 이관 (Termination & Archival)
*   **세션 반환**: ATSE 세션 초기화 및 Pool 반환.
*   **아카이빙**: ATSA Archiver가 종료된 데이터를 signals_history로 이동 후 원본 삭제.

---
**작성자**: Gemini CLI (cli-agent)
**보관경로**: G:\내 드라이브\_Doc\ATS_Trading_Scenario_v1.0.md
