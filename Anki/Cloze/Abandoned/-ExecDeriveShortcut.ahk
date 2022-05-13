; Exec 版派生捷径
;;; 使用 Exec 进行命令操作，需搭配 Cloze 使用。可拓展性强；但效率较低，性能差，且兼容性不佳。
;;;;; 全局捷径
;;;;;;; Win + Q        设置当前激活窗口为标记窗口
;;;;;;; Q + Q          跳转到标记窗口
;;;;;;; W + W          跳转到 Add 窗口
;;;;;;; E + E          跳转到 Browse 窗口
;;;;;;; R + R          跳转到 Anki 主窗口
;;;;; Anki 捷径
;;;;;;; `              保存卡片
;;;;;;; CapsLock       输入 <br> 并换行
;;;;;;; Ctrl + V       格式化输出（词性智能空格 & 标点智能替换为中文）
;;;;; 自定义捷径
;;;;;;; 普通快捷键
;;;;;;;;; 添加 <key>::<command>
;;;;;;; 双击快捷键
;;;;;;;;; 1. 添加 $<key>::Set("<key>")
;;;;;;;;; 2. 在 Keys 中添加键值对 "<key>" - "{"press": "<key Up>_press", "command": "<command>"}"

Exec(s, flag := "Default") {
    static init
    if !init {
        init := 1
        ss =
        (%
        DetectHiddenWindows, On
        RegExMatch(flag, "<<(.*?)>>", r)
        WinWaitClose, ahk_pid %r1%
        WinGet, list, List, %r% ahk_class AutoHotkeyGUI
        Loop, % list {
            IfEqual, myid, % id:=list%A_Index%, Continue
            WinGet, pid, PID, ahk_id %id%
            WinClose, ahk_pid %pid% ahk_class AutoHotkey
            WinWaitClose, ahk_pid %pid%,, 3
            if ErrorLevel
                Process, Close, %pid%
        }
        )
        Exec(ss, "AutoClear")
    }
    pid := DllCall("GetCurrentProcessId")
    add = `nflag = <<%pid%>>[%flag%]`n
    (%
        #NoEnv
        #NoTrayIcon
        DetectHiddenWindows, On
        Gui, Gui_Flag_Gui: Show, Hide, %flag%
        Gui, Gui_Flag_Gui: +Hwndmyid
        WinGet, list, List, %flag% ahk_class AutoHotkeyGUI
        Loop, % list {
            IfEqual, myid, % id:=list%A_Index%, Continue
            WinGet, pid, PID, ahk_id %id%
            WinClose, ahk_pid %pid% ahk_class AutoHotkey
            WinWaitClose, ahk_pid %pid%
        }
        DetectHiddenWindows Off
    )
    s := add "`n" s "`nExitApp`n#SingleInstance off`n"
    s := RegExReplace(s, "\R", "`r`n")
    shell := ComObjCreate("WScript.Shell")
    exec := shell.Exec(A_AhkPath " /ErrorStdOut *")
    exec.StdIn.Write(s)
    exec.StdIn.Close()
}
Set(key) {
    local key_press := Keys[key].press, function := Func("Command").Bind(key)
    if (%key_press% > 0) {
        %key_press% ++
        return
    }
    %key_press% := 1
    SetTimer %function%, -200
}
Command(key) {
    local key_press := Keys[key].press
    if (%key_press% = 1)
        SendInput %key%
    else if (%key_press% = 2)
        Exec(Keys[key].command, "Command")
    Exec("", "Command")
    %key_press% := 0
}

Global Keys := {"q": {"press": "Q_press", "command": ""}
              , "w": {"press": "W_press", "command": "WinActivate Add"}
              , "e": {"press": "E_press", "command": "WinActivate Browse"}
              , "r": {"press": "R_press", "command": "WinActivate PilgrimLyieu - Anki"}}

#q::Keys.q.command := "WinActivate ahk_id " WinActive("A")
$q::Set("q")
$w::Set("w")
$e::Set("e")
$r::Set("r")

#IfWinActive ahk_exe anki.exe
`::SendInput ^{Enter}
CapsLock::SendInput {Text}<br>`n
^v::
Result := RegexRePlace(Trim(Clipboard, " `t`r`n"), "(n|v|adj|adv|prep|conj|vt|vi)\.\s?", "$1. ")
for e, c in {",": "，", ".": "。", "?": "？", "!": "！", ":": "：", ";": "；", "(": "（", ")": "）", "[": "【", "]": "】"}
    Result := RegexReplace(Result, (e ~= "[([]") ? ((e ~= "[.?()[\]]" ? "\" e : e) "(?=\s?[\x{4e00}-\x{9fa5}])") : ("(?:[\x{4e00}-\x{9fa5}]\s?)\K" (e ~= "[.?()[\]]" ? "\" e : e)), c)
SendInput {Text}%Result%
return
#IfWinActive