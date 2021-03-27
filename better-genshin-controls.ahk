#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#MaxHotkeysPerInterval 100
#InstallKeybdHook
#InstallMouseHook
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; =======================================
; Global variables
; =======================================

; Global state
BindingsEnabled = 0
AutoRun = 0

; Expedition duration coordinates
Duration4H := { X: 1500, Y: 700 }
Duration20H := { X: 1800, Y: 700 }

; Expetitions (crystals)
WhisperingWoodsExpedition := { MapNumber: 0, X: 1050, Y: 330 }
DadaupaGorgeExpedition := { MapNumber: 0, X: 1170, Y: 660 }
YaoguangShoalExpedition := { MapNumber: 1, X: 950, Y: 450 }

; Expetitions (mora)
StormterrorLairExpedition := { MapNumber: 0, X: 550, Y: 400 }
DihuaMarshExpedition := { MapNumber: 1, X: 728, Y: 332 }

; Expetitions (food)
WindriseExpedition := { MapNumber: 0, X: 1111, Y: 455 }
GuiliPlainsExpedition := { MapNumber: 1, X: 800, Y: 550 }

; =======================================
; Script initialization
; =======================================

SetTimer, PauseLoop
SetTimer, ConfigureBindings, 200


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

PauseLoop() {
    Suspend ; run suspended
    loop {
        WinWaitActive, ahk_exe GenshinImpact.exe
        Suspend, Off
        WinWaitNotActive, ahk_exe GenshinImpact.exe
        Suspend, On
    }
}



; =======================================
; Enable/disable contextual bindings
; =======================================

ConfigureBindings() {
    global BindingsEnabled

    PixelGetColor, Color, 807, 1010, RGB ; left pixel of the hp bar
    HpBarFound := (Color = "0x8DC921") || (Color = "0xEF5555") ; green or red

    Toggled := 0
    if (HpBarFound && !BindingsEnabled) {
        ; enable bindings
        Hotkey, *~LButton, NormalAutoAttack, On
        Hotkey, *RButton, StrongAttack, On
        Hotkey, ~$*f, SpamF, On
        Toggled := 1
    } else if (!HpBarFound && BindingsEnabled) {
        ; disable bindings
        Hotkey, *~LButton, NormalAutoAttack, Off
        Hotkey, *RButton, StrongAttack, Off
        Hotkey, ~$*f, SpamF, Off,
        Toggled := 1
    }

    if (Toggled) {
        BindingsEnabled := !BindingsEnabled
    }
}



; =======================================
; Auto attack
; =======================================

NormalAutoAttack() {
    while(GetKeyState("LButton", "P")) {
        SpamLeftClick()
    }
}

SpamLeftClick() {
    MouseClick left
    Sleep, 150
}

StrongAttack() {
    Click, down
    KeyWait, RButton
    TimeSinceKeyPressed := A_TimeSinceThisHotkey
    if (TimeSinceKeyPressed < 350) {
        ; hold LMB minimum for 350ms
        Sleep, % 350 - TimeSinceKeyPressed
    }
    Click, up
}



; =======================================
; Pick up on press
; =======================================

SpamF() {
    while(GetKeyState("f", "P")) {
        Send, {f}
        Sleep, 40
    }
}



; =======================================
; Spam left click
; =======================================

XButton2::
    while(GetKeyState("XButton2" ,"P")) {
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
Numpad1::
    ReceiveReward(WhisperingWoodsExpedition)
    ReceiveReward(DadaupaGorgeExpedition)
    ReceiveReward(YaoguangShoalExpedition)
    ReceiveReward(StormterrorLairExpedition)
    ReceiveReward(DihuaMarshExpedition)
return

; Send everyone to the expedition
Numpad2::
    Duration := Duration20H
    SendOnExpedition(WhisperingWoodsExpedition, 4, Duration)
    SendOnExpedition(DadaupaGorgeExpedition, 5, Duration)
    SendOnExpedition(YaoguangShoalExpedition, 6, Duration)
    SendOnExpedition(StormterrorLairExpedition, 7, Duration)
    SendOnExpedition(DihuaMarshExpedition, 8, Duration)
return

SelectExpedition(Expedition) {
    ; Click on the world
    WorldY := 160 + (Expedition["MapNumber"] * 72) ; initial position + offset between lines
    MouseClick, left, 200, WorldY
    Sleep, 500

    ; Click on the expedition
    MouseClick, left, Expedition["X"], Expedition["Y"]
    Sleep, 200
}

ClickOnBottomRightButton() {
    MouseClick, left, 1730, 1000
}

SelectDuration(Duration) {
    MouseClick, left, Duration["X"], Duration["Y"]
    Sleep, 100
}

SendOnExpedition(Expedition, CharacterNumberInList, Duration) {
    SelectExpedition(Expedition)

    SelectDuration(Duration)

    ; Click on "Select Character"
    ClickOnBottomRightButton()
    Sleep, 1500

    ; Find and select the character
    FindAndSelectCharacter(CharacterNumberInList)
    Sleep, 300
}

FindAndSelectCharacter(CharacterNumberInList) {
    FirstCharacterX := 100
    FirstCharacterY := 150
    SpacingBetweenCharacters := 125

    if (CharacterNumberInList <= 7) {
        MouseClick, left, FirstCharacterX, FirstCharacterY + (SpacingBetweenCharacters * (CharacterNumberInList - 1))
    } else {
        ScrollDownCharacterList(CharacterNumberInList - 7.5)
        MouseClick, left, FirstCharacterX, FirstCharacterY + (SpacingBetweenCharacters * 7)
    }
}

; Scroll down the passed number of characters
ScrollDownCharacterList(CharacterAmount) {
    MouseMove, 950, 540

    ScrollAmount := CharacterAmount * 7
    Loop %ScrollAmount% {
        Send, {WheelDown}
        Sleep, 10
    }
}

ReceiveReward(Expedition) {
    SelectExpedition(Expedition)

    loop 2 {
        ; receive reward and skip reward menu
        ClickOnBottomRightButton()
        Sleep, 200
    }
}



; =======================================
; Debug
; =======================================

*XButton1::
    if (AutoRun) {
        ControlSend ,, {w Down}, ahk_exe GenshinImpact.exe
    } else {
        ControlSend ,, {w Up}, ahk_exe GenshinImpact.exe
    }
    AutoRun := !AutoRun
return

NumpadDot::
    ListVars
return
