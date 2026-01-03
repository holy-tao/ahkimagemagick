#Requires AutoHotkey v2.0

#Include ../Core/MagickEnum.ahk

/**
 * Enum of all possible ImageMagick exception types and utilities for them
 * @See https://github.com/ImageMagick/ImageMagick/blob/408a18373ce59ab3a06c55b91d9dfc5397b7e1ca/MagickCore/exception.h#L33C23-L99C7
 */
class MagickExceptionType extends MagickEnum {
    static Undefined => 0
    static WarningException => 300
    static ResourceLimitWarning => 300
    static TypeWarning => 305
    static OptionWarning => 310
    static DelegateWarning => 315
    static MissingDelegateWarning => 320
    static CorruptImageWarning => 325
    static FileOpenWarning => 330
    static BlobWarning => 335
    static StreamWarning => 340
    static CacheWarning => 345
    static CoderWarning => 350
    static FilterWarning => 352
    static ModuleWarning => 355
    static DrawWarning => 360
    static ImageWarning => 365
    static WandWarning => 370
    static RandomWarning => 375
    static XServerWarning => 380
    static MonitorWarning => 385
    static RegistryWarning => 390
    static ConfigureWarning => 395
    static PolicyWarning => 399
    static ErrorException => 400
    static ResourceLimitError => 400
    static TypeError => 405
    static OptionError => 410
    static DelegateError => 415
    static MissingDelegateError => 420
    static CorruptImageError => 425
    static FileOpenError => 430
    static BlobError => 435
    static StreamError => 440
    static CacheError => 445
    static CoderError => 450
    static FilterError => 452
    static ModuleError => 455
    static DrawError => 460
    static ImageError => 465
    static WandError => 470
    static RandomError => 475
    static XServerError => 480
    static MonitorError => 485
    static RegistryError => 490
    static ConfigureError => 495
    static PolicyError => 499
    static FatalErrorException => 700
    static ResourceLimitFatalError => 700
    static TypeFatalError => 705
    static OptionFatalError => 710
    static DelegateFatalError => 715
    static MissingDelegateFatalError => 720
    static CorruptImageFatalError => 725
    static FileOpenFatalError => 730
    static BlobFatalError => 735
    static StreamFatalError => 740
    static CacheFatalError => 745
    static CoderFatalError => 750
    static FilterFatalError => 752
    static ModuleFatalError => 755
    static DrawFatalError => 760
    static ImageFatalError => 765
    static WandFatalError => 770
    static RandomFatalError => 775
    static XServerFatalError => 780
    static MonitorFatalError => 785
    static RegistryFatalError => 790
    static ConfigureFatalError => 795
    static PolicyFatalError => 799

    static Warn_Min => 300
    static Warn_Max => 400
    static Error_Min => 400
    static Error_Max => 700
    static Fatal_Min => 700

    /**
     * Gets the severity for a MagickException
     * @param {Integer} code The code to get the severity for 
     * @returns {"Success" | "Warning" | "Error" | "Fatal"} The severity of the code
     */
    static GetSeverity(code) {
        switch {
            case code == 0: return "Success"
            case code < MagickExceptionType.Warn_Max: return "Warning"
            case code < MagickExceptionType.Error_Max: return "Error"
            default: return "Fatal"
        }
    }
    
    /**
     * Gets a generic long-form message for a MagickException error code - for use when ImageMagick does not provide
     * a more detailed error message, which is rare but can happen if something external to ImageMagick goes down hard
     * @see https://imagemagick.org/script/exception.php#gsc.tab=0
     * 
     * @param {Integer} code The code to get the message for for 
     * @returns {String} the error message
     */
    static GetDefaultErrorMessage(code) {
        if(code == 0)
            return "The command or algorithm completed successfully without complaint"

        switch(Mod(code, 100)){
            case 00: return "A program resource is exhausted (e.g. not enough memory)"
            case 05: return "A font is unavailable; a substitution may have occurred"
            case 10: return "A command-line option was malformed"
            case 15: return "An ImageMagick delegate failed to complete"
            case 20: return "The image type can not be read or written because the appropriate delegate is missing"
            case 25: return "The image file may be corrupt"
            case 30: return "The image file could not be opened for reading or writing"
            case 35: return "A binary large object could not be allocated, read, or written"
            case 40: return "There was a problem reading or writing from a stream"
            case 45: return "Pixels could not be read or written to the pixel cache"
            case 50: return "There was a problem with an image coder"
            case 55: return "There was a problem with an image module"
            case 60: return "A drawing operation failed"
            case 65: return "The operation could not complete due to an incompatible image"
            case 70: return "There was a problem specific to the MagickWand API"
            case 75: return "There is a problem generating a true or pseudo-random number"
            case 80: return "An X resource is unavailable"
            case 85: return "There was a problem activating the progress monitor"
            case 90: return "There was a problem getting or setting the registry"
            case 95: return "There was a problem getting a configuration file"
            case 99: return "A policy denies access to a delegate, coder, filter, path, or resource"
            default: return "An unspecified error occurred"
        }
    }
}