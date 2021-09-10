#NoEnv
#SingleInstance Force
#MaxHotkeysPerInterval 100
#InstallKeybdHook
#InstallMouseHook
#Include lib.ahk

SendMode Event
SetWorkingDir %A_ScriptDir%
SetKeyDelay 0
SetMouseDelay 0

; Rerun script with administrator rights if required.
if (!A_IsAdmin) {
    try {
        Run *RunAs "%A_ScriptFullPath%"
    } catch e {
        MsgBox, Failed to run script with administrator rights
        ExitApp
    }
}

; =======================================
; Global variables
; =======================================

ContextualBindingsEnabled := false

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
JueyunKarstExpedition := { MapNumber: 1, X: 559, Y: 561 }
JinrenIslandExpedition := { MapNumber: 2, X: 1097, Y: 274 }
TarasunaExpedition := { MapNumber: 2, X: 828, Y: 828 }

; Expetitions (food)
WindriseExpedition := { MapNumber: 0, X: 1111, Y: 455 }
GuiliPlainsExpedition := { MapNumber: 1, X: 800, Y: 550 }



; =======================================
; Script initialization
; =======================================

SetTimer, SuspendOnGameInactive, -1
SetTimer, ExitOnGameClose, 5000
SetTimer, ConfigureContextualBindings, 250
SetTimer, Unfreeze, 250 ; if interval is less than 250ms, timer becomes buggy, especially during a reload



; =======================================
; Technical stuff
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

SuspendOnGameInactive() {
    global GameProcessName

    Suspend ; run suspended
    loop {
        WinWaitActive, %GameProcessName%
        Suspend, Off

        WinWaitNotActive, %GameProcessName%
        Suspend, On
    }
}

ExitOnGameClose() {
    global GameProcessName

    ; WinWaitActive is blocked forever when WinWaitClose is waiting (looks like a bug), it can't be used here
    if (!WinExist(GameProcessName)) {
        ExitApp
    }
}



; =======================================
; Enable/disable contextual bindings
; =======================================

ConfigureContextualBindings() {
    global ContextualBindingsEnabled

    PixelGetColor, Color, 808, 1010, "RGB" ; left pixel of the hp bar
    HpBarFound := (Color = "0x96D722") || (Color = "0xFF5A5A") || (Color = "0xFFCC32") ; green or red or orange

    PixelGetColor, ThirdActionItemColor, 1626, 1029, "RGB"
    FishingActive := ThirdActionItemColor = "0xFFE92C" ; is 3rd action icon bound to LMB

    if (!ContextualBindingsEnabled && HpBarFound && !FishingActive) {
        ; enable bindings
        Hotkey, *~LButton, NormalAutoAttack, On
        Hotkey, *RButton, StrongAttack, On
        Hotkey, ~$*f, Loot, On
        ContextualBindingsEnabled := true
    } else if (ContextualBindingsEnabled && (!HpBarFound || FishingActive)) {
        ; disable bindings
        Hotkey, *~LButton, NormalAutoAttack, Off
        Hotkey, *RButton, StrongAttack, Off
        Hotkey, ~$*f, Loot, Off
        ContextualBindingsEnabled := false
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
    Sleep, 250
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
; Hold F to loot
; =======================================

Loot() {
    while(GetKeyState("f", "P")) {
        Send, {f}
        Sleep, 20
        Send, {WheelDown}
        Sleep, 20
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
    Send, {l}
    WaitFullScreenMenu(5000)
    if (Direction = "left") {
        MouseClick, left, 75, 539
    } else {
        MouseClick, left, 1845, 539
    }

    WaitDeployButtonActive(1000)
    MouseClick, left, 1700, 1000 ; press Deploy button

    WaitPixelColor("0xFFFFFF", 836, 491, 2000) ; wait for "Party deployed" notification
    Send, {Esc}
}



; =======================================
; Expeditions
; =======================================

; Recieve all the rewards
Numpad1::
    ReceiveReward(StormterrorLairExpedition, 1000)
    ReceiveReward(DihuaMarshExpedition)
    ReceiveReward(JueyunKarstExpedition)
    ReceiveReward(JinrenIslandExpedition)
    ReceiveReward(TarasunaExpedition)
return

; Send everyone to the expedition
Numpad2::
    Duration := Duration20H
    SendOnExpedition(StormterrorLairExpedition, 3, Duration)
    SendOnExpedition(DihuaMarshExpedition, 3, Duration)
    SendOnExpedition(JueyunKarstExpedition, 4, Duration)
    SendOnExpedition(JinrenIslandExpedition, 5, Duration)
    SendOnExpedition(TarasunaExpedition, 6, Duration)
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

SelectDuration(Duration) {
    MouseClick, left, Duration["X"], Duration["Y"]
    Sleep, 100
}

; Send character to an expedition.
; CharacterNumberInList - starts from 1.
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

ReceiveReward(Expedition, ReceiveRewardLag := 0) {
    SelectExpedition(Expedition)

    ; receive reward
    ClickOnBottomRightButton()
    Sleep, 200
    Sleep, ReceiveRewardLag

    ;skip reward menu
    ClickOnBottomRightButton()
    Sleep, 200
}


; =======================================
; Lock artifact
; =======================================

Numpad8::
    MouseGetPos, X, Y
    MouseClick, left, 1738, 440
    Sleep, 50
    MouseClick, left, X, Y
return



; =======================================
; Select maximum stacks and craft ores
; =======================================

Numpad9::
    MouseClick, left, 1467, 669 ; max stacks
    Sleep, 50
    ClickOnBottomRightButton()
return



; =======================================
; Go to the Serenitea Pot
; =======================================

Numpad5::
    OpenInventory()

    MouseClick, left, 1050, 50 ; gadgets tab
    WaitPixelColor("0xD3BC8E", 1055, 92, 1000) ; wait for tab to be active

    MouseClick, left, 270, 180 ; select first gadget
    ClickOnBottomRightButton()

    WaitDialogMenu()
    Send, {f}
return



; =======================================
; Relogin
; =======================================

Numpad3::
    OpenMenu()

    MouseClick, left, 49, 1022 ; logout button
    WaitPixelColor("0x313131", 1017, 757, 5000) ; wait logout menu

    MouseClick, left, 1197, 759 ; confirm
    WaitPixelColor("0x222222", 1823, 794, 5000) ; wait for settings icon

    MouseClick, left, 500, 500
    Sleep, 500
    WaitPixelColor("0xFEFEFE", 1808, 793, 15000) ; wait for "click to begin"

    MouseClick, left, 600, 500
return



; =======================================
; Hold 1-4 to switch character
; =======================================

~*1::
    while(GetKeyState("1", "P")) {
        Send, {1}
        Sleep, 100
    }
return

~*2::
    while(GetKeyState("2", "P")) {
        Send, {2}
        Sleep, 100
    }
return

~*3::
    while(GetKeyState("3", "P")) {
        Send, {3}
        Sleep, 100
    }
return

~*4::
    while(GetKeyState("4", "P")) {
        Send, {4}
        Sleep, 100
    }
return


; =======================================
; Klee animation cancelling
; =======================================

*XButton1::
    while(GetKeyState("XButton1", "P")) {
        Click
        Sleep, 35
        Send, {Space}
        Sleep, 550
    }
return


; =======================================
; Wait for the next night
; =======================================

Numpad7::
    OpenMenu()

    MouseClick, left, 45, 715 ; clock icon
    WaitPixelColor("0xECE5D8", 1870, 50, 5000) ; wait for clock menu

    ClockCenterX := 1440
    ClockCenterY := 501
    Offset := 30

    ClickOnClock(ClockCenterX, ClockCenterY + Offset) ; 00:00
    ClickOnClock(ClockCenterX - Offset, ClockCenterY) ; 06:00
    ClickOnClock(ClockCenterX, ClockCenterY - Offset) ; 12:00
    ClickOnClock(ClockCenterX + Offset, ClockCenterY) ; 18:00

    MouseClick, left, 1440, 1000 ; "Confirm" button

    Sleep, 100
    WaitPixelColor("0xECE5D8", 1870, 50, 30000) ; wait for clock menu

    Send, {Esc}
    WaitMenu()

    Send, {Esc}
return


ClickOnClock(X, Y) {
    SendEvent, {Click %X% %Y% Down}
    Sleep, 50
    SendEvent, {Click %X% %Y% Up}
    Sleep, 100
}



; =======================================
; Auto unfreeze
; =======================================

Unfreeze() {
    while (IsFrozen()) {
        Send, {Space}
        Sleep, 68
    }
}


; =======================================
; Receive all BP exp and rewards
; =======================================

NumpadDot::
    ;global RedNotificationColor

    ;PixelGetColor, Color, 1515, 23, "RGB" ; top right BP notification icon
    ;if (Color != RedNotificationColor) {
    ;    MsgBox, "No BP exp or reward"
    ;    return
    ;}

    Send, {f4}
    WaitFullScreenMenu()

    ReceiveBpExp()
    ReceiveBpRewards()

    Send, {Esc}
return

ReceiveBpExp() {
    global RedNotificationColor

    ; Check for available BP experience and receive if any
    PixelGetColor, Color, 993, 20, "RGB"
    if (Color != RedNotificationColor) {
        return ; no exp
    }

    MouseClick, left, 993, 20 ; to exp tab
    Sleep, 100

    ClickOnBottomRightButton() ; "Claim all"
    Sleep, 200

    if (!IsFullScreenMenuOpen()) {
        ; level up, need to close popup
        Send, {Esc}
        WaitFullScreenMenu()
    }
}

ReceiveBpRewards() {
    global RedNotificationColor

    ; Check for available BP experience and receive if any
    PixelGetColor, Color, 899, 20, "RGB"
    if (Color != RedNotificationColor) {
        return ; no rewards
    }

    MouseClick, left, 899, 20 ; to rewards tab
    Sleep, 100

    ClickOnBottomRightButton() ; "Claim all"
    Sleep, 200
    Send, {Esc} ; close popup with received rewards
    WaitFullScreenMenu()
}



; =======================================
; Teleport in one click
; =======================================

~MButton::
    if (!IsFullScreenMenuOpen()) {
        return ; not in the world map menu
    }

    MapClick()
    try {
        ; wait for a little white arrow or teleport button
        WaitPixelsRegions([ { X1: 1255, Y1: 484, X2: 1258, Y2: 1080, Color: "0xECE5D8" }, { X1: 1478, Y1: 1012, X2: 1478, Y2: 1013, Color: "0xFFCC33" } ])
    } catch e {
        return
    }

    PixelGetColor, TpColor, 1478, 1012, "RGB"
    if (TpColor = "0xFFCC33") {
        ; selected point has only 1 selectable option and it's available for teleport
        ClickOnBottomRightButton()
        Sleep, 50
        MoveCursorToCenter()
    } else {
        ; selected point has multiple selectable options or selected point is not available for teleport
        TeleportablePointColors := [ "0x2D91D9" ; Teleport waypoint
            , "0x99ECF5"                        ; Statue of The Seven
            , "0x05EDF6"                        ; Domain
            , "0x00FFFF" ]                      ; One-time dungeon

        for Index, TeleportablePointColor in TeleportablePointColors {
            Teleported := FindIconAndTeleport(TeleportablePointColor)
            if (Teleported) {
                MoveCursorToCenter()
                break
            }
        }
    }
return

FindIconAndTeleport(IconPixelColor) {
    PixelSearch, FoundX, FoundY, 1298, 460, 1299, 1080, IconPixelColor, 0, "Fast RGB"
    if (ErrorLevel) {
        ; icon wasn't found
        return false
    }

    MouseClick, left, FoundX, FoundY
    WaitPixelColor("0xFFCB33", 1480, 1011, 500) ; "Teleport" button

    ClickOnBottomRightButton()
    Sleep, 50
    return true
}
