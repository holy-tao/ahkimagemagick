#Requires AutoHotkey v2.0

#Include ../Core/MagickEnum.ahk

/**
 * Enumeration of ImageMagick interlace types
 * @see https://github.com/ImageMagick/ImageMagick/blob/408a18373ce59ab3a06c55b91d9dfc5397b7e1ca/MagickCore/image.h#L44-L54
 */
class InterlaceType extends MagickEnum {
    static Undefined    => 0
    static None         => 1
    static Line         => 2
    static Plane        => 3
    static Partition    => 4
    static GIF          => 5
    static JPEG         => 6
    static PNG          => 7
}