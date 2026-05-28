# 구현 계획서 - CXUI 오류 수정 및 지정가 계산 최적화 (v1.0)

본 계획서는 ATS UI(WPF) 내 개별 신호 뷰(UCXSignalView)에서의 SID 표시 색상 개선 및 지정가(Limit/Stop) 오더의 가격 계산 오동작 문제를 해결하기 위한 방안을 제시합니다.

## 제안된 변경 사항

### 1. UI 개선 (WPF Dashboard)

#### [MODIFY] [UCXSignalView.xaml](file:///d:/Projects/ATS/ATSA/ATSA/UI/UCtrls/UCXSignalView.xaml)
- `SID` 컬럼의 `DataGridTextColumn.ElementStyle`에 `DataTrigger`를 추가하여 방향(`dir`)에 따른 텍스트 색상을 동적으로 변경합니다.
  - `dir == 1` (BUY): `#2196F3` (Blue)
  - `dir == 2` (SELL): `#F44336` (Red)
  - 기본값: 일반 검은색 혹은 시스템 기본값

### 2. 비즈니스 로직 수정 (ATSA Core Service)

#### [MODIFY] [XTradePolicyService.Sequence.cs](file:///d:/Projects/ATS/ATSA/XTA/Services/XTradePolicyService.Sequence.cs)
- 지정가(`TYPE_LIMIT`) 및 역지정가(`TYPE_STOP`) 오더의 경우, 그리드 프로필의 오프셋(`profile.offset`)이 `0`인 경우에도 `te_limit`이 정책 기본값(예: 1000)으로 오염되어 가격이 잘못 계산되는 오류를 해결합니다.
- `s.type`에 따라 `te_limit` 할당 조건을 분기 처리합니다.
  - `s.type == XCode.TYPE_LIMIT` 또는 `XCode.TYPE_STOP`: `s.te_limit = profile.offset` (무조건 대입하여 `0`인 경우도 정상 처리)
  - `s.type == XCode.TYPE_LIMIT_TRAILING`: `s.te_limit = (profile.offset > 0) ? profile.offset : s.te_limit` (기존의 조건부 유지)

```csharp
// [v14.42] Conditional Override Logic: Only overwrite if profile has non-zero value
if (s.type == XCode.TYPE_LIMIT || s.type == XCode.TYPE_STOP)
{
    s.te_limit = profile.offset;
}
else if (s.type == XCode.TYPE_LIMIT_TRAILING)
{
    s.te_limit = (profile.offset > 0) ? profile.offset : s.te_limit;
}

s.limit_offset = profile.offset;
s.stop_offset = profile.offset;
```

## 검증 계획

### 자동화 테스트 (Automated Tests)
1. ATSA 프로젝트 빌드 검증: `dotnet build`를 실행하여 컴파일 오류가 없는지 확인합니다.
2. `XTA.Test` 유닛 테스트 실행하여 정책 적용 결과의 정합성을 검증합니다.

### 수동 검증 (Manual Verification)
1. DataManager에서 신호 주입 후 `UCXSignalView` 내의 `SID` 값이 방향에 따라 올바른 색상(BUY는 파란색, SELL은 빨간색)으로 표시되는지 확인합니다.
2. 지정가 그리드 오프셋이 `0`인 경우 생성된 자식 신호의 `price_signal` 값이 마스터 가격과 동일하게 유지되는지 그리드 및 로그에서 확인합니다.
