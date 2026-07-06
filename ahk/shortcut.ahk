#Requires AutoHotkey v2.0

A_MaxHotkeysPerInterval := 200

; 노브 업다운 -> 휠, 클릭 -> 터미널 
Volume_Up::Send("{WheelDown 3}")
Volume_Down::Send("{WheelUp 3}")
Volume_Mute:: {
    if WinExist("ahk_exe WindowsTerminal.exe")
        WinActivate("ahk_exe WindowsTerminal.exe")
    else
        Run("wt")
}
; 컨트롤 노브 업다운 -> 컨트롤 홈/엔드
^Volume_Up::Send("^{End}")
^Volume_Down::Send("^{Home}")

; F18 -> 컨트롤, F19 -> 알트 리맵
; KeyWait 방식: Up 이벤트 누락으로 인한 stuck 현상 방지
*F18:: {
    Send("{Blind}{Ctrl down}")
    KeyWait("F18")
    Send("{Blind}{Ctrl up}")
}
*F19:: {
    Send("{Blind}{Alt down}")
    KeyWait("F19")
    Send("{Blind}{Alt up}")
}

; F20 -> 다음 탭, 컨트롤 F20 -> 이전 탭
F20::Send("^{PgDn}")
^F20::Send("^{PgUp}")

; F21 -> 백스페이스, 컨트롤 F21 -> 되돌리기
F21::Send("{Backspace}")
^F21::Send("^z")

; F13 -> Obsidian, F14 -> 파일 탐색기, F15 -> 카카오톡, F16 -> Amaranth 10
; Obsidian: 보이면 포커스(최소화 시 복원) / 없으면 실행 (트레이에 숨지 않아 F14와 동일 패턴)
F13:: {
    hwnd := WinExist("ahk_exe Obsidian.exe")
    if hwnd {
        if WinGetMinMax("ahk_id " hwnd) == -1  ; 최소화 상태면 먼저 복원
            WinRestore("ahk_id " hwnd)
        WinActivate("ahk_id " hwnd)
    } else {
        Run(EnvGet("LOCALAPPDATA") "\Programs\Obsidian\Obsidian.exe")
    }
}
F14:: {
    if WinExist("ahk_class CabinetWClass")
        WinActivate("ahk_class CabinetWClass")
    else
        Run("explorer.exe")
}
; KakaoTalk: 보이면 포커스 / 트레이에 숨겨있으면 Show→Minimize→Restore 복원
F15:: {
    if WinExist("카카오톡 ahk_class EVA_Window_Dblclk") {
        WinActivate("카카오톡 ahk_class EVA_Window_Dblclk")
        return
    }
    DetectHiddenWindows(true)
    hwnd := WinExist("카카오톡 ahk_class EVA_Window_Dblclk")
    DetectHiddenWindows(false)
    if hwnd {
        DllCall("ShowWindow", "Ptr", hwnd, "Int", 2)  ; SW_SHOWMINIMIZED: 빈 창 없이 바로 최소화 상태로
        Sleep(300)
        WinRestore("ahk_id " hwnd)
        WinActivate("ahk_id " hwnd)
    }
}

; Amaranth: 보이면 포커스 / 트레이에 숨겨있으면 WM_APP+1 메시지로 복원
F16:: {
    if WinExist("ahk_exe AmaranthMessenger.exe") {
        WinActivate("ahk_exe AmaranthMessenger.exe")
        return
    }
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
            hr := DllCall("shell32\Shell_NotifyIconGetRect"
                , "Ptr", nii.Ptr, "Ptr", rect.Ptr, "Int")
            if hr == 0 {
                PostMessage(0x8001, A_Index-1, 0x0203, , "ahk_id " hwnd)
                break 2
            }
        }
    }
    DetectHiddenWindows(false)
}

; F17 -> 계산기 열기 (꾹 눌러도 1회만: 릴리스까지 대기해 auto-repeat 차단)
F17:: {
    Run("calc.exe")
    KeyWait("F17")
}

; 마우스 가운데 버튼 홀드 + 마우스 이동 -> 스크롤 이동
MButton:: {
    MouseGetPos(&prevX, &prevY)
    while GetKeyState("MButton", "P") {
        MouseGetPos(&curX, &curY)
        deltaX := curX - prevX
        deltaY := curY - prevY
        if (Abs(deltaX) >= 10) {
            if (deltaX > 0)
                Send("{WheelRight}")
            else
                Send("{WheelLeft}")
            prevX := curX
        }
        if (Abs(deltaY) >= 10) {
            if (deltaY > 0)
                Send("{WheelDown}")
            else
                Send("{WheelUp}")
            prevY := curY
        }
        Sleep(30)
    }
}

; VSCode + Chrome: 마우스 측면 버튼으로 탭 전환
#HotIf WinActive("ahk_exe Code.exe") || WinActive("ahk_exe chrome.exe")
XButton1::Send("^{PgUp}")
XButton2::Send("^{PgDn}")

#HotIf

; Obsidian: 마우스 측면 버튼으로 탭 전환
#HotIf WinActive("ahk_exe Obsidian.exe")
XButton1::Send("^{PgUp}") ; 4번 버튼 -> 이전 탭
XButton2::Send("^{PgDn}") ; 5번 버튼 -> 다음 탭
#HotIf

; Notion: 마우스 측면 버튼으로 탭 전환
#HotIf WinActive("ahk_exe Notion.exe")
XButton1::Send("^+{Tab}")
XButton2::Send("^{Tab}")
#HotIf

; VSCode 전용
#HotIf WinActive("ahk_exe Code.exe")
!XButton1::Send("!{Left}") ; 돌아가기
!XButton2::Send("!{Right}") ; 앞으로 이동
^+XButton1::Send("^+k") ; 라인 제거

F13::Send("^!b") ; 채팅 탭 토글
F21::Send("^+k") ; 라인 제거
#HotIf

; 윈도우 터미널 전용
#HotIf WinActive("ahk_exe WindowsTerminal.exe")
XButton1::Send("^+{Tab}") ; 이전 탭
XButton2::Send("^{Tab}") ; 다음 탭


^Volume_Up::Send("^+{End}") ; 제일 끝으로
^Volume_Down::Send("^+{Home}") ; 제일 처음으로
F20::Send("^{Tab}") ; 다음 탭
^F20::Send("^+{Tab}") ; 이전 탭
^w::Send("^+w") ; 탭 닫기 (Ctrl+W -> Ctrl+Shift+W)
^t::Send("^+t") ; 새 탭 (Ctrl+T -> Ctrl+Shift+T)

!1::Send("^!1") ; Alt+1 -> Ctrl+Alt+1
!2::Send("^!2") ; Alt+2 -> Ctrl+Alt+2
!3::Send("^!3") ; Alt+3 -> Ctrl+Alt+3
!4::Send("^!4") ; Alt+4 -> Ctrl+Alt+4
!5::Send("^!5") ; Alt+5 -> Ctrl+Alt+5
#HotIf
