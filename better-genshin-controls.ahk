#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#MaxHotkeysPerInterval 100
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.


; =======================================
; Global variables
; =======================================

; Global state
AutoAttackEnabled = 0

; Expedition duration coordinates
Duration4H := { X: 1500, Y: 700 }
Duration20H := { X: 1800, Y: 700 }

; ores:
WhisperingWoodsExpedition := { MapNumber: 0, X: 1050, Y: 330 }
DadaupaGorgeExpedition := { MapNumber: 0, X: 1170, Y: 660 }
YaoguangShoalExpedition := { MapNumber: 1, X: 950, Y: 450 }

; mora:
StormterrorLairExpedition := { MapNumber: 0, X: 550, Y: 400 }
DihuaMarshExpedition := { MapNumber: 1, X: 728, Y: 332 }


; =======================================
; Script initialization
; =======================================

Gosub, PauseLoop


; =======================================
; Technical
; =======================================

; Pause script
Pause::
    Suspend
    ; Pause ; script won't be unpaused
return

; Reload script
Numpad0::
    Reload
return

PauseLoop:
    Suspend ; run suspended
    loop {
        WinWaitActive, ahk_exe GenshinImpact.exe
        Suspend, Off
        WinWaitNotActive, ahk_exe GenshinImpact.exe
        Suspend, On
    }
return

; =======================================
; Auto attack
; =======================================

XButton1::
    if (AutoAttackEnabled) {
        Hotkey, *~LButton, NormalAutoAttack, Off
        Hotkey, *RButton, StrongAttack, Off
        Message := "Disabled"
    } else {
        Hotkey, *~LButton, NormalAutoAttack, On
        Hotkey, *RButton, StrongAttack, On
        Message := "Enable"
    }
    AutoAttackEnabled := !AutoAttackEnabled

    ToolTip, %Message%
    SetTimer, HideToolTip, -700
return

HideToolTip() {
    ToolTip
}

NormalAutoAttack() {
    SetTimer, SpamLeftClick, 150
    keyWait, LButton
    SetTimer, SpamLeftClick, Off
}

SpamLeftClick() {
    MouseClick left
    Sleep, 150
}

StrongAttack() {
    Click, down
    Sleep 350
    Click, up
}




; =======================================
; Pick up on press
; =======================================

$*f::
    PressF()
    SetTimer, PressF, 40
    KeyWait, f
    SetTimer, PressF, Off
return

PressF() {
    Send, {f}
}



; =======================================
; Spam left click
; =======================================

NumpadSub::
While ( GetKeyState( "NumpadSub","P" ) ) {
      MouseClick, left
      Sleep, 20
}
return



; =======================================
; Change character group
; =======================================


Numpad4::
  ChangeParty("left")
return

Numpad6::
  ChangeParty("right")
return


ChangeParty(Direction) {
  Send, {Esc}
  Sleep, 800
  MouseClick, left, 348, 414 ; Party setup
  Sleep, 3000
  if (Direction = "left") {
    MouseClick, left, 75, 539
  } else {
    MouseClick, left, 1845, 539
  }
  Sleep, 100

  MouseClick, left, 1700, 1000 ; press Deploy button
  Sleep, 300
  Send, {Esc} ; first escape cancels the notification
  Sleep, 400
  Send, {Esc}
  return
}



; =======================================
; Expeditions
; =======================================

; Recieve all the rewards
Numpad2::
    ReceiveReward(WhisperingWoodsExpedition)
    ReceiveReward(DadaupaGorgeExpedition)
    ReceiveReward(YaoguangShoalExpedition)
    ReceiveReward(StormterrorLairExpedition)
    ReceiveReward(DihuaMarshExpedition)
return

; Send everyone to the expedition
Numpad3::
    Duration := Duration20H
    SendOnExpedition(WhisperingWoodsExpedition, "amber", Duration)
    SendOnExpedition(DadaupaGorgeExpedition, "kaeya", Duration)
    SendOnExpedition(YaoguangShoalExpedition, "lisa", Duration)
    SendOnExpedition(StormterrorLairExpedition, "noelle", Duration)
    SendOnExpedition(DihuaMarshExpedition, "xiangling", Duration)
return

SelectExpedition(Expedition) {
    ; Click on the world
    WorldY := 160 + (Expedition["MapNumber"] * 72) ; initial position + offset between lines
    MouseClick, left, 200, WorldY
    Sleep 500

    ; Click on the expedition
    MouseClick, left, Expedition["X"], Expedition["Y"]
    Sleep 200
}

ClickOnBottomRightButton() {
    MouseClick, left, 1730, 1000
}

SelectDuration(Duration) {
    MouseClick, left, Duration["X"], Duration["Y"]
    Sleep 100
}

SendOnExpedition(Expedition, CharacterName, Duration) {
    SelectExpedition(Expedition)

    SelectDuration(Duration)

    ; Click on "Select Character"
    ClickOnBottomRightButton()
    Sleep, 1500

    ; Find and select the character
    FindAndSelectCharacter(CharacterName)
    Sleep, 300
}



; Find character at character list. The caracter must not be highlighted.
; Returns array [x, y] or 0 if it's not found.
FindCharacterOnScreen(CharacterName) {
    ImageSearch, FoundX, FoundY, 40, 100, 200, 1050, *30 characters\%CharacterName%.png
    if (ErrorLevel = 2) {
        ErrorMessage = Failed to search character %CharacterName%
        throw Exception(ErrorMessage)
    } else if (ErrorLevel = 1) {
        return
    } else {
        return [FoundX, FoundY]
    }
}

; Scroll down the passed number of characters
ScrollDownCharacterList(CharacterAmount) {
    MouseMove, 950, 540

    ScrollAmount := CharacterAmount * 7
    Loop %ScrollAmount% {
        Send, {WheelDown}
        ;Sleep 17 TODO
    }
}

FindAndSelectCharacter(CharacterName) {
    loop 5 {
        CharacterXY := FindCharacterOnScreen(CharacterName)
        if (CharacterXY) {
            ; character was found, select it
            MouseClick, left, CharacterXY[1], CharacterXY[2]
            Sleep 100
            break
        } else {
            ; character was not found, scrolling down if we can
            PixelGetColor, ScrollBarColor, 935, 1013, RGB
            if (ScrollBarColor = "ECE5D8") {
                break
            }
            ScrollDownCharacterList(7)
            Sleep 300
        }
    }
}

ReceiveReward(Expedition) {
    SelectExpedition(Expedition)

    loop 2 {
        ; receive reward and skip reward menu
        ClickOnBottomRightButton()
        Sleep 200
    }
}



; =======================================
; Klee machine gun
; =======================================

*XButton2::
    while(GetKeyState("XButton2", "P")) {
        Click
        Sleep, 35
        Send, {Space}
        Sleep, 550
    }
return



; =======================================
; Debug
; =======================================

NumpadDot::
    KeyState := GetKeyState("XButton2")
    MsgBox, % KeyState

    ;MsgBox, waiting
    ;WinWaitActive, ahk_exe GenshinImpact.exe
    ;MsgBox, active

    ;Active := WinActive("ahk_exe GenshinImpact.exe")
    ;MsgBox, %Active%

    ;ToolTip, hey
    ;Sleep 1000
    ;ToolTip

    ;SelectDuration(Coordinates4H)
    ;SendOnExpedition(DadaupaGorgeExpedition, "kaeya", Duration4H)

    ;ReceiveReward(DihuaMarshExpedition)
    ;FindAndSelectCharacter("barbara")

    ;FindAndSelectCharacter("ningguang")
    ;PixelGetColor, ScrollBarColor, 935, 1013, RGB
    ;MsgBox, % ScrollBarColor

    ;ListVars
    ;MsgBox, % WorldY
return
