#Requires AutoHotkey v2.0

#Include ../Core/MagickEnum.ahk

class ImageType extends MagickEnum {
    static Undefined            => 0
    static Bilevel              => 1
    static Grayscale            => 2
    static GrayscaleAlpha       => 3
    static Palette              => 4
    static PaletteAlpha         => 5
    static TrueColor            => 6
    static TrueColorAlpha       => 7
    static ColorSeparation      => 8
    static ColorSeparationAlpha => 9
    static Optimize             => 10
    static PaletteBilevelAlpha  => 11
}