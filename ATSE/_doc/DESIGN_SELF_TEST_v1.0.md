# [Design] ATSE Self-Test Framework (v1.0)

## 1. 개요 (Overview)
본 문서는 ATSE의 비즈니스 로직(진입, 트레일링, 청산)을 실제 시장 환경 또는 백테스트 환경에서 검증하기 위한 **CSV 기반 시나리오 시뮬레이터** 설계를 정의한다. 개발자는 CSV 파일에 매매 시나리오를 정의하고, `TestRunner`가 이를 DB에 주입함으로써 ATSE가 실제 신호처럼 인식하여 시퀀스를 수행하도록 유도한다.

## 2. 설계 원칙 (Design Principles)
1.  **Production Parity**: ATSE의 운영 코드를 수정하지 않고, 외부에서 데이터(DB)만 조작하여 테스트한다.
2.  **Deterministic Testing**: CSV의 `release_delay` 필드를 통해 신호 주입 시점을 제어하여 결정론적 테스트를 수행한다.
3.  **Cross-Environment**: Live 차트(Expert)와 Strategy Tester(Backtest)에서 동일하게 동작한다.
4.  **Edit-Friendly**: 메모장이나 엑셀에서 즉시 수정 가능한 단순한 CSV 구조를 유지한다.

## 3. CSV 시나리오 구조 (Schema Design)

### 3.1 필드 정의 (Refined)
| 필드명 | 설명 | 예시 |
| :--- | :--- | :--- |
| `release_delay` | 이전 작업 후 대기 시간 (초, `TimeCurrent()` 기준) | 10 |
| `action` | 수행 작업 (`INSERT`, `UPDATE`, `EXIT`, `ARCHIVE`) | INSERT |
| `sid` | (선택) 직접 지정할 SID. 공백 시 자동 생성. | |
| `cno` | 채널 번호 (1001~9999) | 1001 |
| `sno` | 전략 번호 (1~99) | 1 |
| `symbol` | 대상 심볼 | GOLD# |
| `dir` | 방향 (1:Buy, 2:Sell) | 1 |
| `type` | 주문 타입 (1:TrailLim, 2:Lim, 9:Mkt) | 1 |
| `lot` | 계약수 | 0.1 |
| `sl_pts` | 손절 포인트 | 500 |
| `tp_pts` | 익절 포인트 | 1000 |
| `te_pts` | 트레일링 진입 포인트 | 200 |
| `ts_pts` | 트레일링 스탑 포인트 | 300 |
| `comment` | 시나리오 설명 | "Recovery Test" |

### 3.2 핵심 로직 정책
1.  **ID Generation**: `sid` 미지정 시 `CNO-SNO-DIR-TYPE-TimeCurrent()` 조합으로 고유 ID를 자동 생성하여 주입한다.
2.  **Market-Price Priority**: CSV의 가격 정보는 무시한다. `INSERT` 시점의 실시간 시장가(Ask/Bid)를 `price_sig`로 주입하여 ATSE가 즉시 계산에 착수하게 한다.
3.  **Time Synchronization**: 모든 대기 시간은 `TimeCurrent()`를 사용하여 백테스트와 라이브 환경의 정합성을 보장한다.
4.  **Lifecycle Archiving**: `ARCHIVE` 액션을 통해 테스트가 완료된 신호를 신호 테이블에서 삭제하고 정리를 수행한다.

## 4. 컴포넌트 설계 (Component Architecture)

### 4.1 `CXScenarioLoader`
- CSV 파일을 파싱하여 `CXParam` 객체 리스트(Queue)로 변환한다.
- MQL5 `FileOpen` 및 `FileReadString`을 사용하여 표준 파싱을 수행한다.

### 4.2 `CXScenarioRunner` (Expert Advisor / Script)
- `OnInit`: CSV 파일을 읽어 큐에 쌓는다.
- `OnTimer` (0.5s or 1.0s):
    - 큐의 맨 앞 시나리오의 `release_delay`를 체크한다.
    - 시간이 도래하면 `IDatabase` 인터페이스를 통해 `CXSignal` 레코드를 생성/수정한다.
    - `EXIT` 액션의 경우, DB에서 해당 CNO/SNO를 찾아 `xa_exit=1`로 업데이트한다.

### 4.3 `ATSE Core` (검증 대상)
- 평소와 같이 DB를 감시(Watcher)하다가 `TestRunner`가 주입한 신호를 발견하고 세션을 기동한다.

## 5. 핵심 테스트 시나리오 (Test Matrix)

1.  **Atomic Entry**: 단일 신호 진입 및 청산.
2.  **Hedge Mode**: 동일 심볼에 Buy/Sell 신호 동시 주입.
3.  **Pyramiding**: 동일 CNO/SNO에 대해 시간차를 두고 여러 신호 주입 (회차 증가 검증).
4.  **Multi-Channel**: 서로 다른 CNO(1001, 3001) 신호를 동시에 처리하는 병렬 세션 검증.
5.  **Trailing Volatility**: 가격이 급변하는 상황에서 `te_pts` 보정 로직 검증.
6.  **Remote Exit**: ATSE가 구동 중인 상태에서 외부(Simulator)가 DB의 `xa_exit`를 1로 바꿨을 때의 즉각 대응 여부.

## 6. Grill-Me: 심화 질문 (Critical Questions)

1.  **ID Mapping**: `EXIT` 액션 시, 시나리오 파일에는 `sid`가 없는데 어떻게 특정 신호를 타겟팅할 것인가? (CNO+SNO 조합? 아니면 내부 변수 활용?)
2.  **Backtest Time Sync**: Strategy Tester에서 `TimeCurrent()`는 백테스트 시간이다. CSV의 `release_delay`를 백테스트 시간과 어떻게 동기화할 것인가?
3.  **Price Simulation**: ATSE는 실제 시장가를 참조한다. CSV에 정의된 `price_sig`와 실제 차트의 가격 차이가 클 경우(예: 주말 주입), 테스트 결과가 왜곡되지 않겠는가?
4.  **Verification**: 테스트 성공 여부를 어떻게 자동으로 판별할 것인가? (로그 파일 분석? 아니면 DB의 `xe_status` 최종값 확인?)
