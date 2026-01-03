#Requires AutoHotkey v2.0

#Include .\Color\HSL.ahk
#Include .\Errors\MagickError.ahk
#Include .\Errors\MagickExceptionType.ahk

#DllLoad CORE_RL_MagickWand_.dll

/**
 * PixelWands describe colors and are used in MagickWand operations which require color information
 */
class PixelWand {
    ;@region Ctor & Initialization

    ptr := 0
    ThrowForWarnings := false

    /**
     * Creates a new pixel wand or wraps an existing pointer
     * @param {Integer | String} ptrOrColor A pointer to the pixel wand, or 0 or a color string ("blue", "#0000ff")
     *          to create a new pixel wand with that color
     */
    __New(ptrOrColor := 0) {
        this.ThrowForWarnings := false
        if(ptrOrColor is Integer) {
            this.ptr := ptrOrColor
        }

        this.ptr := DllCall("CORE_RL_MagickWand_\NewPixelWand")
        if(ptrOrColor is String)
            this.SetColor(ptrOrColor)
    }

    /**
     * Makes an exact copy of the specified wand.
     * @returns {PixelWand} the new PixelWand
     */
    Clone() {
        wandPtr := DllCall("CORE_RL_MagickWand_\ClonePixelWand", "ptr", this, "ptr")
        this.ThrowForMagickException()
        return PixelWand(wandPtr)
    }

    __Delete() {
        DllCall("CORE_RL_MagickWand_\DestroyPixelWand", "ptr", this, "ptr")
    }
    ;@endregion

    ;@region Utilities

    /**
     * Sets the color of the pixel wand with a string (e.g. "blue", "#0000ff", "rgb(0,0,255)", "cmyk(100,100,100,10)", 
     * etc.).
     * @see https://imagemagick.org/api/pixel-wand.php#PixelSetColor
     * 
     * @param {String} color The color string 
     */
    SetColor(color) {
        DllCall("CORE_RL_MagickWand_\PixelSetColor", "ptr", this, "astr", color, "int")
        this.ThrowForMagickException()
    }

    /**
     * Copies the color from one PixelWand onto this one
     * @param {PixelWand} other Pixel wand or unwrapped pointer to copy the color from 
     */
    SetColorFromWand(other) {
        if(!(other is PixelWand) && !IsInteger(other)) {
            throw ValueError("Expected a PixelWand or unwrapped PixelWand pointer, but got a(n) " Type(other), -1, other)
        }

        DllCall("CORE_RL_MagickWand_\PixelSetColorFromWand", "ptr", other)
        this.ThrowForMagickException()
    }

    /**
     * Clears the PixelWand
     */
    Clear() => DllCall("CORE_RL_MagickWand_\ClearPixelWand", "ptr", this)

    /**
     * The number of colors in the pixel wand
     * @type {Integer}
     */
    ColorCount {
        get => DllCall("CORE_RL_MagickWand_\PixelGetColorCount", "ptr", this, "uint")
        set => DllCall("CORE_RL_MagickWand_\PixelSetColorCount", "ptr", this, "uint", value)
    }

    /**
     * The color of the pixel wand as a string like "srgb(0,0,0)".
     * @see https://imagemagick.org/api/pixel-wand.php#PixelGetColorAsString
     * @type {String}
     */
    ColorAsString {
        get {
            pStr := DllCall("CORE_RL_MagickWand_\PixelGetColorAsString", "ptr", this, "ptr")
            this.ThrowForMagickException()
            return StrGet(pStr, , "UTF-8")
        }
    }

    /**
     * The normalized color of the pixel wand as a string like "0,0,0"
     * @see https://imagemagick.org/api/pixel-wand.php#PixelGetColorAsNormalizedString
     * @type {String}
     */
    ColorAsNormalizedString {
        get {
            pStr := DllCall("CORE_RL_MagickWand_\PixelGetColorAsNormalizedString", "ptr", this, "ptr")
            this.ThrowForMagickException()
            return StrGet(pStr, , "UTF-8")
        }
    }

    ;@endregion

    ;@region Color Properties

    /**
     * Gets or sets colormap index of the pixel wand.
     * @type {Float}
     */
    Index {
        get => DllCall("CORE_RL_MagickWand_\PixelGetIndex", "ptr", this, "double")
        set => DllCall("CORE_RL_MagickWand_\PixelSetIndex", "ptr", this, "double", value)
    }

    /**
     * The normalized HSL color of the pixel wand. To set the HSL color of the pixel, use `SetHSL`
     * @type {HSL}
     */
    HSL {
        get {
            DllCall("CORE_RL_MagickWand_\PixelGetHSL", 
                "ptr", this, 
                "double*", &hue := 0,
                "double*", &staturation := 0,
                "double*", &lightness := 0
            )
            this.ThrowForMagickException()
            return HSL(hue, staturation, lightness)
        }
    }

    /**
     * Sets the HSL color of the pixel wand.
     * @param {Float} hueOrHSL An {@link HSL `HSL`} object with color information, or else the hue of the color
     * @param {Float} saturation The saturation of the color
     * @param {Float} lightness The lightness of the color 
     */
    SetHsl(hueOrHSL, saturation?, lightness?) {
        hue := 0
        if(hueOrHSL is HSL) {
            hue := hueOrHSL
            saturation := hueOrHSL.saturation
            lightness := hueOrHSL.lightness
        }
        else{
            if(!IsSet(saturation) || !IsSet(lightness))
                throw ValueError("Saturation and lightness are required if hueOrHSL is not an HSL object", -1)

            hue := Float(hueOrHSL)
            saturation := Float(saturation)
            lightness := Float(lightness)
        }

        DllCall("CORE_RL_MagickWand_\PixelSetHSL", "ptr", this, "double", hue, "double", saturation, "double", lightness)
        this.ThrowForMagickException()
    }

    /**
     * The normalized alpha value of the pixel wand.
     * @type {Float}
     */
    Alpha {
        get => DllCall("CORE_RL_MagickWand_\PixelGetAlpha", "ptr", this, "double")
        set => DllCall("CORE_RL_MagickWand_\PixelSetAlpha", "ptr", this, "double", value)
    }

    /**
     * The alpha value of the pixel wand.
     * @type {Float}
     */
    AlphaQuantum {
        get => DllCall("CORE_RL_MagickWand_\PixelGetAlphaQuantum", "ptr", this, "double")
        set => DllCall("CORE_RL_MagickWand_\PixelSetAlphaQuantum", "ptr", this, "double", value)
    }

    /**
     * The normalized black value of the pixel wand.
     * @type {Float}
     */
    Black {
        get => DllCall("CORE_RL_MagickWand_\PixelGetBlack", "ptr", this, "double")
        set => DllCall("CORE_RL_MagickWand_\PixelSetBlack", "ptr", this, "double", value)
    }

    /**
     * The black value of the pixel wand.
     * @type {Float}
     */
    BlackQuantum {
        get => DllCall("CORE_RL_MagickWand_\PixelGetBlackQuantum", "ptr", this, "double")
        set => DllCall("CORE_RL_MagickWand_\PixelSetBlackQuantum", "ptr", this, "double", value)
    }

        /**
     * The normalized blue value of the pixel wand.
     * @type {Float}
     */
    Blue {
        get => DllCall("CORE_RL_MagickWand_\PixelGetBlue", "ptr", this, "double")
        set => DllCall("CORE_RL_MagickWand_\PixelSetBlue", "ptr", this, "double", value)
    }

    /**
     * The blue quantum value of the pixel wand.
     * @type {Float}
     */
    BlueQuantum {
        get => DllCall("CORE_RL_MagickWand_\PixelGetBlueQuantum", "ptr", this, "double")
        set => DllCall("CORE_RL_MagickWand_\PixelSetBlueQuantum", "ptr", this, "double", value)
    }

    /**
     * The normalized cyan value of the pixel wand.
     * @type {Float}
     */
    Cyan {
        get => DllCall("CORE_RL_MagickWand_\PixelGetCyan", "ptr", this, "double")
        set => DllCall("CORE_RL_MagickWand_\PixelSetCyan", "ptr", this, "double", value)
    }

    /**
     * The cyan quantum value of the pixel wand.
     * @type {Float}
     */
    CyanQuantum {
        get => DllCall("CORE_RL_MagickWand_\PixelGetCyanQuantum", "ptr", this, "double")
        set => DllCall("CORE_RL_MagickWand_\PixelSetCyanQuantum", "ptr", this, "double", value)
    }

    /**
     * The normalized green value of the pixel wand.
     * @type {Float}
     */
    Green {
        get => DllCall("CORE_RL_MagickWand_\PixelGetGreen", "ptr", this, "double")
        set => DllCall("CORE_RL_MagickWand_\PixelSetGreen", "ptr", this, "double", value)
    }

    /**
     * The green quantum value of the pixel wand.
     * @type {Float}
     */
    GreenQuantum {
        get => DllCall("CORE_RL_MagickWand_\PixelGetGreenQuantum", "ptr", this, "double")
        set => DllCall("CORE_RL_MagickWand_\PixelSetGreenQuantum", "ptr", this, "double", value)
    }

    /**
     * The normalized magenta value of the pixel wand.
     * @type {Float}
     */
    Magenta {
        get => DllCall("CORE_RL_MagickWand_\PixelGetMagenta", "ptr", this, "double")
        set => DllCall("CORE_RL_MagickWand_\PixelSetMagenta", "ptr", this, "double", value)
    }

    /**
     * The magenta quantum value of the pixel wand.
     * @type {Float}
     */
    MagentaQuantum {
        get => DllCall("CORE_RL_MagickWand_\PixelGetMagentaQuantum", "ptr", this, "double")
        set => DllCall("CORE_RL_MagickWand_\PixelSetMagentaQuantum", "ptr", this, "double", value)
    }

    /**
     * The normalized red value of the pixel wand.
     * @type {Float}
     */
    Red {
        get => DllCall("CORE_RL_MagickWand_\PixelGetRed", "ptr", this, "double")
        set => DllCall("CORE_RL_MagickWand_\PixelSetRed", "ptr", this, "double", value)
    }

    /**
     * The red quantum value of the pixel wand.
     * @type {Float}
     */
    RedQuantum {
        get => DllCall("CORE_RL_MagickWand_\PixelGetRedQuantum", "ptr", this, "double")
        set => DllCall("CORE_RL_MagickWand_\PixelSetRedQuantum", "ptr", this, "double", value)
    }

    /**
     * The normalized yellow value of the pixel wand.
     * @type {Float}
     */
    Yellow {
        get => DllCall("CORE_RL_MagickWand_\PixelGetYellow", "ptr", this, "double")
        set => DllCall("CORE_RL_MagickWand_\PixelSetYellow", "ptr", this, "double", value)
    }

    /**
     * The yellow quantum value of the pixel wand.
     * @type {Float}
     */
    YellowQuantum {
        get => DllCall("CORE_RL_MagickWand_\PixelGetYellowQuantum", "ptr", this, "double")
        set => DllCall("CORE_RL_MagickWand_\PixelSetYellowQuantum", "ptr", this, "double", value)
    }

    ;@endregion

    ;@region Comparison

    /**
     * The fuzz distance for color comparisons.
     * @type {Float}
     */
    Fuzz {
        get => DllCall("CORE_RL_MagickWand_\PixelGetFuzz", "ptr", this, "double")
        set => DllCall("CORE_RL_MagickWand_\PixelSetFuzz", "ptr", this, "double", value)
    }

    /**
     * Returns True if the distance between two colors is less than the specified distance.
     * @see https://imagemagick.org/api/pixel-wand.php#IsPixelWandSimilar
     * 
     * @param {PixelWand} other A pixel wand or pointer to a pixel wand to compare to this one 
     * @param {Float} fuzz Tny two colors that are less than or equal to this distance squared are consider similar. 
     */
    IsWandSimilar(other, fuzz) {
        if(!(other is PixelWand) && !IsInteger(other)) {
            throw ValueError("Expected a PixelWand or unwrapped PixelWand pointer, but got a(n) " Type(other), -1, other)
        }
        fuzz := Float(fuzz)

        similar := DllCall("CORE_RL_MagickWand_\IsPixelWandSimilar", "ptr", this, "ptr", other, "double", fuzz, "int")
        this.ThrowForMagickException()
        return similar
    }

    ;@endregion

    ;@region Error Handling

    /**
     * Returns the exception type associated with the wand. If no exception has occurred, 0 is returned.
     * @see https://imagemagick.org/api/pixel-wand.php#PixelGetExceptionType
     * @returns {Integer} The exception type assosciated with the wand.
     */
    GetExceptionType() => DllCall("CORE_RL_MagickWand_\PixelGetExceptionType", "ptr", this)

    /**
     * Clears any exceptions associated with the wand.
     * @see https://imagemagick.org/api/pixel-wand.php#PixelClearException
     */
    ClearExceptions() => DllCall("CORE_RL_MagickWand_\PixelClearException", "ptr", this)

    /**
     * Retrieves the description and severity of any error that occurs when using other methods in this API.
     * @see https://imagemagick.org/api/pixel-wand.php#PixelGetException
     * 
     * @param {VarRef<Integer>} severity An optional output variable which receives the severity of the error
     * @returns {String} The error description 
     */
    GetException(&severity := 0) {
        descPtr := DllCall("CORE_RL_MagickWand_\PixelGetException", "ptr", this, "uint*", severity)
        description := StrGet(descPtr, , "UTF-8")

        DllCall("CORE_RL_MagickWand_\MagickRelinquishMemory", "ptr", descPtr, "ptr")
        return description
    }

    /**
     * Throws a {@link MagickError `MagickError`} if the wand has any exceptions and clears all exceptions on the
     * wand. If `ThrowForWarnings` is truthy, also throws if a warning is present, otherwise, any warnings are 
     * silently discarded.
     * @param {Any} extra Any value to use as the error's {@link https://www.autohotkey.com/docs/v2/lib/Error.htm#Extra extra}
     *          property, if one is thrown
     */
    ThrowForMagickException(extra := "") {
        threshold := this.ThrowForWarnings ? MagickExceptionType.Warn_Min : MagickExceptionType.Error_Min
        exCode := this.GetExceptionType()

        if(exCode > threshold) {
            description := this.GetException()
            ; Always clear exceptions - if callers catch them, they shouldn't pollute future API calls
            this.ClearExceptions()
            throw MagickError(exCode, description, -3, extra)
        }
    }

    ;@endregion
}