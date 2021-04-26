#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; 为以下方法设置字符集：FileRead, FileReadLine, Loop Read, FileAppend, and FileOpen().
FileEncoding, UTF-8
; 配置菜单栏子选项
Menu, FileMenu, Add, 打开文件, FileOpen
Menu, FileMenu, Add  ; 分割线
Menu, FileMenu, Add, 退出, FileExit
Menu, FuncMenu, Add, 添加分类, AddCategory
Menu, FuncMenu, Add, 我的博客, OpenPage
Menu, HelpMenu, Add, 关于, HelpAbout
; 配置菜单栏
Menu, MenuBar, Add, 文件, :FileMenu
Menu, MenuBar, Add, 功能, :FuncMenu
Menu, MenuBar, Add, 帮助, :HelpMenu
; 将菜单栏添加到窗口
Gui, Menu, MenuBar

Gui, +Resize  ; 使窗口大小可调整

Gui, Add, Edit, vMainEdit ReadOnly W400 R30 ; 创建编辑栏，用于展示文本内容，命名为MainEdit，宽600高20行
Gui, Font, s11
Gui, Add, Text, vTitleText, 标题:
Gui, Add, Edit, vTitleEdit W400 R1 ; 创建编辑栏，用于为文章命名
Gui, Add, ListBox, vCateListBox W400 r10
Gui, Add, Button, Default vUploadButton w80, 上传
Gui, Add, CheckBox, vPublishCheckBox, 同时发布
Gui, Show,, 拖入文件上传 ; 命名并显示窗口
CurrentFileName := ""
command := "python " A_ScriptDir "\cnblog_uploader.py -c"
categories := ExecCommand(command)
Loop, parse, categories, `,
{
    GuiControl,, CateListBox, %A_LoopField%
}
return

FileOpen: ; 通过windows对话框打开文件
Gui +OwnDialogs  ; Force the user to dismiss the FileSelectFile dialog before returning to the main window.
FileSelectFile, SelectedFileName, 3,, Open File, Text Documents (*.txt)
if not SelectedFileName
    return
Gosub FileRead
return

GuiDropFiles:  ; 启用拖入文件支持
Loop, Parse, A_GuiEvent, `n
{
    SelectedFileName := A_LoopField  ; 只取拖入的第一个文件
    break
}
GuiControl,, TitleEdit  ; 清空文章名编辑栏
Gosub FileRead
return

FileRead:  ; 调用该方法需要存在SelectedFileName变量
FileRead, MainEdit, %SelectedFileName%
if ErrorLevel
{
    MsgBox, 无法打开"%SelectedFileName%"
    return
}
GuiControl,, MainEdit, %MainEdit%  ; 将读取到的内容显示出来
CurrentFileName := SelectedFileName
Gui, Show,, %CurrentFileName%   ; 将文件路径显示到窗口标题
return

AddCategory:
MsgBox, 添加成功
return

OpenPage:
Run, "https://www.cnblogs.com/"
return

HelpAbout:
Gui, About:+owner1  ; Make the main window (Gui #1) the owner of the "about box".
Gui +Disabled  ; Disable main window.
Gui, About:Add, Text,, 本程序由AutoHotKey编写。
Gui, About:Add, Button, Default, OK
Gui, About:Show
return

Button上传:
GuiControlGet, TitleEdit ; 直接赋值给TitleEdit变量
GuiControlGet, CateListBox ; 直接赋值给CateListBox变量
GuiControlGet, PublishCheckBox ; 值为0或1
if (!TitleEdit) {
    MsgBox, 请输入标题!
} else if (!CateListBox) {
    MsgBox, 请选择类别!
} else {
    SelectedFileName = "%SelectedFileName%"
    TitleEdit = "%TitleEdit%"
    CateListBox = "%CateListBox%"
    command := "python " A_ScriptDir "\cnblog_uploader.py " SelectedFileName " " TitleEdit " " CateListBox " " PublishCheckBox
    result := ExecCommand(command)
    if (InStr(result, "-") == 1){
        MsgBox, 上传失败
    } else {
        MsgBox, 上传成功 %result%
        Run, %result%
    }
}
return

AboutButtonOK:  ; This section is used by the "about box" above.
AboutGuiClose:
AboutGuiEscape:
Gui, 1:-Disabled  ; Re-enable the main window (must be done prior to the next step).
Gui Destroy  ; Destroy the about box.
return

GuiSize:
if (ErrorLevel = 1)  ; The window has been minimized. No action needed.
    return
; Otherwise, the window has been resized or maximized. Resize the Edit control to match.
NewWidth := A_GuiWidth - 20
NewHeight := A_GuiHeight - 280
GuiControl, Move, MainEdit, W%NewWidth% H%NewHeight%
GuiControl, Move, CateListBox, % "y" A_GuiHeight-250 "w" NewWidth
GuiControl, Move, TitleText, % "y" A_GuiHeight-85
GuiControl, Move, TitleEdit, % "y" A_GuiHeight-65 "w" NewWidth
GuiControl, Move, PublishCheckBox, % "x" A_GuiWidth-180 "y" A_GuiHeight-30
GuiControl, Move, UploadButton, % "x" A_GuiWidth-88 "y" A_GuiHeight-35
return

FileExit:     ; User chose "Exit" from the File menu.
GuiClose:  ; User closed the window.
ExitApp


; 上传
Upload() {
    GuiControlGet, TitleEdit
    GuiControlGet, CateListBox
    if (!TitleEdit) {
        MsgBox, 请输入标题!
    } else if (!CateListBox) {
        MsgBox, 请选择类别!
    } else {
        SelectedFileName = "%SelectedFileName%"
        TitleEdit = "%TitleEdit%"
        CateListBox = "%CateListBox%"
        command := "python " A_ScriptDir "\cnblog_uploader.py " SelectedFileName " " TitleEdit " " CateListBox
        result := ExecCommand(command)
        if (result != "-1") {
            MsgBox, 上传成功
            Run, %result%
        } else {
            MsgBox, 上传失败
        }
    }
}

; 执行控制台命令
; 所需参数:command
ExecCommand(command) {
    shell := ComObjCreate("WScript.Shell")
    exec := shell.Exec(ComSpec " /C " command) ;相当于cmd /C python...
    result := exec.StdOut.ReadAll()
    Return result
}