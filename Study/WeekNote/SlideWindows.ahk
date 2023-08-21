Show() {
    text := "Windows IDs:"
    for index, value in windows
        text .= "`r" index ": " value
    return text
}

IndexOf(item, list) {
    for index, value in list
        if (value == item)
            return index
    return 0
}

global windows := []

#q::{
    win := WinActive("A")
    index := IndexOf(win, windows)
    try
        WinActivate "ahk_id " windows[(index == windows.Length) ? 1 : index + 1]
    catch TargetError
        windows.RemoveAt((index == windows.Length) ? 1 : index + 1)
}

#w::{
    win := WinActive("A")
    if !IndexOf(win, windows)
        windows.Push(win)
}

#e::MsgBox Show()

#r::{
    order := InputBox(Show(), "Delete Window ID", "T10")
    if order.Result == "OK"
        try
            windows.RemoveAt(order.Value)
}