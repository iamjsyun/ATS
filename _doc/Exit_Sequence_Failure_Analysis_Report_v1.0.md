# Exit Sequence Failure Analysis Report (v1.0)

## 1. 개요 (Executive Summary)
본 보고서는 DB 내 특정 신호 레코드가 청산 의도(`xa_exit=1`) 및 진입 의도(`xa_entry=1`)가 정상적으로 주입되었음에도 불구하고, 실행 상태(`xe_status`)가 빈 값(0 / NULL) 상태로 동결되어 청산 시퀀스가 작동하지 않는 동작 오류 현상에 대한 원인 분석 및 해결 방안을 제시한다.

### 분석 대상 데이터
* **ID**: `13704`
* **SID**: `1001-26052615-01-00-1-1`
* **GID**: `1001-26052615-01-00`
* **CNO / SNO**: `1001` / `1`
* **의도 필드**: `xa_entry=1` (진입 활성), `xa_exit=1` (청산 요구 활성)
* **상태 필드 (`xe_status`)**: 빈 값 (0 또는 NULL)

---

## 2. 동작 실패 근본 원인 분석 (Root Cause Analysis)

ATSE 파이프라인의 생명주기 및 의존성 연결 분석 결과, 세션 생성 및 가동을 제어하는 **Watcher 계층**에서 아래와 같은 세 가지 유력한 오작동 가설이 도출되었다.

```
[신호 감지: Discovery]
         │
         ▼
[신호 검증: Validation] ──► (ValidateSID 통과, ticket=0 이므로 AssetBypass 우회)
         │
         ▼
[세션 생성: Spawning] ──► [가설 A] DB Pre-lock 락킹 실패 (locked = false) ──► 세션 Start 취소
         │           ──► [가설 B] UI/팩토리 생성 오류로 세션 생성 실패 ──► DB 미기록 상태 동결
         ▼
[세션 기동: Session.Start] (진입 안 됨 -> xe_status가 0 상태로 방치)
```

### [가설 A] DB Pre-lock (UpdateStatus) 실패로 인한 세션 기동 차단 (가장 유력)
* **원인**: `CXStepSpawning.mqh`는 세션 매니저가 세션을 정상 빌드한 직후, DB 상태를 `XE_PENDING_REQ (1)`로 갱신하기 위해 `repo.UpdateStatus(sig)`를 실행하여 선제적 락킹(`Pre-lock`)을 확인한다.
* **현상**: 이 데이터베이스 쓰기 과정에서 SQLite 락(Lock) 충돌 또는 쿼리 실패가 발생하여 `locked = false`로 판정될 경우, 엔진은 세션 구동(`session.Start()`)을 강제 중단하고 메모리 상의 신호 인스턴스를 즉시 파괴(`SAFE_DELETE`)한다.
* **결과**: 세션이 기동하지 않았으므로 DB의 `xe_status` 및 관련 필드는 최초 주입 상태인 `0` (비어 있음) 상태로 멈추게 된다.

### [가설 B] 티켓 미발급 (Ticket=0) 상태에서의 세션 스폰 실패
* **원인**: 해당 신호는 `xe_status`가 `0`인 초기 상태에서 청산 명령(`xa_exit=1`)이 들어왔으며, 실제 대기 주문이나 포지션이 체결되지 않아 물리적 티켓이 존재하지 않는 상태(`ticket = 0`)이다.
* **현상**: `CXStepValidation`의 `Exit-Priority Bypass` 조건에 의해 검증 단계를 간신히 통과하여 `Spawning` 단계로 넘어갔으나, `CXSessionManager`가 `XE_READY (0)` 상태에 의거하여 `CXSessionEntry` 세션을 생성하려 할 때 팩토리 의존성(`m_factory` 등) 충돌로 인해 세션 객체 생성 자체가 실패했을 가능성이 있다.
* **결과**: `session` 객체가 NULL로 리턴되면서 DB 업데이트 없이 락이 풀려 상태 갱신이 누락되었다.

### [가설 C] SID 문자열의 공백 패딩으로 인한 SQL 매칭 실패
* **원인**: `CXStepSpawning` 내부적으로는 SID 앞뒤의 공백을 제거(`StringTrim`)하여 활성 세션을 검색하지만, DB 리포지토리(`CXSignalRepository.mqh`)에 저장하거나 업데이트 쿼리를 날릴 때는 `sig.GetSid()` 원본 문자열을 그대로 사용한다.
* **현상**: 문자열에 미세한 공백이나 제어문자가 포함되어 있을 경우, SQLite의 `WHERE sid = '%s'` 조건 매칭이 실패하여 DB 상에서 행(Row) 업데이트가 무시되고 결과적으로 어떠한 상태 변경 로그도 기록되지 않는 현상이 발생한다.

---

## 3. 시정 조치 및 개선 아키텍처 제안 (Corrective Actions)

청산 시퀀스가 어떠한 상황에서도 동결되지 않고 즉시 완료되도록 파이프라인 구조를 다음과 같이 고도화한다.

### 1단계: 티켓 미발급 신호에 대한 즉시 패스트 패스(Fast-Pass) 적용
물리적으로 개설된 주문이나 포지션이 전혀 없는(`ticket <= 0`) 신호에 청산 의도(`xa_exit=1`)가 감지된 경우, 무겁게 세션을 스폰하는 단계를 거치지 않고 **Watcher Validation 단계에서 즉시 청산 완료 마킹**을 진행하여 DB를 클린업한다.

```mql5
// CXStepValidation.mqh 내의 Exit-Priority Bypass 로직 보완안
if(sig.GetXAExit() == XA_ACTIVE) {
    ulong ticket = (ulong)sig.GetTicket();
    
    // [보완] 물리 티켓이 아예 생성된 적이 없는 경우, 세션 구동 없이 즉시 청산 완료 마킹
    if(ticket <= 0) {
        string skipMsg = "Auto-Closed: No physical asset generated yet. Fast-tracking exit.";
        IRepository* repo = CX_GET_OBJ(ctx, "repo", IRepository);
        
        CXMessageProvider::UpdateStatus(sig, XE_CLOSED_SIGNAL, skipMsg);
        sig.SetXAExit(XA_CLOSED_COMPLETED); // xa_exit=2 마킹
        
        if(IS_VALID(repo)) repo.ForceUpdateIntent(sig);
        activeList.Delete(i);
        continue;
    }
}
```

### 2단계: SID 문자열 거버넌스 강화
* `CXSignal` 모델에 신호를 바인딩하거나 DB에서 로드하는 즉시 `sid` 및 `gid` 속성에 대해 `StringTrim` 처리를 강제하여 공백 문자로 인한 SQL 업데이트 유실을 원천 차단한다.

### 3단계: SQLite DB Pre-lock 리트라이(Retry) 구현
* DB 커넥션이 일시적으로 바쁠 때(SQLite `SQLITE_BUSY` 상태) 발생하는 Pre-lock 실패를 해결하기 위해, `repo.UpdateStatus` 수행 시 실패하면 짧은 지연(Sleep 10ms) 후 최대 3회 재시도하도록 락킹 로직을 보호한다.

---
**문서 버전**: v1.0 (PDCA/Design Storage Standard 준수)
**작성 주체**: Antigravity AI Coding System
**승인 상태**: 최초 작성 및 검토 대기
