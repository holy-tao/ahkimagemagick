#Requires AutoHotkey v2.0

#Include ../Core/MagickEnum.ahk

/**
 * Enumeration of image resolution type values
 * @see https://github.com/ImageMagick/ImageMagick/blob/408a18373ce59ab3a06c55b91d9dfc5397b7e1ca/MagickCore/image.h#L69-L74
 */
class ResolutionType extends MagickEnum {
    static Undefined            => 0
    static PixelsPerInch        => 1
    static PixelsPerCentimeter  => 2
}