# 전역 규칙 및 기억 파일 클라우드(Google Drive) 연동 구성 분석 보고 및 타 PC 설정 매뉴얼

## 1. 구성 분석 보고 (Configuration Analysis Report)

### 1.1 구성 목표 및 철학
현재 설정은 **"로컬 환경의 휘발성(재설치, PC 교체 등) 극복 및 다중 PC(사무실/자택 등) 간의 완벽한 개발 경험 동기화"**를 목표로 설계되었습니다. 모든 전역 설정(Global Settings), 개인 기억(Global Memory), 그리고 커스텀 명령어(Commands)를 로컬 C드라이브에서 Google Drive(G드라이브)로 분리하고, 심볼릭 링크(Symbolic Link)와 정션(Junction)을 활용하여 Gemini CLI가 이를 투명하게(Transparent) 인식하도록 구성했습니다.

### 1.2 핵심 인프라 매핑 현황 (Current Mapping Status)

| 리소스 유형 | 논리적 위치 (Gemini CLI 인식 경로) | 물리적 위치 (실제 저장소) | 매핑 방식 | 동기화 주체 |
| :--- | :--- | :--- | :--- | :--- |
| **전역 설정 및 메모리** | `C:\Users\Username\.gemini\` | `G:\내 드라이브\_Doc\gemini\` | **Symbolic Link** | Google Drive |
| **프로젝트 전역 명령어** | `D:\Projects\ATS\.gemini\commands\cloud\` | `G:\내 드라이브\_Doc\gemini\commands\project_ats\` | **Junction Link** | Google Drive |
| **프로젝트 설정** | `D:\Projects\ATS\.gemini\settings.json` | `D:\Projects\ATS\.gemini\settings.json` | 로컬 파일 | Git (Repository) |
| **프로젝트 메모리** | `G:\내 드라이브\_Doc\gemini\memory\ats\` | `G:\내 드라이브\_Doc\gemini\memory\ats\` | GEMINI.md 강제 | Google Drive |
| **무시 규칙 (.geminiignore)** | `D:\Projects\ATS\.geminiignore` | `D:\Projects\ATS\.geminiignore` | 로컬 파일 | Git (Repository) |

### 1.3 종합 분석 결론
1. **SSOT(Single Source of Truth) 확보**: 전역 설정과 메모리의 원본을 클라우드(`G:\내 드라이브\_Doc\gemini`)에 둠으로써 어느 PC에서 작업하든 항상 동일한 기억과 설정을 공유받게 되었습니다.
2. **이원화된 동기화 전략**: 코드베이스와 밀접하게 연관된 설정(`settings.json`, `.geminiignore`)은 **Git**으로 관리하고, 지속적으로 누적/변경되는 기억(Memory)과 전역/프로젝트 명령어(Commands)는 **Google Drive**로 동기화하여 버전 관리의 충돌을 방지했습니다.
3. **무결성(Integrity)**: 이 구조는 향후 Gemini CLI가 업데이트되거나 삭제 후 재설치되더라도, 링크만 다시 걸어주면 즉시 모든 환경이 복구되는 강력한 무결성을 자랑합니다.

---

## 2. 타 PC 동일 구성 설정 매뉴얼 (Setup Manual for Other PCs)

이 매뉴얼은 새로운 PC(예: 노트북 또는 사무실 PC)에서 현재와 완벽하게 동일한 Gemini CLI 클라우드 연동 환경을 구축하기 위한 가이드입니다.

### 전제 조건 (Prerequisites)
1. 새로운 PC에 **Google Drive 데스크톱 앱**이 설치되어 있고, `G:` 드라이브로 `내 드라이브`가 마운트되어 있어야 합니다.
2. **Git**이 설치되어 있고, ATS 프로젝트가 새로운 PC(예: `D:\Projects\ATS`)에 Clone 되어 있어야 합니다.
3. **Gemini CLI**가 1회 이상 실행되어 `C:\Users\[사용자명]\.gemini` 폴더가 생성되어 있어야 합니다.

### 단계별 설정 절차 (Step-by-Step Guide)

#### Step 1: 전역 설정 클라우드 심볼릭 링크 생성 (가장 중요)
이 작업은 로컬 사용자 프로필의 `.gemini` 폴더를 구글 드라이브와 연결합니다.
1. **관리자 권한**으로 PowerShell을 실행합니다. (시작 메뉴에서 PowerShell 우클릭 -> 관리자 권한으로 실행)
2. 아래 명령어를 복사하여 실행합니다.
   *(주의: 기존 로컬 폴더를 덮어쓰므로 1회성 초기 세팅 시에만 수행하세요.)*
```powershell
# 기존 로컬 .gemini 폴더 삭제 (초기화)
Remove-Item -Path "$env:USERPROFILE\.gemini" -Recurse -Force

# Google Drive 폴더로 심볼릭 링크 생성
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.gemini" -Target "G:\내 드라이브\_Doc\gemini"
```
3. `C:\Users\[사용자계정]` 폴더를 열어 `.gemini` 폴더 아이콘에 화살표(바로가기 모양)가 생겼는지 확인합니다.

#### Step 2: 프로젝트 커맨드 정션(Junction) 링크 연결
프로젝트 전용(ATS)으로 관리되는 클라우드 명령어를 로컬 프로젝트 폴더에 연결합니다.
1. **일반 권한**으로 명령 프롬프트(CMD) 또는 PowerShell을 실행합니다. (관리자 권한 아니어도 됨)
2. ATS 프로젝트가 위치한 경로(`D:\Projects\ATS`)로 이동하거나, 전체 경로를 지정하여 아래 명령어를 실행합니다.
```cmd
:: .gemini\commands 폴더가 없다면 생성
mkdir D:\Projects\ATS\.gemini\commands

:: 클라우드의 프로젝트 명령어 폴더를 로컬 'cloud' 폴더로 정션 연결
mklink /J D:\Projects\ATS\.gemini\commands\cloud "G:\내 드라이브\_Doc\gemini\commands\project_ats"
```
3. 정상적으로 연결되었다면 `D:\Projects\ATS\.gemini\commands\cloud` 폴더 진입 시 G드라이브에 있는 명령어들이 보입니다.

#### Step 3: 프로젝트 설정 및 메모리 확인
1. **프로젝트 설정 (`settings.json`)**: Git Repository에 포함되어 있으므로 `git pull`을 통해 자동으로 동기화되어 `D:\Projects\ATS\.gemini\settings.json`에 위치하게 됩니다. (추가 설정 불필요)
2. **프로젝트 메모리 (`memory\ats`)**: `GEMINI.md` 파일 내의 `[Session/Memory]` 규칙(G드라이브 강제 리다이렉션)에 의해 Gemini CLI가 구동될 때 자동으로 클라우드 메모리를 읽고 씁니다. (추가 설정 불필요)

---
**🎉 설정 완료:** 위 3단계(실제로는 2가지 명령 실행)만 거치면 새로운 PC에서도 기존 PC와 100% 동일한 설정, 명령어, 기억을 가진 Gemini CLI 환경에서 즉시 작업을 시작할 수 있습니다.