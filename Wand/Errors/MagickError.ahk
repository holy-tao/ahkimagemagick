#Requires AutoHotkey v2.0

#Include MagickExceptionType.ahk

/**
 * Thrown when an ImageMagick call raises an [exception](https://imagemagick.org/script/exception.php#gsc.tab=0).
 */
class MagickError extends Error {

    /**
     * The exception code that caused this error
     * @type {Integer}
     */
    Number := unset

    /**
     * The severity of the error
     * @type {"Success" | "Warning" | "Error" | "Fatal"}
     */
    Severity := unset

    /**
     * The name of the exception type
     * @type {String}
     */
    ExceptionType := unset

    /**
     * Initializes a new `MagickException` object
     * @param {Integer} code The {@link MagickExceptionType error code} 
     * @param {String} description Description for the error message. If unset, a default message is used based on
     *          the error code
     * @param {Any} what Optionally, sets the {@link https://www.autohotkey.com/docs/v2/lib/Error.htm#What `what`} 
     *          property of the underlying Error. If unset, defaults to A_ThisFunc
     * @param {Any} extra Optionally, sets the {@link https://www.autohotkey.com/docs/v2/lib/Error.htm#Extra `extra`}
     *          property of the underlying Error
     */
    static Call(code, description?, what := A_ThisFunc, extra := "") {
        description := description ?? MagickExceptionType.GetDefaultErrorMessage(code)
        msg := Format("({1}) {2}: {3}", code, name := MagickExceptionType.GetName(code), description)
        err := super.Call(msg, what, extra?)

        err.Number := code
        err.Severity := MagickExceptionType.GetSeverity(code)
        err.ExceptionType := name

        return err
    }
}