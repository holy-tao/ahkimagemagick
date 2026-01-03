#Requires AutoHotkey v2.0

#Include ../Core/MagickEnum.ahk

/**
 * Enumeration of valid noise types
 * @see https://github.com/ImageMagick/ImageMagick/blob/9b94be4627c63bf810bb94503473d3b68353c35a/MagickCore/visual-effects.h#L27-L37
 */
class NoiseType extends MagickEnum {
    static Undefined              => 0
    static Uniform                => 1
    static Gaussian               => 2
    static MultiplicativeGaussian => 3
    static Impulse                => 4
    static Laplacian              => 5
    static Poisson                => 6
    static Random                 => 7
}
