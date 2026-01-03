#Requires AutoHotkey v2.0

/**
 * Contains hue, stauration, and lightness information
 */
class HSL {
    __New(hue, saturation, lightness) {
        this.hue := hue
        this.saturation := saturation
        this.lightness := lightness
    }
}