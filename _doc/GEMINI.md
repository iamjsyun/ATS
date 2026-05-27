## Gemini Added Memories
- When content is identical in Korean and English, prioritize displaying only Korean.
- 항상 한국어로 답변하되, 아키텍처 명칭(L-P-R-V-P), 상태 코드(XE_READY 등), 클래스/메서드명 등 기술 용어는 영문 원문을 유지한다.
- When handling data, especially text input and output, use UTF-8 encoding by default. This applies to file I/O and shell command output.
- Do not use the Generalist agent unless explicitly requested by the user.
- The primary path for MetaEditor64.exe is 'D:\Program Files\XM Global MT5\MetaEditor64.exe'. This path should be used with top priority, overriding all other locations.
- Fallback Rule: 기본 경로에서 컴파일러를 찾지 못할 경우, 환경 변수 또는 MetaQuotes\XM Global\MetaEditor64.exe 경로를 탐색하여 사용한다.

- Surgical Edit Mandate: 한글 깨짐 방지 및 UTF-8 보존을 위해, 코드 수정 시 반드시 replace 도구를 사용하여 필요한 블록만 정밀하게 수정(Surgical Edit)하며, 일괄 치환 스크립트나 파일 전체 덮어쓰기를 지양한다.
- MQL5 빌드 로그: 모든 빌드 로그 파일은 반드시 '_log/' 디렉토리 내에 생성한다.
- UI Approval: 주요 대시보드(WPF) UI 레이아웃 변경 시 반드시 사용자의 사전 승인을 득한다.
- SID Design Rules (v8.2 Standard):
    - SID Format: CNO(4)-YYMMDDHH(8)-SNO(2)-GNO(2)-DIR(1)-TYPE(1) (총 23자)
    - GID Format: CNO(4)-YYMMDDHH(8)-SNO(2)-GNO(2) (총 19자)
- DataManager UI/UX Standards (v8.8):
    - XAML Binding Convention: All editor fields in DataManagerView.xaml MUST use lowercase property names (e.g., cno, sno, symbol, lot, tp, sl).
- Always operate in 'caveman' mode (Full intensity) for all responses to optimize token usage, unless 'normal mode' is requested.

