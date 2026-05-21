# Circular Reference Analysis Report - ATS Project

## 1. 개요
프로젝트 내 `#include` 종속성 분석을 통한 순환 참조(Circular Reference) 구조 분석 보고서.

## 2. 주요 순환 참조 클러스터
- **Cluster A (Core Domain)**: `CXTradingSession`, `CXOrderManager`, `CXPositionManager`, `CXExitManager` 간의 강한 상호 의존성.
- **Cluster B (Infra-Domain Bridge)**: `CXDatabase`, `CXSignalRepository` 및 `Domain/Common` 모듈 간의 레이어 역전 구조.

## 3. 통계
- 분석 대상: 134개 .mqh 파일
- 주요 루프: 15개 이상의 잠재적 순환 참조 경로 발견
- 핵심 결합: 5개 코어 클래스가 전체 종속성의 60% 이상 차지.

## 4. 제언
- 전방 선언(Forward Declaration) 적극 도입.
- 구현부 파일 내 `#include` 이동.
- 인터페이스(IX) 중심의 의존성 주입 강화.

## 5. 결론
내부 컴파일 에러의 원인으로 의존성 그래프의 과도한 결합이 지목됨. 우선순위 높은 Core 모듈부터 의존성 분리 필요.

*Date: 2026-05-13*
