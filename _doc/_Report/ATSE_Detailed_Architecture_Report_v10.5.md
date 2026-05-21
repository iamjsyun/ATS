# ⚠️ DEPRECATED: Superseded by _doc/spec.md (v11.3)
**Note**: This document (v10.5) is now for historical reference only. All active development and architectural mandates must follow the **ATS Master Design Specification (v11.3)** in `_doc/spec.md`.

# 📘 ATSE Master Design & Architecture Specification (v10.5)

## 1. 아키텍처 철학 및 핵심 원칙 (Core Principles)
- **1 Task = 1 Responsibility (1T1R)**: 모든 비즈니스 로직은 하이퍼 원자화(Hyper-Atomized)되어 단일 책임을 가짐.
- **L-P-R-V 파이프라인 패턴**:
  - L (Logic): 상태 판단 및 계산 (DB/네트워크 I/O 없음)
  - P (Persistence/Prepare): 상태 잠금 및 내부 데이터 준비
  - R (Request): 브로커/외부 시스템으로의 물리적 요청 송신
  - V (Verify): 요청 결과에 대한 물리적 검증 (티켓 확인 등)
- **SSOT (Single Source of Truth)**: 모든 데이터는 DB의 signals 테이블을 기준으로 동기화되며, CXSignal 객체가 런타임 메모리를 대변함.
- **샌드박스 세션 (Sandboxed Session)**: 각 트레이딩 시그널(SID)은 독립적인 CXTradingSession에 바인딩되어 상호 간섭(Cross-talk) 없이 병렬 처리됨.

## 2. 데이터 스키마 및 상태 전이 규격 (Schema & Matrix)

### 2.1. 데이터 스키마 (signals 테이블 / 46개 필드)
* 식별자: sid(PK), gid, cno, sno, msg_id, raw_id
* 의도(Intent): xa_entry (1=ACTIVE), xa_exit (1=ACTIVE, 2=COMP, 3=ARCH)
* 상태(Status): xe_status, xe_status_msg
* 트레이딩 파라미터: symbol, dir(1=Buy, -1=Sell), type(0=Market, 2/3=Limit), lot
* 가격 설정: price_signal, limit_offset, stop_offset
* 트레일링(TE/TS): te_start, te_step, te_limit, ts_start, ts_step, ikte_start, ikte_step
* 물리 정보: price_open, price_close, ticket, magic

### 2.2. State Transition Matrix (상태 전이 매트릭스)
1. READY (0): 신호 최초 주입.
2. PENDING_REQ (1): 브로커로 대기 주문 송신.
3. PENDING_PLACED (5): 대기 주문 터미널 등록 완료.
4. IN_TRANSIT (2): 시장가 주문 송신 중.
5. EXECUTED (10): 실제 포지션 오픈 완료.
6. CLOSED_SIGNAL (20), CLOSED_SL (21), CLOSED_TP (22): 청산 완료.
7. ERROR (99): 치명적 에러 발생 시스템 강제 종료.

## 3. 전역 로깅 및 에러 전파 규격 (Today's Standard v10.4)

### 3.1. 에러 전파 체계 (xp.SetString())
- 모든 매니저 메서드는 ICXParam* xp를 매개변수로 받음.
- 브로커 실패 시 xp.SetString(상세_에러_메시지)를 호출하여 최종 [ERR-000] 메시지로 전파.

### 3.2. Trading Logging Standard v10.4
* 주문 진입 (OrderOpen)
  - 성공: [EXEC-ENTRY] Sending Order: [Sym:{symbol}, Type:{type}, Lot:{lot}, Price:{price}, SL:{sl}, TP:{tp}, Mkt:{mkt}, TELimPts:{pts}, TELimP:{price}, TESta:{teStart}, TESte:{teStep}, SID:{sid}]
  - 실패: [EXEC-ENTRY-FAIL] Broker Code:{ret}({desc}), SysErr:{err}. Original Params: [...]

## 4. 트레이딩 파이프라인 및 가격 계산 규칙

### 4.1. 가격 계산 규칙 (Market-Price Priority Mandate v10.23)
* [v10.32 Fix] 지정가 SL/TP 계산 기준가 보정:
  - 시장가(Market) 주문: SL/TP 계산 기준가(BasePrice) = marketPrice
  - 지정가(Pending) 주문: SL/TP 계산 기준가(BasePrice) = execPrice (시장가 - offset)

## 5. 현재 구현의 위험성 및 고도화(Enhancement) 분석 보고

### 5.1. 식별된 위험성 (Risks)
1. 동기적 브로커 요청: CTrade 함수 블로킹으로 인한 전체 성능 저하 위험.
2. DB I/O 병목: 잦은 파일 I/O로 인한 MT5 프레임드랍 유발 가능성.
3. 자가 치유 한계: XE_ERROR(99) 발생 시 자동 복구 로직 부재.

### 5.2. 향후 고도화 방안
1. Phase 1 (비동기): OrderSendAsync 도입 및 트랜잭션 콜백 기반 리스너 구축.
2. Phase 2 (인메모리): Redis 또는 ZeroMQ를 활용한 고속 상태 전파 및 Bulk DB Update.
3. Phase 3 (자가치유): 소프트/하드 에러 분리 및 Suspended(98) 상태 기반 Retry Policy 구축.

---
보고 날짜: 2026-05-20
문서 상태: Approved (v10.5)
