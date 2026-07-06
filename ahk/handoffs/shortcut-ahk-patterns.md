# shortcut.ahk 단축키 관리 핸드오프

## 프로젝트 개요

- 파일: `shortcut.ahk` (단일 파일에 모든 단축키 관리)
- 빌드: `pnpm compile` → `shortcut.exe` 생성 후 자동 실행
- 환경: Windows 11, AutoHotkey v2.0 (64-bit), 노브(볼륨 키) + 펑션키(F13~F21) 기반 단축키 장치 사용 중

---

## 트레이 앱 복원 패턴 (핵심 노하우)

Windows 11에서 트레이 아이콘으로 숨겨진 앱을 복원하는 방법은 앱마다 다르다.
이 섹션은 디버깅 과정에서 얻은 패턴이다.

### 공통 구조

```ahk
F1x:: {
    ; 1) 이미 보이면 포커스만
    if WinExist("...") {
        WinActivate("...")
        return
    }
    ; 2) 숨겨진 경우 복원
    DetectHiddenWindows(true)
    ; ... 복원 로직 ...
    DetectHiddenWindows(false)
}
```

### KakaoTalk (EVA 프레임워크 / Chromium 기반)

- **창 클래스**: `EVA_Window_Dblclk`, 타이틀: `카카오톡`
- **트레이 등록 방식**: GUID 방식 → `Shell_NotifyIconGetRect`의 uID 방식 불가
- **복원 방법**: `SW_SHOWMINIMIZED(2)` → `WinRestore` 사이클
  - 단순 `WinShow`는 빈 흰색 창만 표시됨 (Chromium 렌더러 미초기화)
  - `WinShow` → `WinMinimize` → `WinRestore`도 깜빡임 발생
  - `SW_SHOWMINIMIZED`로 직접 최소화 상태 진입 → 빈 창 단계 건너뜀

```ahk
DllCall("ShowWindow", "Ptr", hwnd, "Int", 2)  ; SW_SHOWMINIMIZED
Sleep(300)
WinRestore("ahk_id " hwnd)
WinActivate("ahk_id " hwnd)
```

- **시도했으나 실패한 것들**:
  - `WinShow` + `WinActivate` → 빈 흰색 창
  - `PostMessage(WM_SYSCOMMAND, SC_RESTORE)` → 무반응
  - `WM_LBUTTONDBLCLK` 직접 전송 → 무반응
  - `Shell_NotifyIconGetRect` uID 스캔 (0~30) → 전부 미발견 (GUID 방식)
  - `WM_USER/WM_APP` 계열 메시지 전송 → 무반응
  - `InvalidateRect` + `UpdateWindow` → 빈 창 그대로

### Amaranth 10 (AmaranthMessenger.exe)

- **트레이 등록 방식**: uID 방식 → `Shell_NotifyIconGetRect` 동작
  - 발견된 uID: **3**, 콜백 메시지: **WM_APP+1 (0x8001)**
- **복원 방법**: `Shell_NotifyIconGetRect`로 tray HWND/uID 확인 후 `PostMessage`

```ahk
; NOTIFYICONIDENTIFIER 구조체 (64-bit: 40bytes)
niiSize    := A_PtrSize == 8 ? 40 : 28
hWndOffset := A_PtrSize == 8 ?  8 :  4
uIDOffset  := A_PtrSize == 8 ? 16 :  8

DetectHiddenWindows(true)
hwnds := WinGetList("ahk_exe AmaranthMessenger.exe")
for hwnd in hwnds {
    loop 10 {
        nii := Buffer(niiSize, 0)
        NumPut("UInt", niiSize,   nii, 0)
        NumPut("Ptr",  hwnd,      nii, hWndOffset)
        NumPut("UInt", A_Index-1, nii, uIDOffset)
        rect := Buffer(16, 0)
        hr := DllCall("shell32\Shell_NotifyIconGetRect", "Ptr", nii.Ptr, "Ptr", rect.Ptr, "Int")
        if hr == 0 {
            PostMessage(0x8001, A_Index-1, 0x0203, , "ahk_id " hwnd)  ; WM_APP+1, WM_LBUTTONDBLCLK
            break 2
        }
    }
}
DetectHiddenWindows(false)
```

- **시도했으나 실패한 것들**:
  - `WinShow` + `WinActivate` → 창은 보이지만 인터랙션 불가
  - `MouseClick` 더블클릭 시뮬레이션 → 오버플로우 트레이를 열었다 닫기만 함
  - Windows 11 트레이는 `ToolbarWindow321` 없음 → 기존 Win32 방식 불가

---

## Windows 11 트레이 환경 특이사항

- `Shell_TrayWnd` 하위에 `ToolbarWindow32` 없음 (Windows 11에서 XAML 기반으로 변경)
- `NotifyIconOverflowWindow` hwnd=0 (오버플로우 창 기본 닫혀있음)
- `UIAutomationClient.CUIAutomation` ProgID 미등록 → CLSID 직접 사용 필요
- `Shell_NotifyIconGetRect` API는 여전히 동작하나, 아이콘이 오버플로우에 있으면 오버플로우 버튼 좌표 반환
- GUID 방식으로 등록된 트레이 아이콘은 `Shell_NotifyIconGetRect`의 uID 방식으로 탐색 불가

---

## 새 앱 트레이 복원 추가 시 진단 절차

1. `Shell_NotifyIconGetRect`로 uID 스캔 → 발견 시 uID 기반 방식 사용
2. 발견 안 됨 → GUID 방식일 가능성 → WinShow로 창 표시 시도
   - 창이 정상 렌더링 → `DetectHiddenWindows(true)` + `WinShow` + `WinActivate`
   - 창이 빈 화면 → Chromium 계열 → `SW_SHOWMINIMIZED` + `WinRestore` 패턴
3. uID 발견 시 콜백 메시지 탐색:
   - `WM_APP+1 (0x8001)`, `WM_APP (0x8000)`, `WM_USER+1 (0x401)` 순으로 시도
   - `DetectHiddenWindows(true)` 상태에서 `PostMessage` 필수
   - wParam = uID, lParam = 0x0203 (WM_LBUTTONDBLCLK)

---

## 현재 상태

모든 단축키 정상 동작. F15(KakaoTalk) 깜빡임 없이 트레이 복원 성공. F16(Amaranth) 완벽 동작.

## 다음 단계

없음. 필요 시 새 앱 트레이 복원 키 추가 — 위 진단 절차 참고.
