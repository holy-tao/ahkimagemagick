#Requires AutoHotkey v2.0

#Include ../Core/MagickEnum.ahk

/**
 * Enumeration of orientation types
 * @see https://github.com/ImageMagick/ImageMagick/blob/408a18373ce59ab3a06c55b91d9dfc5397b7e1ca/MagickCore/image.h#L56-L67
 */
class OrientationType extends MagickEnum {
    static Undefined    => 0
    static TopLeft      => 1
    static TopRight     => 2
    static BottomRight  => 3
    static BottomLeft   => 4
    static LeftTop      => 5
    static RightTop     => 6
    static RightBottom  => 7
    static LeftBottom   => 8
}