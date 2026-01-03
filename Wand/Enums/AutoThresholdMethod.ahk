#Requires AutoHotkey v2.0

#Include ../Core/MagickEnum.ahk

/**
 * Auto-threshold method for `MagickWand.AutoThresholdImage`
 * @see https://github.com/ImageMagick/ImageMagick/blob/9b94be4627c63bf810bb94503473d3b68353c35a/MagickCore/threshold.h#L25-L31
 */
class AutoThresholdMethod extends MagickEnum {
    static Undefined => 0
    static Kapur     => 1
    static OTSU      => 2
    static Triangle  => 3
}