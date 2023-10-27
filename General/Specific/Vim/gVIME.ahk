#NoTrayIcon

#Include ..\..\..\Library\IME.ahk

SetTimer(gVimIMEwithCompatibility, 250)

gVIME_status  := [1, 0] ; [vim, others]

gVimIMEwithCompatibility() {
    static ime_compatibility
    ime_compatibility := GetIMECompatibility()
    vimactive := WinActive("ahk_exe gvim.exe")
    if vimactive && ime_compatibility != gVIME_status[1]
        ChangeIMECompatibility(gVIME_status[1])
    else if !vimactive && ime_compatibility != gVIME_status[2]
        ChangeIMECompatibility(gVIME_status[2])
}

#F1::{
    ime_compatibility := GetIMECompatibility()
    vimactive := !!WinActive("ahk_exe gvim.exe")
    ChangeIMECompatibility(gVIME_status[2 - vimactive] := !ime_compatibility)
}
