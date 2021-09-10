; Static variables
GameProcessName := "ahk_exe GenshinImpact.exe"

RedNotificationColor := "0xE6455F"
LightMenuColor := "0xECE5D8"


OpenMenu() {
    Send, {Esc}
    WaitMenu()
}

WaitMenu() {
    global LightMenuColor
    WaitPixelColor(LightMenuColor, 729, 63, 2000) ; wait for menu
}

OpenInventory() {
    Send, {b}
    WaitFullScreenMenu(2000)
}

ClickOnBottomRightButton() {
    MouseClick, left, 1730, 1000
}

WaitFullScreenMenu(Timeout := 3000) {
    global LightMenuColor
    WaitPixelColor(LightMenuColor, 1859, 47, Timeout) ; wait for close button on the top right
}

IsFullScreenMenuOpen() {
    global LightMenuColor
    PixelGetColor, Color, 1859, 47, "RGB"
    return Color = LightMenuColor
}

WaitDeployButtonActive(Timeout) {
    WaitPixelColor("0x313131", 1557, 1005, Timeout) ; wait for close button on the top right
}

WaitDialogMenu() {
    WaitPixelColor("0x656D76", 1180, 537, 2000) ; wait for "..." icon in the center of the screen
}

; Check is a character frozen
IsFrozen() {
    PixelGetColor, SpaceTextColor, 1417, 596, "RGB"

    if (SpaceTextColor != "0x333333") {
        return false
    }

    PixelGetColor, SpaceButtonColor, 1417, 585, "RGB"

    return SpaceButtonColor = "0xFFFFFF"
}

; Special click function for the world map menu.
;
; For some reasons MouseClick(and Click) doesn't work consistently: it doesn't works if a click goes to an empty place,
; but works fine if a click goes to an interactable point.
MapClick() {
    Send, {LButton down}
    Sleep, 50
    Send, {LButton up}
}

MoveCursorToCenter() {
    MouseMove, % A_ScreenWidth / 2, % A_ScreenHeight / 2
}

; Wait for pixel to be the specified color or throw exception after the specified Timeout.
;
; Color - hex string in RGB format, for example "0xA0B357".
; Timeout - timeout in milliseconds.
WaitPixelColor(Color, X, Y, Timeout) {
    StartTime := A_TickCount
    loop {
        PixelGetColor, CurrentColor, X, Y, "RGB"
        if (CurrentColor = Color) {
            return
        } else if (ErrorLevel) {
            throw "Error level " . ErrorLevel
        } else if (A_TickCount - StartTime >= Timeout) {
            throw "Timeout " . Timeout . " ms"
        }
    }
}

; Wait to at least one pixel of the specified color to appear in the corresponding region.
;
; Regions - array of objects that must have the following fields:
;     X1, Y1, X2, Y2 - region coordinates;
;     Color - pixel color to wait.
; Returns found region or throws exception
WaitPixelsRegions(Regions, Timeout := 1000) {
    StartTime := A_TickCount
    loop {
        for Index, Region in Regions {
            X1 := Region["X1"]
            X2 := Region["X2"]
            Y1 := Region["Y1"]
            Y2 := Region["Y2"]
            Color := Region["Color"]

            PixelSearch, FoundX, FoundY, X1, Y1, X2, Y2, Color, 0, "Fast RGB"
            if (!ErrorLevel) {
                return Region
            }
        }

        if (A_TickCount - StartTime >= Timeout) {
            throw "Timeout " . Timeout . " ms"
        }
    }
}
