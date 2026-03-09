#Requires AutoHotkey v2.0

; 노브 업다운 -> 휠, 클릭 -> 터미널 
Volume_Up::Send("{WheelDown 3}")
Volume_Down::Send("{WheelUp 3}")
Volume_Mute::Run("wt")
^Volume_Up::Send("^{WheelUp 3}")
^Volume_Down::Send("^{WheelDown 3}")

; F18 -> 컨트롤, F19 -> 알트 리맵
*F18::Send("{Blind}{Ctrl down}")
*F18 Up::Send("{Blind}{Ctrl up}")
*F19::Send("{Blind}{Alt down}")
*F19 Up::Send("{Blind}{Alt up}")

; VSCode + Chrome: 마우스 측면 버튼으로 탭 전환
#HotIf WinActive("ahk_exe Code.exe") || WinActive("ahk_exe chrome.exe")
XButton1::Send("^{PgUp}")
XButton2::Send("^{PgDn}")

F13::Send("^{PgUp}")
F14::Send("^{PgDn}")
#HotIf

; VSCode 전용
#HotIf WinActive("ahk_exe Code.exe")
!XButton1::Send("!{Left}") ; 돌아가기
!XButton2::Send("!{Right}") ; 앞으로 이동
^+XButton1::Send("^+k") ; 라인 제거

F15::Send("!{Left}") ; 돌아가기
F16::Send("!{Right}") ; 앞으로 이동
F17::Send("^!b") ; 채팅 탭 토글
F20::Send("^z") ; 실행 취소
^F20::Send("^+z") ; 다시 실행
F21::Send("^+k") ; 라인 제거
#HotIf