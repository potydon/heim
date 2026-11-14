#Requires AutoHotKey v2.0
#SingleInstance Force

; ---
; ---- GlazeWM Keybinds -----
userProfilePath := EnvGet("USERPROFILE")
glazewmc(cmd){
	RunWait(format("glazewm.exe command {}", cmd), , "Hide")
}

; Programs
!e::Run userProfilePath

; Utilities
!o::Send "#^v"				;Audio Output
!+o::Send "#p"				;Screen Output

; Screenshot whole screen
!p::{
	Send "#{PrintScreen}"
	Sleep 300
	TrayTip "Screenshot taken!", "File saved in Pictures/Screenshots", 1
}

; Screenshot active window
!+p::{
	Send "!{PrintScreen}"
	Sleep 300

	TargetDir := A_MyDocuments "\..\Pictures\Screenshots"
	if !DirExist(TargetDir)
		DirCreate(TargetDir)

	TimeStamp := FormatTime(, "yyyy-MM-dd_HH.mm.ss")
	FilePath := TargetDir "\screenshot_" Timestamp ".png"

	PowerShellCmd := 'powershell.exe -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; if ([System.Windows.Forms.Clipboard]::ContainsImage()) { [System.Drawing.Bitmap][System.Windows.Forms.Clipboard]::GetImage().Save(\"' FilePath '\", [System.Drawing.Imaging.ImageFormat]::Png) }"'
	Run(PowerShellCmd, , "Hide")
	Sleep 200
	TrayTip "Screenshot taken!", "File saved in Pictures/Screenshots", 1
}

; Volume & Brightness
!m::Send "{Volume_Mute}"
!,::Send "{Volume_Down}"
!.::Send "{Volume_Up}"
!+,::bright(5,"-")
!+.::bright(5,"+")

!f::F11
!+f::glazewmc("toggle-fullscreen")
!+m::glazewmc("toggle-minimized")

!q::{
    check := WinExist("A")
	if !check
		return

	title := WinGetTitle("ahk_id " check)
	if (title = "")
		title := "Untitled"

	winClass := WinGetClass("ahk_id " check)
	if (winClass = "progman" || winClass = "WorkerW" || winClass = "shell_TrayWnd" || winClass = "buttery-taskbar")
		return

	msgTitle := "Warning - Close Window"
	hasBeenActive := false

	setTimer(CheckFocus, 50)
	result := MsgBox("Confirm to Close " title "?", msgTitle, "YesNoCancel")
	setTimer(CheckFocus, 0)

	if (result = "Yes")
		glazewmc("close")
	
	CheckFocus(){
		targetWindow := msgTitle " ahk_class #32770"

		if !WinExist(targetWindow)
			return

		if WinActive(targetWindow)
			hasBeenActive := true
		else if (hasBeenActive) {
			WinClose(targetWindow)
			SetTimer(CheckFocus, 0)
		}
	}
}

!+q::{
	hwnd := WinExist("A")
	if !hwnd
		return

	title := WinGetTitle("ahk_id " hwnd)
	winClass := WinGetClass("ahk_id " hwnd)
	pid := WinGetPID("ahk_id " hwnd)
	fullPath := WinGetProcessPath("ahk_id " hwnd)
	exeName := ""
	SplitPath(fullPath, &exeName)

    MsgBox(
		"Title: " title "`nPID  : " pid  "`nClass : " winClass "`nExec : " exeName "`nPath : " fullPath,
		"Active window Informations",
		"OK"
	)
}

; Functions (Do Not Delete)
bright(inputNum:=0,option:=""){
  Switch option {
    Default: ; bright(70) sets brightess to 70
      setBright(inputNum)

    Case "+" : ; bright(10,"+") increases brightess by 10
      setBright(getBright()+inputNum)

    Case "-" : ; bright(10,"-") decreases brightess by 10
      setBright(getBright()-inputNum)
  }
}
setBright(inputB){
  targetB:=(inputB<100)?(inputB):(100)  ; Maximum of 100
  targetB:=(inputB>0)?(inputB):(0)      ; Minimum of 0
  For property in ComObjGet( "winmgmts:\\.\root\WMI" ).ExecQuery( "SELECT * FROM WmiMonitorBrightnessMethods" )
    property.WmisetBrightness( 1, targetB )
  Tooltip(getBright())
  SetTimer( ()=>ToolTip(), -1000)
}
getBright(){
	For property in ComObjGet( "winmgmts:\\.\root\WMI" ).ExecQuery( "SELECT * FROM WmiMonitorBrightness" )
    return property.CurrentBrightness
}
