# Retcode 10016 (Invalid Stops) 분석 및 대응 보고서
**날짜**: 2026-05-19
**상태**: 정밀 분석 완료 및 수정안

## 1. 오류 상세 (Retcode 10016)
OrderOpen 호출 시 브로커로부터 10016 - invalid stops 에러를 수신함. 이는 MT5의 주문 규칙상 SL/TP 가격이 현재가와 너무 가깝거나(StopsLevel 위반), 계산된 절대 가격이 브로커의 요구사항을 충족하지 못할 때 발생함.

## 2. 원인 분석
- **StopsLevel 미준수**: GOLD# 심볼은 변동성이 커서 브로커마다 요구하는 최소 가격 거리(StopsLevel)가 존재함. 현재 로직이 계산한 sl_price, 	p_price가 현재가와 너무 가깝거나, 브로커가 요구하는 정규화(Normalization) 단위를 미세하게 벗어났을 가능성이 높음.
- **주문 실행 로직의 간극**: OrderOpen 실행 직전, 계산된 SL/TP가 해당 심볼의 유효성 검사를 통과했는지 확인하는 로직이 주문 전송 시점(OrderOpen 호출)에는 누락되어 있음.

## 3. 조치 계획 (Fix Plan)
- **강제 검증 추가**: OrderOpen 실행 직전, 최종적으로 계산된 SL/TP 값이 ValidateStopLevel 기준을 통과하는지 검증을 추가하여 에러 발생 시 브로커 전송 전 차단하고 실패 사유를 로그에 남김.
- **StopsLevel 예외 처리**: 계산된 가격이 StopsLevel에 미달하는 경우, 해당 SL/TP를 0으로 강제 리셋하여 '손절/익절 없음'으로 주문을 전송함으로써 10016 에러를 회피.

## 4. 구조적 개선 권고
- CXGuard의 ValidateStopLevel을 OrderManager 내부 주문 전송 직전에 의무 호출하도록 강제함.
- 브로커의 StopsLevel 정보를 SymbolInfo로부터 실시간으로 획득하여 계산 로직에 반영함.
