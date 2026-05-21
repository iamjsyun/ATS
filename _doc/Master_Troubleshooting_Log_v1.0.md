# ATS Master Troubleshooting Log (v1.0)

## 1. 개요 (Overview)
본 문서는 ATS 시스템 운영 중 발생한 기술적 이슈와 해결 방안을 기록한 통합 지식 베이스이다. PDCA(Plan-Do-Check-Act) 사이클을 통해 재발 방지책을 수립한다.

---

## 2. 주요 장애 대응 이력

### 2.1 MQL5 샌드박스 로그 생성 실패 (Critical)
- **현상**: 시스템 로그 및 SID 로그 파일이 디스크에 생성되지 않음.
- **원인**:
    1. `FileOpen` 시 존재하지 않는 하위 폴더(`ATSE\`)가 포함되면 즉시 실패.
    2. 폴더 생성 API(`FolderCreate`) 오용 및 샌드박스 권한 제약.
- **해결 조치**:
    - **파일 명명 평탄화(Flattening)**: `ATSE_*.log`, `{sid}_*.log`와 같이 접두사를 활용하여 루트 경로(`Common/Files`)에 직접 생성.
    - 하위 디렉토리 의존성 완전 제거.

### 2.2 XTA 신호 감지 및 시퀀스 시작 오류 (High)
- **현상**: DB에 신호가 주입되어도 EA가 인지하지 못하거나 시퀀스가 -1 상태로 멈춤.
- **원인**:
    1. `CXFluentSequence` 빌드 시 시작 상태 변수가 초기화 전 참조됨.
    2. `DatabaseReset`만으로는 SQLite 신규 쿼리 결과가 반영되지 않는 캐싱 이슈.
- **해결 조치**:
    - `m_first_state` 도입으로 시작점 보존.
    - 폴링 시마다 `DatabasePrepare`를 수행하여 쿼리 무결성(Integrity) 확보.

### 2.3 Retcode 10016 (Invalid Stops) 대응 (High)
- **현상**: 주문 송신 시 브로커로부터 가격 거리 위반 에러 수수.
- **원인**: GOLD# 심볼의 높은 변동성 및 브로커의 `StopsLevel` 제약 미준수.
- **해결 조치**:
    - 주문 전송 직전 `ValidateStopLevel` 강제 호출.
    - 위반 시 SL/TP를 0으로 강제 리셋하여 주문 성공률 우선 확보.

---

## 3. 구조적 결함 분석 (Root Cause Analysis)

| 식별된 결함 | 위험 수준 | 근본 원인 | 개선 방향 |
| :--- | :---: | :--- | :--- |
| **검증 로직 파편화** | 상 | `CXGuard` 호출 지점이 여러 클래스에 분산 | `CXOrderManager` 내 단일 통로로 일원화 |
| **에러 마스킹** | 중 | 예외 발생 시 원본 `Retcode` 유실 | `xp.SetString()`을 통한 에러 전파 표준화 |
| **샌드박스 이해도** | 중 | MQL5 특유의 파일 시스템 제약 간과 | 평탄화 패턴(Flattening)을 표준 파일 규칙으로 채택 |

---

## 4. 정량적 요약
| 항목 | 조치 전 오류율 | 조치 후 목표 | 현재 상태 |
| :--- | :---: | :---: | :---: |
| 신호 감지 성공률 | 10% | 99.9% | 95% (개선 중) |
| 로그 가시성 | 0% | 100% | 100% (완료) |
| 주문 체결률(Error-free) | 80% | 95% | 92% (완료) |

---
**Last Updated**: 2026-05-21
**Governance**: Knowledge Base for ATS Troubleshooting.
