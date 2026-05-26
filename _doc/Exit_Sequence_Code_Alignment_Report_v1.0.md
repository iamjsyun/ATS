# Exit Sequence Code Alignment Report (v1.0)

## 1. 개요 (Executive Summary)
본 보고서는 **Exit Sequence Scenario Analysis Report (v1.0)**에 기술된 청산 핵심 규칙 및 8대 동작 시나리오(A~H)가 실제 ATSE (Active Trading State Engine)의 MQL5 소스 코드에 누수 없이 정상 구현되었는지 검증한 코드 정합성 대조 보고서이다.

분석 결과, 정상 포지션 청산(A) 및 부분 체결 청산(E), 레이스 컨디션 방어(D) 등 핵심 동작부는 높은 정합성을 보였으나, **통신 장애 대처(F), 벌크 비동기 청산(G), 유령 신호 패스트 클린업(C) 등 일부 한계/예외 상황 대처 로직에 대한 코드 갭(Gap)이 발견**되어 보완이 시급한 상태이다.

---

## 2. 시나리오별 코드 정합성 대조 매트릭스 (Alignment Audit)

| 시나리오 | 설계 스펙 요구사항 | 실제 소스 코드 구현 위치 | 정합 상태 | 발견된 갭 (Gaps & Drifts) |
| :--- | :--- | :--- | :---: | :--- |
| **A. 정상 포지션 청산** | xa_exit=1 감지 후 즉시 SESSION_LIQUIDATING(20) 전이 및 PositionClose 실행 | - [CXTaskIntentWatch.mqh](file:///d:/Projects/ATS/ATSE/CXTrade/Session/Workflow/Active/CXTaskIntentWatch.mqh#L55-L57)<br>- [CXTaskExit_R_Order.mqh](file:///d:/Projects/ATS/ATSE/CXTrade/Session/Workflow/Exit/CXTaskExit_R_Order.mqh) | **95%** | 무결하게 연동되어 있으나 청산 API 호출 전 전역 파라미터 로깅 규격 검증 필요. |
| **B. 주문 즉시 취소** | IN_TRANSIT(2) 상태에서 xa_exit=1 감지 시 OrderDelete 실행 | - [CXTaskIntentWatch.mqh](file:///d:/Projects/ATS/ATSE/CXTrade/Session/Workflow/Active/CXTaskIntentWatch.mqh)<br>- [CXTaskExit_R_Order.mqh](file:///d:/Projects/ATS/ATSE/CXTrade/Session/Workflow/Exit/CXTaskExit_R_Order.mqh) | **90%** | 티켓 미발급 상태에서 청산으로 전이 시 `SweepBySid`에 의존하여 취소 수행. |
| **C. 유령 신호 정리** | ticket=0 및 자산 무감지 시 세션 스폰을 생략하고 xe_status=20 직권 마킹 (Fast-Pass) | - [CXStepValidation.mqh](file:///d:/Projects/ATS/ATSE/CXTrade/Watcher/WatcherWorkflow/CXStepValidation.mqh#L88-L100) | **50%** (일부 누락) | **[Critical Gap]** `ticket > 0` 가드 조건이 붙어 있어, 진입 실패 등으로 `ticket=0`인 유령 신호가 들어올 시 Fast-Pass를 타지 못하고 무의미하게 세션을 구동해 교착 상태를 유발함. |
| **D. 레이스 컨디션 방어**| Watcher의 Fast-Pass 수행 시 이미 구동 중인 세션이 발견되면 제어권 양보 | - [CXStepSpawning.mqh](file:///d:/Projects/ATS/ATSE/CXTrade/Watcher/WatcherWorkflow/CXStepSpawning.mqh#L49-L69) | **100%** | `session_mgr.FindSessionBySid` 탐색 후 `ForceTransition`을 유발하여 완벽하게 방어함. |
| **E. 부분 체결 긴급 청산**| 동일 SID 하에 포지션과 주문 혼재 시 일괄 수거하여 청산 | - [CXTerminalPlatform.mqh](file:///d:/Projects/ATS/ATSE/CXTrade/Execution/CXTerminalPlatform.mqh#L358-L393) | **100%** | `SweepBySid` 메서드 내에서 루프를 돌려 매치되는 모든 포지션/오더 티켓을 삭제 및 클로즈함. |
| **F. 브로커 오프라인** | 통신 실패 시 즉시 세션을 ERROR로 터뜨리지 않고 30초 간격 Retry 후 서킷 작동 | - [CXTerminalPlatform.mqh](file:///d:/Projects/ATS/ATSE/CXTrade/Execution/CXTerminalPlatform.mqh) | **10%** (미구현) | **[High Gap]** 청산 실패 시 `OrderDelete` 및 `PositionClose`에서 단순히 즉시 `false`를 반환하며, 리트라이 루프 및 Circuit Breaker 발동 로직이 부재함. |
| **G. 다중 좀비 적체** | Watcher 단에서 개별 세션의 틱을 대기하지 않고 비동기 벌크 Sweep 구동 | - [CXSignalWatcher.mqh](file:///d:/Projects/ATS/ATSE/CXTrade/Watcher/CXSignalWatcher.mqh) | **0%** (미구현) | **[Medium Gap]** 순차적으로 세션을 탐색하고 생성 및 구동하는 루프만 존재하며, 벌크 비동기 Sweep 전용 제어 스레드는 미구현 상태임. |
| **H. SL/TP 임의 조작** | 청산 직전 터미널 포지션 실물 정보를 최신으로 재섀도잉(Shadowing) 동기화 | - [CXTaskExit_R_Order.mqh](file:///d:/Projects/ATS/ATSE/CXTrade/Session/Workflow/Exit/CXTaskExit_R_Order.mqh) | **30%** (부족) | **[Medium Gap]** 청산 송신 직전 `ICXInventoryManager::SyncToSignal`에 의한 최신 볼륨 및 SL/TP 동기화 없이 기존 메모리 캐시 상태에 의존하여 닫기 명령을 송신함. |

---

## 3. 핵심 코드 갭(Gap) 상세 및 교정 설계 가이드

### [Gap 1] `ticket <= 0` 인 유령 신호의 Fast-Pass 누락 (시나리오 C)
* **현황**: `CXStepValidation::OnProcess`의 실물 자산 부재 우회 로직이 `ticket > 0` 가드에 걸려 있음.
* **영향**: 진입 단계에서 에러가 발생했거나 티켓이 할당되지 못한 채 `xa_exit=1`로 청산 요구된 좀비 신호는 세션 생성 프로세스로 넘어가 교착을 유발함.
* **교정안**:
  ```mql5
  // CXStepValidation.mqh 수정 제안
  if(sig.GetXAExit() == XA_ACTIVE) {
      ulong ticket = (ulong)sig.GetTicket();
      
      // [교정] 티켓이 아예 없거나, 티켓이 있는데 터미널에 실물이 없는 두 케이스 모두 Fast-Pass 처리
      bool isAbsent = (ticket <= 0) || (IS_VALID(invMgr) && !invMgr.IsAssetExists(ticket, sig.GetType()));
      
      if(isAbsent) {
          string bypassMsg = (ticket <= 0) ? "Auto-Closed: No physical asset created yet."
                                           : StringFormat("Auto-Closed: Physical Asset(%I64u) missing.", ticket);
          
          IRepository* repo = CX_GET_OBJ(ctx, "repo", IRepository);
          CXMessageProvider::UpdateStatus(sig, XE_CLOSED_SIGNAL, bypassMsg);
          sig.SetXAExit(XA_CLOSED_COMPLETED); // xa_exit=2 마킹
          
          if(IS_VALID(repo)) repo.ForceUpdateIntent(sig);
          activeList.Delete(i);
          continue;
      }
  }
  ```

### [Gap 2] 청산 전송 직전 최신 실물 데이터 동기화 누락 (시나리오 H)
* **현황**: `CXTaskExit_R_Order`는 메모리 내 캐시 정보에 의존하여 주문을 날림.
* **영향**: 모바일 터미널 조작 등으로 SL/TP가 바뀌었을 시 락이 걸리거나 단가 에러 발생 가능.
* **교정안**:
  ```mql5
  // CXTaskExit_R_Order.mqh 수정 제안
  virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
      ...
      ICXSignal* sig = xp.GetSignal();
      if(IS_INVALID(sig)) return TASK_BREAK;
      
      // [교정] 청산 명령 송신 직전 반드시 터미널 실물 데이터를 메모리 모델과 최종 동기화
      if(IS_VALID(invMgr)) {
          invMgr.SyncToSignal(sig);
      }
      
      ulong ticket = (ulong)sig.GetTicket();
      ...
  ```

### [Gap 3] 청산 실패 시의 물리적 Retry Loop 및 회로 차단 부재 (시나리오 F)
* **현황**: `CXTerminalPlatform`은 브로커로부터 리턴코드 에러를 받으면 즉시 실패(`false`) 처리.
* **영향**: 일시적 브로커 오프라인 상황에서 청산 포기 및 ERROR 홀딩 발생.
* **교정안**: `CXTerminalPlatform::SweepBySid` 내에서 통신 단절 관련 에러(`10006`) 발생 시 루프를 돌려 최대 30회 지연(1000ms Sleep) 재시도를 처리하고, 최종 실패 시 긴급 전역 변수(Circuit Breaker Flag)를 활성화하여 신규 진입을 자동 잠금 처리함.

---

## 4. 결론 및 향후 보완 로드맵
ATSE 청산 시퀀스는 대다수 메이저 시나리오를 정상 처리할 수 있는 아키텍처를 보유하고 있으나, 극단적인 예외 상에서의 견고함을 위해 위 3대 핵심 갭(특히 **유령 신호 Fast-Pass 누락** 및 **청산 직전 실물 동기화 누락**)을 교정하는 보완 리팩토링이 권장된다.

---
**문서 버전**: v1.0 (PDCA/Design Storage Standard 준수)
**작성 주체**: Antigravity AI Coding System
**승인 상태**: 최초 작성 및 검토 대기
