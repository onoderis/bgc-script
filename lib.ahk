OpenMenu() {
    Send, {Esc}
    WaitMenu()
}

WaitMenu() {
    WaitPixelColor("ECE5D8", 729, 63, 2000) ; wait for menu
}

OpenInventory() {
    Send, {b}
    WaitFullScreenMenu(2000)
}

ClickOnBottomRightButton() {
    MouseClick, left, 1730, 1000
}

WaitFullScreenMenu(Timeout) {
    WaitPixelColor("ECE5D8", 1859, 47, Timeout) ; wait for close button on the top right
}

WaitDeployButtonActive(Timeout) {
    WaitPixelColor("313131", 1557, 1005, Timeout) ; wait for close button on the top right
}

WaitDialogMenu() {
    WaitPixelColor("656D76", 1180, 537, 2000) ; wait for "..." icon in the center of the screen
}

; Wait for pixel to be the specified color or throw exception after the specified Timeout.
;
; Color - hex string in RGB format, for example "A0B357".
; Timeout - timeout in milliseconds.
WaitPixelColor(Color, X, Y, Timeout) {
    FormattedColor := "0x" . Color

    StartTime := A_TickCount
    loop {
        PixelGetColor, CurrentColor, X, Y, "RGB"
        if (CurrentColor = FormattedColor) {
            return
        } else if (ErrorLevel) {
            throw "Error level " . ErrorLevel
        } else if (A_TickCount - StartTime >= Timeout) {
            throw "Timeout " . Timeout . " ms"
        }
    }
}
