OpenMenu() {
    Send, {Esc}
    WaitPixelColor("ECE5D8", 729, 63, 2000) ; wait for menu
}

ClickOnBottomRightButton() {
    MouseClick, left, 1730, 1000
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
