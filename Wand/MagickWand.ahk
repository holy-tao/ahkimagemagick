#Requires AutoHotkey v2.0

#Include .\Errors\MagickError.ahk
#Include .\Errors\MagickExceptionType.ahk
#Include .\Core\MagickImageBlob.ahk
#Include .\PixelWand.ahk

#DllLoad CORE_RL_MagickWand_.dll

; See https://github.com/ImageMagick/ImageMagick/blob/408a18373ce59ab3a06c55b91d9dfc5397b7e1ca/MagickWand/magick-image.h
; See https://imagemagick.org/api/magick-wand.php#gsc.tab=0

/**
 * A Magick Wand is used to apply a series of effects to one or more images (the "image sequence")
 */
class MagickWand {
    ;@region Statics

    /**
     * Instantiates the MagickWand environment and registers an [OnExit](https://www.autohotkey.com/docs/v2/lib/OnExit.htm)
     * callback to clean it up when the script exits
     * @see https://imagemagick.org/api/magick-wand.php#MagickWandGenesis and terminus immediately below it
     */
    static InstantiateEnvironment() {
        DllCall("CORE_RL_MagickWand_\MagickWandGenesis")
        OnExit((*) => MagickWand.Terminus(), 1)
    }

    /**
     * Returns 1 if the ImageMagick environment is currently instantiated -- that is, 
     * [`MagickWandGenesis()`](https://imagemagick.org/api/magick-wand.php#MagickWandGenesis) has been called but 
     * [`MagickWandTerminus()`](https://imagemagick.org/api/magick-wand.php#MagickWandTerminus) has not.
     * @see https://imagemagick.org/api/magick-wand.php#IsMagickWandInstantiated 
     * @type {Integer (Boolean)}
     */
    static IsInstantiated => DllCall("CORE_RL_MagickWand_\IsMagickWandInstantiated")

    /**
     * Initializes the MagickWand environment. You generally don't need to do this yourself, a `MagickWand` object
     * will initialize the environment when it is created if it is not already initialized
     * @see https://imagemagick.org/api/magick-wand.php#MagickWandGenesis
     */
    static Genesis() => DllCall("CORE_RL_MagickWand_\MagickWandGenesis")

    /**
     * If the MagickWand environment is running, shuts it down and frees its resources. Because ImageMagick might be
     * multithreaded, you must ensure that all `MagickWand` objects and anything else using ImageMagick are finished.
     * 
     * If the MagickWand environment is not instantiated, this method does nothing. As such, it's safe to call
     * multiple times.
     * @see https://imagemagick.org/api/magick-wand.php#MagickWandTerminus
     */
    static Terminus() {
        if(MagickWand.IsInstantiated)
            DllCall("CORE_RL_MagickWand_\MagickWandTerminus")
    }

    /**
     * The ImageMagick version being used
     */
    static Version => MagickWand.QueryConfigureOption("VERSION")
    static LibVersion => StrReplace(MagickWand.QueryConfigureOption("LIB_VERSION_NUMBER"), ",", ".")

    /**
     * Returns the value assosciated with the specified configuration option. Configuration options are flags used
     * to compile ImageMagick, and are separate from command-line options or options set at runtime which control
     * its behavior.
     * 
     *      releaseDate := MagickWand.QueryConfigurationOption("RELEASE_DATE")
     * 
     * For a list of available options, see https://phpimagick.com/Imagick/getConfigureOptions
     * 
     * @see https://imagemagick.org/api/magick-wand.php#MagickQueryConfigureOption
     * 
     * @param {String} opt The option to query
     * @returns {String} The value assosciated with `opt`. If `opt` is not a valid option, returns 0.
     */
    static QueryConfigureOption(opt) {    
        strPtr := DllCall("CORE_RL_MagickWand_\MagickQueryConfigureOption", "astr", opt, "ptr")
        outStr := strPtr == 0 ? "" : StrGet(strPtr, , "UTF-8")
        DllCall("CORE_RL_MagickWand_\MagickRelinquishMemory", "ptr", strPtr)
        return outStr
    }

    /**
     * Returns any configure options that match the specified pattern (e.g. "*" for all). Options include NAME,
     * VERSION, LIB_VERSION, etc. Configuration options are flags used to compile ImageMagick, and are separate 
     * from command-line options or options set at runtime which control its behavior. Use `QueryConfigureOption`
     * to get the values assosciated with these options
     * 
     *      ; Print all version-related options to the console
     *      for(key in MagickWand.QueryConfigureOptions("*VERSION*")){
     *          FileAppend(key ": " MagickWand.QueryConfigureOption(key) "`n", "*")
     *      }
     * @see https://imagemagick.org/api/magick-wand.php#MagickQueryConfigureOptions
     * 
     * @param {String} pattern A text string containing a pattern.
     * @returns {Array<String>} An array of strings containing the names of all options matching `pattern`
     */
    static QueryConfigureOptions(pattern) {
        ppArr := DllCall("CORE_RL_MagickWand_\MagickQueryConfigureOptions", "astr", pattern, "uint*", &count := 0)

        options := [], options.Length := count
        Loop(count) {
            strPtr := NumGet(ppArr + ((A_Index - 1) * A_PtrSize), "ptr")
            options[A_Index] := StrGet(strPtr, , "UTF-8")
            DllCall("CORE_RL_MagickWand_\MagickRelinquishMemory", "ptr", strPtr)
        }

        return options
    }

    /**
     * Retrieves the names and values of all configure options in the form of a Map
     * @returns {Map<String, String>} A map of option keys to values
     */
    static GetAllConfigureOptions() {
        options := Map()
        for(key in this.QueryConfigureOptions("*")) {
            options[key] := MagickWand.QueryConfigureOption(key)
        }
        
        return options
    }

    /**
     * Returns any image formats that match the specified pattern (e.g. "*" for all).
     * @see https://imagemagick.org/api/magick-wand.php#MagickQueryFormats
     * 
     * @param {String} pattern The pattern to query (default: "*"). Returend formates are always uppercase, but the
     *          pattern is case-insensitive
     * @returns {Array<String>} All image formats matching the pattern 
     */
    static QueryImageFormats(pattern := "*") {
        pattern := StrUpper(pattern)    ; Formats are always uppercase
        ppArr := DllCall("CORE_RL_MagickWand_\MagickQueryFormats", "astr", pattern, "uint*", &count := 0, "ptr")

        formats := [], formats.Length := count
        Loop(count) {
            strPtr := NumGet(ppArr + ((A_Index - 1) * A_PtrSize), "ptr")
            formats[A_Index] := StrGet(strPtr, , "UTF-8")
            DllCall("CORE_RL_MagickWand_\MagickRelinquishMemory", "ptr", strPtr)
        }

        return formats
    }

    /**
     * Returns any font that match the specified pattern (e.g. "*" for all).
     * 
     *      segoeFamily := MagickWand.QueryFonts("Segoe*")
     * 
     * @see https://imagemagick.org/api/magick-wand.php#MagickQueryFonts
     * 
     * @param {String} pattern The pattern to query (default: "*"). The pattern is case-sensitive
     * @returns {Array<String>} All fonts matching `pattern`
     */
    static QueryFonts(pattern := "*") {
        ppArr := DllCall("CORE_RL_MagickWand_\MagickQueryFonts", "astr", pattern, "uint*", &count := 0, "ptr")

        fonts := [], fonts.Length := count
        Loop(count) {
            strPtr := NumGet(ppArr + ((A_Index - 1) * A_PtrSize), "ptr")
            fonts[A_Index] := StrGet(strPtr, , "UTF-8")
            DllCall("CORE_RL_MagickWand_\MagickRelinquishMemory", "ptr", strPtr)
        }

        return fonts
    }

    ;@endregion Statics

    ;@region Ctor & Initialization
    /**
     * Set to true to cause the `MagickWand` to throw `MagickErrors` for warnings (Default: false)
     * @type {Boolean}
     */
    ThrowForWarnings := false

    /**
     * Creates a new MagickWand for manipulating images
     * @param {Pointer} ptr A pointer to a MagickWand to wrap, otherwise a new wand is created
     */
    __New(ptr := 0) {
        ; Instantiate lazily, it's kind of a slow operation
        if(!MagickWand.IsInstantiated)
            MagickWand.InstantiateEnvironment()

        this.ptr := ptr == 0 ? DllCall("CORE_RL_MagickWand_\NewMagickWand") : ptr
    }

    /**
     * Creates a new MagickWand from an existing image pointer
     * @param {Pointer<Image>} imagePtr A pointer to an image
     * @returns {MagickWand} a new MagickWand
     */
    static FromImage(imagePtr) {
        ptr := DllCall("CORE_RL_MagickWand_\NewMagickWandFromImage", "ptr", imagePtr, "ptr")
        return MagickWand(ptr)
    }

    /**
     * Creates an exact copy of the MagickWand
     * @see https://imagemagick.org/api/magick-wand.php#CloneMagickWand
     * @returns {MagickWand} a copy of the wand
     */
    Clone() {
        wandPtr := DllCall("CORE_RL_MagickWand_\CloneMagickWand", "ptr", this)
        this.ThrowForMagickException()
        return MagickWand(wandPtr)
    }

    /**
     * Clears resources associated with the wand, leaving the wand blank, and ready to be used for a new set of images
     * @see https://imagemagick.org/api/magick-wand.php#ClearMagickWand
     */
    Clear() {
        DllCall("CORE_RL_MagickWand_\ClearMagickWand", "ptr", this)
        this.ThrowForMagickException()
    }

    ;@endregion

    ;@region Wand Properties

    /**
     * @readony Returns the ImageMagick home URL
     * @type {String}
     */
    HomeUrl => StrGet(DllCall("CORE_RL_MagickWand_\MagickGetHomeURL", "ptr", this), , "UTF-8")

    /**
     * @readonly Returns a pointer to the current image from the magick wand.
     * @type {Integer}
     */
    CurrentImage {
        get {
            DllCall("CORE_RL_MagickWand_\GetImageFromMagickWand", "ptr", this)
            this.ThrowForMagickException()
        }
    }

    /**
     * Returns true if the wand is verified as a magick wand. Can be used to distinguish magick wands from pixel and
     * drawing wands.
     * @see https://imagemagick.org/api/magick-wand.php#IsMagickWand
     * @type {Boolean}
     */
    IsMagickWand => DllCall("CORE_RL_MagickWand_\IsMagickWand", "ptr", this)

    /**
     * Gets or sets the image format of the current image in the sequence - "PNG", "JPEG", etc
     * @type {String}
     */
    ImageFormat {
        get {
            strPtr := DllCall("CORE_RL_MagickWand_\MagickGetImageFormat", "ptr", this, "ptr")
            this.ThrowForMagickException()
            return strPtr == 0 ? "" : StrGet(strPtr, , "UTF-8")
        }
        set {
            DllCall("CORE_RL_MagickWand_\MagickSetImageFormat", "ptr", this, "astr", value, "int")
            this.ThrowForMagickException(value)
        }
    }

    /**
     * Gets or sets the current image's filename. When not modified, this is the path from which the image was read,
     * which may be relative to the working directory at the time.
     * @type {String}
     */
    ImageFilename {
        get {
            strPtr := DllCall("CORE_RL_MagickWand_\MagickGetImageFilename", "ptr", this, "ptr")
            this.ThrowForMagickException()
            return strPtr == 0 ? "" : StrGet(strPtr, , "UTF-8")
        }   
        set {
            DllCall("CORE_RL_MagickWand_\MagickSetImageFilename", "ptr", this, "astr", value, "int")
            this.ThrowForMagickException(value)
        }
    }

    /**
     * Gets or Sets a key-value pair in the image artifact namespace. Setting an artifact key to an empty string 
     * deletes it.
     * 
     * Artifacts differ from properties. Properties are public and are generally exported to an external image format 
     * if the format supports it. Artifacts are private and are utilized by the internal ImageMagick API to modify the 
     * behavior of certain algorithms.
     * 
     * @see https://imagemagick.org/api/magick-property.php#MagickGetImageArtifact
     * 
     * @param {String} key The artifact to modify or retrieve
     */
    ImageArtifacts[key] {
        get {    
            strPtr := DllCall("CORE_RL_MagickWand_\MagickGetImageArtifact", "ptr", this, "astr", key, "ptr")
            this.ThrowForMagickException()
            outStr := strPtr == 0 ? "" : StrGet(strPtr, , "UTF-8")
            DllCall("CORE_RL_MagickWand_\MagickRelinquishMemory", "ptr", strPtr)
            return outStr
        }
        set {
            IsSpace(value) ? 
                DllCall("CORE_RL_MagickWand_\MagickDeleteImageArtifact", "ptr", this, "astr", key, "int") :
                DllCall("CORE_RL_MagickWand_\MagickSetImageArtifact", "ptr", this, "astr", key, "astr", value, "int")
            this.ThrowForMagickException(value)
        }
    }

    /** 
     * Gets the names of all image artifacts which match `pattern`
     * @see https://imagemagick.org/api/magick-property.php#MagickGetImageArtifacts
     * @param {String} pattern The pattern to search for. If unset, defaults to "*" (everything)
     * @returns {Array<String>} An array the names of all image artifacts in the wand
     */
    GetImageArtifacts(pattern := "*") {
        ppArr := DllCall("CORE_RL_MagickWand_\MagickGetImageArtifacts", "ptr", this, "astr", pattern, "uint*", &count := 0)
        this.ThrowForMagickException(pattern)

        artifacts := [], artifacts.Length := count
        Loop(count) {
            strPtr := NumGet(ppArr + ((A_Index - 1) * A_PtrSize), "ptr")
            artifacts[A_Index] := StrGet(strPtr, , "UTF-8")
            DllCall("CORE_RL_MagickWand_\MagickRelinquishMemory", "ptr", strPtr)
        }

        return artifacts
    }

    /**
     * Gets or Sets the value associated with the specified property. Setting a value to the empty string deletes it.
     * When accessing an image property, if the wand's current image doesn't have it, an empty string is returned.
     * 
     *      creationTime := wand.ImageProperties["date:create"]
     * 
     * Propeties are keys like "date:create", "exif:Compression", or "png:PLTE.number_colors". Many properties are
     * specific to image file formats. Use `GetImageProperties` to discover the available properties of an image.
     * 
     * @see https://imagemagick.org/api/magick-property.php#MagickGetImageProperty
     * 
     * @param {String} key The property to modify or retrieve
     */
    ImageProperties[key] {
        get {    
            strPtr := DllCall("CORE_RL_MagickWand_\MagickGetImageProperty", "ptr", this, "astr", key, "ptr")
            this.ThrowForMagickException()
            outStr := strPtr == 0 ? "" : StrGet(strPtr, , "UTF-8")
            DllCall("CORE_RL_MagickWand_\MagickRelinquishMemory", "ptr", strPtr)
            return outStr
        }
        set {
            IsSpace(value) ? 
                DllCall("CORE_RL_MagickWand_\MagickDeleteImageProperty", "ptr", this, "astr", key, "int") :
                DllCall("CORE_RL_MagickWand_\MagickSetImageProperty", "ptr", this, "astr", key, "astr", value, "int")
            this.ThrowForMagickException(value)
        }
    }

    /** 
     * Gets the names of all image properties which match `pattern`. Use `ImageProperties` to retrieve the values
     * 
     *      ; Retrieve the names and values of all exif properties
     *      props := Map()
     *      for(prop in wand.GetImageProperties("exif*")) {
     *          props[prop] := wand.ImageProperties[prop]
     *      }
     * 
     * @see https://imagemagick.org/api/magick-property.php#MagickGetImageProperties
     * 
     * @param {String} pattern The pattern to search for. If unset, defaults to "*" (everything)
     * @returns {Array<String>} An array the names of all image artifacts in the wand
     */
    GetImageProperties(pattern := "*") {
        ppArr := DllCall("CORE_RL_MagickWand_\MagickGetImageProperties", "ptr", this, "astr", pattern, "uint*", &count := 0)
        this.ThrowForMagickException(pattern)

        artifacts := [], artifacts.Length := count
        Loop(count) {
            strPtr := NumGet(ppArr + ((A_Index - 1) * A_PtrSize), "ptr")
            artifacts[A_Index] := StrGet(strPtr, , "UTF-8")
            DllCall("CORE_RL_MagickWand_\MagickRelinquishMemory", "ptr", strPtr)
        }

        return artifacts
    }
    ;@endregion

    ;@region Image Manipulation

    /**
     * Adaptively blurs the image by blurring less intensely near image edges and more intensely far from edges. We 
     * blur the image with a Gaussian operator of the given radius and standard deviation (sigma). For reasonable 
     * results, radius should be larger than sigma. Use a radius of 0 and `AdaptiveBlur` selects a suitable radius for 
     * you.
     * 
     * @see https://imagemagick.org/api/magick-image.php#MagickAdaptiveBlurImage
     * 
     * @param {Float} radius The radius of the Gaussian, in pixels, not counting the center pixel.
     * @param {Float} sigma The standard deviation of the Gaussian, in pixels.
     * @returns {MagickWand} The magick wand, for chaining
     */
    AdaptiveBlur(radius, sigma) {
        radius := Float(radius)
        sigma := Float(sigma)

        DllCall("CORE_RL_MagickWand_\MagickAdaptiveBlurImage", "ptr", this, "double", radius, "double", sigma, "int")
        this.ThrowForMagickException()
        return this
    }

    /**
     * Adaptively resize image with data dependent triangulation
     * @see https://imagemagick.org/api/magick-image.php#MagickAdaptiveResizeImage
     * 
     * @param {Integer} columns The number of columns in the scaled image.
     * @param {Integer} rows The number of rows in the scaled image.
     * @returns {MagickWand} The magick wand, for chaining
     */
    AdaptiveResize(columns, rows) {
        columns := Integer(columns)
        rows := Integer(rows)

        DllCall("CORE_RL_MagickWand_\MagickAdaptiveResizeImage", "ptr", this, "uint", columns, "uint", rows, "int")
        this.ThrowForMagickException()
        return this
    }

    /**
     * Adaptively sharpens the image by sharpening more intensely near image edges and less intensely far from edges. 
     * We sharpen the image with a Gaussian operator of the given radius and standard deviation (sigma). For 
     * reasonable results, radius should be larger than sigma. Use a radius of 0 and `AdaptiveSharpen` selects a 
     * suitable radius for you.
     * @see https://imagemagick.org/api/magick-image.php#MagickAdaptiveSharpenImage
     * 
     * @param {Float} radius The radius of the Gaussian, in pixels, not counting the center pixel.
     * @param {Float} sigma The standard deviation of the Gaussian, in pixels.
     * @returns {MagickWand} The magick wand, for chaining
     */
    AdaptiveSharpen(radius, sigma) {
        radius := Float(radius)
        sigma := Float(sigma)

        DllCall("CORE_RL_MagickWand_\MagickAdaptiveSharpenImage", "ptr", this, "double", radius, "double", sigma, "int")
        this.ThrowForMagickException()
        return this
    }

    /**
     * Selects an individual threshold for each pixel based on the range of intensity values in its local neighborhood. 
     * This allows for thresholding of an image whose global intensity histogram doesn't contain distinctive peaks.
     * @see https://imagemagick.org/api/magick-image.php#MagickAdaptiveThresholdImage
     * 
     * @param {Integer} width The width of the local neighborhood.
     * @param {Integer} height The height of the local neighborhood.
     * @param {Integer} offset The mean bias.
     * @returns {MagickWand} The magick wand, for chaining
     */
    AdaptiveThreshold(width, height, offset) {
        width := Integer(width)
        height := Integer(height)
        offset := Integer(offset)

        DllCall("CORE_RL_MagickWand_\MagickAdaptiveThresholdImage", "ptr", this, "uint", width, "uint", height, "uint", offset, "int")
        this.ThrowForMagickException()
        return this
    }

    /**
     * Adds a clone of the images from the second wand and inserts them into the current wand. 
     * 
     * Use `SetLastIterator` to append new images into an existing wand, current image will be set to last image so 
     * later adds with also be appended to end of wand. Use `SetFirstIterator` to prepend new images into wand, any 
     * more images added will also be prepended before other images in the wand. However the order of a list of new 
     * images will not change.
     * 
     * Otherwise the new images will be inserted just after the current image, and any later image will also be added 
     * after this current image but before the previously added images. Caution is advised when multiple image adds 
     * are inserted into the middle of the wand image list.
     * 
     * @see https://imagemagick.org/api/magick-image.php#MagickAddImage
     * @param {MagickWand} addWand A wand that contains the image list to be added.
     */
    AddImage(addWand) {
        if(!(addWand is MagickWand) || !IsInteger(addWand)) {
            throw ValueError("Expected a MagickWand or a pointer to a MagickWand, but got a(n) " Type(addWand), -1, addWand)
        }

        DllCall("CORE_RL_MagickWand_\MagickAddImage", "ptr", this, "ptr", addWand, "int")
        this.ThrowForMagickException()
        return this
    }

    /**
     * Adds random noise to the current image. Use the {@link MagickNoiseType noise type enum} to indicate noise
     * type
     *  
     *      wand.AddNoise(MagickNoiseType.Random, 2.0)
     * 
     * @see https://imagemagick.org/api/magick-image.php#MagickAddNoiseImage
     *  
     * @param {NoiseType} noiseType The type of noise: Uniform, Gaussian, Multiplicative, Impulse, Laplacian, or Poisson.
     * @param {Float} attenuate attenuate the random distribution.
     * @returns {MagickWand} The magick wand, for chaining
     */
    AddNoise(noiseType, attenuate) {
        attenuate := Float(attenuate)
        DllCall("CORE_RL_MagickWand_\MagickAddNoiseImage", "ptr", this, "int", noiseType, "double", attenuate, "int")
        this.ThrowForMagickException(noiseType)
        return this
    }

    /**
     * Transforms an image as dictated by the affine matrix of the drawing wand.
     * @deprecated ;TODO requires DrawingWand
     * @see https://imagemagick.org/api/magick-image.php#MagickAffineTransformImage
     * @param {DrawingWand} drawingWand The drawing wand 
     */
    AffineTransform(drawingWand) {
        throw MethodError("Not implemented (DrawingWand)")
    }

    /**
     * Animates an image or image sequence.
     * @see https://imagemagick.org/api/magick-image.php#MagickAnimateImages
     * 
     * @param {String} serverName the X server name.
     * @returns {MagickWand} The magick wand, for chaining
     */
    AnimateImages(serverName) {
        DllCall("CORE_RL_MagickWand_\MagickAnimateImages", "ptr", this, "astr", serverName, "int")
        this.ThrowForMagickException("X Server name: `"" serverName '"')
        return this
    }

    /**
     * Displays the current image.
     * @see https://imagemagick.org/script/display.php
     * @param {String} serverName the X server name.
     * @returns {MagickWand} The magick wand, for chaining
     */
    Display(serverName := "") {
        DllCall("CORE_RL_MagickWand_\MagickDisplayImage", "ptr", this, "astr", serverName, "int")
        this.ThrowForMagickException("X Server name: `"" serverName '"')
        return this
    }

    /**
     * Append the images in a wand from the current image onwards, creating a new wand with the single image result. 
     * This is affected by the gravity and background settings of the first image.
     * 
     * Typically you would call either `ResetIterator` or `SetFirstImage` before calling this function to ensure that 
     * all the images in the wand's image list will be appended together.
     * @see https://imagemagick.org/api/magick-image.php#MagickAppendImages
     * 
     * @param {Boolean} stack By default, images are stacked left-to-right. Set stack to true to stack them 
     *          top-to-bottom.
     * @returns {MagickWand} A new wand with the single resulting image.
     */
    AppendImages(stack := false) {
        appended := DllCall("CORE_RL_MagickWand_\MagickAppendImages", "ptr", this, "int", stack, "int")
        this.ThrowForMagickException()
        return MagickWand(appended)
    }

    /**
     * Extracts the 'mean' from the image and adjust the image to try make set its gamma appropriately.
     * @see https://imagemagick.org/api/magick-image.php#MagickAutoGammaImage
     * @returns {MagickWand} The magick wand, for chaining
     */
    AutoGamma() {
        DllCall("CORE_RL_MagickWand_\MagickAutoGammaImage", "ptr", this)
        this.ThrowForMagickException()
        return this
    }

    /**
     * Adjusts the levels of a particular image channel by scaling the minimum and maximum values to the full quantum 
     * range.
     * @see https://imagemagick.org/api/magick-image.php#MagickAutoLevelImage
     * @returns {MagickWand} The magick wand, for chaining
     */
    AutoLevel() {
        DllCall("CORE_RL_MagickWand_\MagickAutoLevelImage", "ptr", this)
        this.ThrowForMagickException()
        return this
    }

    /**
     * Adjusts an image so that its orientation is suitable $ for viewing (i.e. top-left orientation).
     * @see https://imagemagick.org/api/magick-image.php#MagickAutoOrientImage
     * @returns {MagickWand} The magick wand, for chaining
     */
    AutoOrient() {
        DllCall("CORE_RL_MagickWand_\MagickAutoOrientImage", "ptr", this)
        this.ThrowForMagickException()
        return this
    }

    /**
     * Automatically performs image thresholding dependent on which method you specify.
     * @see https://imagemagick.org/api/magick-image.php#MagickAutoThresholdImage
     * 
     * @param {AutoThresholdMethod} method Choose from KapurThresholdMethod, OTSUThresholdMethod, or 
     *          TriangleThresholdMethod.
     * @returns {MagickWand} The magick wand, for chaining
     */
    AutoThreshold(method) {
        DllCall("CORE_RL_MagickWand_\MagickAutoThresholdImage", "ptr", this, "int", method, "int")
        this.ThrowForMagickException(method)
        return this
    }

    /**
     * `BilateralBlur` is a non-linear, edge-preserving, and noise-reducing smoothing filter for images. It replaces 
     * the intensity of each pixel with a weighted average of intensity values from nearby pixels. This weight is 
     * based on a Gaussian distribution. The weights depend not only on Euclidean distance of pixels, but also on the 
     * radiometric differences (e.g., range differences, such as color intensity, depth distance, etc.). This 
     * preserves sharp edges.
     * @see https://imagemagick.org/api/magick-image.php#MagickBilateralBlurImage
     * 
     * @param {Float} radius The radius of the Gaussian, in pixels, not counting the center pixel.
     * @param {Float} sigma The standard deviation of the Gaussian, in pixels.
     * @param {Float} intensitySigma Sigma in the intensity space. A larger value means that farther colors within the 
     *          pixel neighborhood (see `spatialSigma`) will be mixed together, resulting in larger areas of semi- 
     *          equal color.
     * @param {Float} spatialSigma Sigma in the coordinate space. A larger value means that farther pixels influence 
     *          each other as long as their colors are close enough (see `intensitySigma`). When the neighborhood 
     *          diameter is greater than zero, it specifies the neighborhood size regardless of `spatialSigma`. 
     *          Otherwise, the neighborhood diameter is proportional to `spatialSigma`.
     * @returns {MagickWand} The magick wand, for chaining
     */
    BilateralBlur(radius, sigma, intensitySigma, spatialSigma) {
        radius := Float(radius)
        sigma := Float(sigma)
        intensitySigma := Float(intensitySigma)
        spatialSigma := Float(spatialSigma)

        DllCall("CORE_RL_MagickWand_\MagickBilateralBlurImage",
            "ptr", this,
            "double", radius,
            "double", sigma,
            "double", intensitySigma,
            "double", spatialSigma,
            "int")
        this.ThrowForMagickException()
        return this
    }

    /**
     * `BlackThreshold` is like `Threshold` but forces all pixels below the threshold into black while leaving all 
     * pixels above the threshold unchanged.
     * @see https://imagemagick.org/api/magick-image.php#MagickBlackThresholdImage
     * 
     * @param {PixelWand} thresholdWand The pixel wand
     */
    BlackThreshold(thresholdWand) {
        if(!(thresholdWand is PixelWand) && !IsInteger(thresholdWand)) {
            throw ValueError("Expected a PixelWand or unwrapped PixelWand pointer, but got a(n) " Type(thresholdWand), -1, thresholdWand)
        }

        DllCall("CORE_RL_MagickWand_\MagickBlackThresholdImage", "ptr", this, "ptr", thresholdWand)
        this.ThrowForMagickException()
        return this
    }

    /**
     * Mutes the colors of the image to simulate a scene at nighttime in the moonlight.
     * @see https://imagemagick.org/api/magick-image.php#MagickBlueShiftImage
     * 
     * @param {Float} factor The blue shift factor (default 1.5)
     * @returns {MagickWand} The magick wand, for chaining
     */
    BlueShift(factor := 1.5) {
        factor := Float(factor)

        DllCall("CORE_RL_MagickWand_\MagickBlueShiftImage", "ptr", this, "double", factor, "int")
        this.ThrowForMagickException(factor)
        return this
    }

    /**
     * Surrounds the image with a border of the color defined by the bordercolor pixel wand.
     * @see https://imagemagick.org/api/magick-image.php#MagickBorderImage
     * 
     * @param {PixelWand} borderColor The border color pixel wand.
     * @param {Integer} width The border width
     * @param {Integer} height The border height
     * @param {CompositeOperator} compose The composite operator.
     * @returns {MagickWand} The magick wand, for chaining
     */
    Border(borderColor, width, height, compose) {
        if(!(borderColor is PixelWand) && !IsInteger(borderColor)) {
            throw ValueError("Expected a PixelWand or unwrapped PixelWand pointer, but got a(n) " Type(borderColor), -1, borderColor)
        }
        width := Integer(width)
        height := Integer(height)

        DllCall("CORE_RL_MagickWand_\MagickBorderImage", "ptr", this, "ptr", borderColor, "uint", width, "uint", height, "int", compose)
        this.ThrowForMagickException()
        return this
    }

    /**
     * Changes the brightness and/or contrast of an image. Converts the brightness and contrast parameters into slope 
     * and intercept and calls a polynomial function to apply to the image.
     * 
     * @param {Float} brightness The brightness percent (-100 .. 100).
     * @param {Float} contrast The contrast percent (-100 .. 100).
     * @returns {MagickWand} The magick wand, for chaining
     */
    BrightnessContrast(brightness, contrast) {
        brightness := Float(brightness)
        if(brightness < -100.0 || brightness > 100.0)
            throw ValueError("Brightness out of range", -1, brightness)

        contrast := Float(contrast)
        if(contrast < -100.0 || contrast > 100.0)
            throw ValueError("Contrast out of range", -1, contrast)

        DllCall("CORE_RL_MagickWand_\MagickBrightnessContrastImage", "ptr", this, "double", brightness, "double", contrast, "int")
        this.ThrowForMagickException()
        return this
    }

    /**
     * Uses a multi-stage algorithm to detect a wide range of edges in images.
     * @see https://imagemagick.org/api/magick-image.php#MagickCannyEdgeImage
     * 
     * @param {Float} radius The radius of the gaussian smoothing filter.
     * @param {Float} sigma The sigma of the gaussian smoothing filter.
     * @param {Float} lowerPercent Percentage of edge pixels in the lower threshold.
     * @param {Float} upperPercent Percentage of edge pixels in the upper threshold.
     * @returns {MagickWand} The magick wand, for chaining
     */
    CannyEdge(radius, sigma, lowerPercent, upperPercent) {
        radius := Float(radius)
        sigma := Float(sigma)
        lowerPercent := Float(lowerPercent)
        upperPercent := Float(upperPercent)

        DllCall("CORE_RL_MagickWand_\MagickCannyEdgeImage", "ptr", this, "double", radius, "double", sigma, "double", lowerPercent, "double", upperPercent)
        this.ThrowForMagickException()
        return this
    }

    /**
     * Applies a channel expression to the specified image. The expression consists of one or more channels, either 
     * mnemonic or numeric (e.g. red, 1), separated by actions as follows:
     *  - `<=>`: exchange two channels (e.g. red<=>blue)
     *  - `=>` transfer a channel to another (e.g. red=>green)
     *  - `,` separate channel operations (e.g. red, green)
     *  - `|` read channels from next input image (e.g. red | green)
     *  - `;` write channels to next output image (e.g. red; green; blue)
     * 
     * A channel without a operation symbol implies extract. For example, to create 3 grayscale images from the red, 
     * green, and blue channels of an image, use:
     * 
     *      wand.ChannelFx("red; green; blue)
     * @see https://imagemagick.org/api/magick-image.php#MagickChannelFxImage
     * 
     * @param {String} expression The expression to apply
     * @returns {MagickWand} A new magick wand containing the results of the channel expression.
     */
    ChannelFx(expression) {
        wandPtr := DllCall("CORE_RL_MagickWand_\MagickChannelFxImage", "ptr", this, "astr", expression, "ptr")
        this.ThrowForMagickException()
        return MagickWand(wandPtr)
    }

    /**
     * Simulates the effects of charcoal drawing
     * @see https://imagemagick.org/api/magick-image.php#MagickCharcoalImage
     * 
     * @param {Float} radius The radius of the Gaussian, in pixels, not counting the center pixel.
     * @param {Float} sigma The standard deviation of the Gaussian, in pixels.
     * @returns {MagickWand} The magick wand, for chaining
     */
    Charcoal(radius, sigma) {
        radius := Float(radius)
        sigma := Float(sigma)

        DllCall("CORE_RL_MagickWand_\MagickCharcoalImage", "ptr", this, "double", radius, "double", sigma)
        this.ThrowForMagickException()
        return this
    }

    ;@endregion

    ;@region I/O

    /**
     * Reads an image or image sequence.  The images are inserted just before the current image pointer position.
     * 
     * Use `SetFirstIterator()` to insert new images before all the current images in the wand, `SetLastIterator()` 
     * to append add to the end, `SetIteratorIndex()` to place images just after the given index.
     * @param {String | Buffer} input Either the path to an image file to read, an open file descriptor for an
     *          image file, or a Buffer or {@link https://www.autohotkey.com/docs/v2/lib/Buffer.htm#like buffer-like object }
     *          containing a binary image or image sequence
     * @returns {MagickWand} The magick wand, for chaining
     */
    ReadImage(input) {
        success := false
        switch {
            case input is String: 
                DllCall("CORE_RL_MagickWand_\MagickReadImage", "ptr", this, "astr", input, "int")
            case (input.HasProp("ptr") && input.HasProp("size")): 
                DllCall("CORE_RL_MagickWand_\MagickReadImageBlob", "ptr", this, "ptr", input.ptr, "uint", input.size, "int")
            default:
                throw ValueError("Expected a filepath, open file, Buffer, or buffer-like object, but got a(n) " Type(input), -1, input)
        }

        this.ThrowForMagickException(input)
        return this
    }

    /**
     * Reads multiple images in. See `ReadImage` for details
     * @param {String | Buffer} inputs A variadic array of `ReadImage` inputs
     * @returns {MagickWand} The magick wand, for chaining
     */
    ReadImages(inputs*) {
        for(input in inputs)
            this.ReadImage(input)
        return this
    }

    /**
     * Writes an image to the specified open file or filename.  If the filename parameter is blank, the image is 
     * written to the filename set by `ReadImage` or `SetImageFilename`.
     * 
     * To write an image to a buffer, use `GetImageBlob` after setting `ImageFormat` to your desired format.
     * 
     * @param {String} fileOrFileName The destination file or filepath. Leave blank to use the filepath
     *          set by `ReadImage` or `SetImageFilename` 
     * @returns {MagickWand} The magick wand, for chaining
     * 
     * @example <caption>Create a png copy of "logo.gif"</caption>
     * wand := MagickWand()
     * wand.ReadImage("logo.gif")
     * wand.WriteImage("logo.png")
     */
    WriteImage(fileOrFileName := "") {
        if(fileOrFileName is String) {
            IsSpace(fileOrFileName) ?
                DllCall("CORE_RL_MagickWand_\MagickWriteImage", "ptr", this, "ptr", 0, "int") :
                DllCall("CORE_RL_MagickWand_\MagickWriteImage", "ptr", this, "astr", fileOrFileName, "int")
        }
        else {
            throw TypeError("Expected a String or File, but got a(n) " Type(fileOrFileName), -1, fileOrFileName)
        }

        this.ThrowForMagickException(fileOrFileName)
        return this
    }

    /**
     * Writes an image or image sequence to a new file or an open file descriptor, optionally combining them into
     * a single multi-image file. Combining images is not supported when passing an open file descriptor. Unlike
     * `WriteImage`, fileOrFileName cannot be empty.
     * 
     * To write images to a buffer, call `MagickGetImagesBlob` after setting `ImageFormat` to your desired format
     * 
     * @param {String} filename The destination filepath
     * @param {Boolean} adjoin True to join the images into a single multi-image file. If false or the output file
     *          format does not support multi-image files, images are written to sequentially-named files like
     *          "fileOrFileName-0", "fileOrFileName-1", etc. (default: false)
     * @returns {MagickWand} The magick wand, for chaining
     */
    WriteImages(fileOrFileName, adjoin := false) {
        switch {
            case fileOrFileName is String: DllCall("CORE_RL_MagickWand_\MagickWriteImages", "ptr", this, "astr", fileOrFileName, "char", adjoin ? 1 : 0, "int")
            case fileOrFileName is File: DllCall("CORE_RL_MagickWand_\MagickWriteImagesFile", "ptr", this, "ptr", fileOrFileName.Handle)
            default: throw TypeError("Expected a String or a File, but got a(n) " Type(fileOrFileName), -1, fileOrFileName)
        }

        this.ThrowForMagickException(fileOrFileName)
        return this
    }

    /**
     * Returns the image as a blob (a formatted "file" in memory), starting from the current position in the image
     * sequence.  Set `ImageFormat` to the format to write to the blob (GIF, JPEG,  PNG, etc.).
     * 
     * Utilize `ResetIterator` to ensure the write is from the beginning of the image sequence.
     * 
     * @returns {MagickImageBlob} An object representing the image blob
     */
    GetImageBlob() {
        blobPtr := DllCall("CORE_RL_MagickWand_\MagickGetImageBlob", "ptr", this, "uint*", &length := 0)
        this.ThrowForMagickException()
        return MagickBlob(this.ImageFormat, blobPtr, length)
    }

    /**
     * Returns the image sequence as a blob. The format of the current image determines the format of the returned 
     * blob (GIF, JPEG, PNG, etc.). To return a different image format, set `ImageFormat`.
     * 
     * Note, some image formats do not permit multiple images to the same image stream (e.g. JPEG).  in this instance, 
     * just the first image of the sequence is returned as a blob.
     * 
     * @returns {MagickImageBlob} An object representing the image blob
     */
    GetImagesBlob() {
        blobPtr := DllCall("CORE_RL_MagickWand_\MagickGetImagesBlob", "ptr", this, "uint*", &length := 0)
        this.ThrowForMagickException()
        return MagickBlob(this.ImageFormat, blobPtr, length)
    }

    ;@endregion

    ;@region Enumeration

    /**
     * Gets the iterator index, or sets the iterator to the given position in the image list specified with the index 
     * parameter. 
     * 
     * A zero index will set the first image as current, and so on. Negative indexes can be used to specify an image 
     * relative to the end of the images in the wand, with -1 being the last image in the wand.
     * 
     * After using any images added to the wand using `AddImage`or `ReadImage` will be added after the image indexed, 
     * regardless of if a zero (first image in list) or negative index (from end) is used. 
     * 
     * Jumping to index 0 is similar to `ResetIterator` but differs in how `NextImage` behaves afterward.
     * 
     * @see https://imagemagick.org/api/magick-wand.php#MagickSetIteratorIndex
     * @type {Integer}
     */
    IteratorIndex {
        get {
            index := DllCall("CORE_RL_MagickWand_\MagickGetIteratorIndex", "ptr", this, "uint")
            this.ThrowForMagickException()
            return index
        }
        set {
            result := DllCall("CORE_RL_MagickWand_\MagickSetIteratorIndex", "ptr", this, "uint", value, "int")
            if(result == false)
                throw IndexError("Index out of range", -1, value)
            this.ThrowForMagickException(value)
        }
    }

    /**
     * Sets the wand iterator to the last image.
     * 
     * The last image is actually the current image, and the next use of `PreviousImage` will not change this allowing 
     * this function to be used to iterate over the images in the reverse direction. In this sense it is more like 
     * `ResetIterator` than `SetFirstIterator`.
     * 
     * Typically this function is used before `AddImage`, `ReadImage` functions to ensure new images are appended to 
     * the very end of wand's image list.
     * @see https://imagemagick.org/api/magick-wand.php#MagickSetLastIterator
     */
    SetLastIterator() {
        DllCall("CORE_RL_MagickWand_\MagickSetLastIterator", "ptr", this)
        this.ThrowForMagickException()
    }

    /**
     * Sets the wand iterator to the first image.
     * 
     * After using any images added to the wand using `AddImage` or `ReadImage` will be prepended before any image in 
     * the wand.
     * 
     * Also the current image has been set to the first image (if any) in the Magick Wand. Using `NextImage` will then 
     * set the current image to the second image in the list (if present).
     * 
     * This operation is similar to `ResetIterator` but differs in how `AddImage`, `ReadImage`, and `NextImage` 
     * behaves afterward.
     * @see https://imagemagick.org/api/magick-wand.php#MagickSetFirstIterator
     */
    SetFirstIterator() {
        DllCall("CORE_RL_MagickWand_\MagickSetFirstIterator", "ptr", this)
        this.ThrowForMagickException()
    }

    /**
     * Resets the wand iterator.
     * 
     * It is typically used either before iterating though images, or before calling specific functions such as 
     * `AppendImages` to append all images together.
     * 
     * Afterward you can use `NextImage` to iterate over all the images in a wand container, starting with the first 
     * image. Using this before `AddImages` or `ReadImages` will cause new images to be inserted between the first and 
     * second image.
     * @see https://imagemagick.org/api/magick-wand.php#MagickResetIterator
     */
    ResetItrator() {
        DllCall("CORE_RL_MagickWand_\MagickResetIterator", "ptr", this)
        this.ThrowForMagickException()
    }

    /**
     * Sets the next image in the wand as the current image. It is typically used after `ResetIterator`, after which 
     * its first use will set the first image as the current image (unless the wand is empty).
     * 
     * It will return False when no more images are left to be returned which happens when the wand is empty, or the 
     * current image is the last image.
     * 
     * When the above condition (end of image list) is reached, the iterator is automatically set so that you can 
     * start using `PreviousImage` to again iterate over the images in the reverse direction, starting with the last 
     * image (again). You can jump to this condition immediately using `SetLastIterator`
     * 
     * @returns {Boolean} 1 if there are more images left in the wand, 0 otherwise
     */
    NextImage() {
        result := DllCall("CORE_RL_MagickWand_\MagickNextImage", "ptr", this, "int")
        this.ThrowForMagickException()
        return result
    }

    /**
     * Indicates whether or not the wand has a next image
     * @type {Boolean}
     */
    HasNext => DllCall("CORE_RL_MagickWand_\MagickHasNextImage", "ptr", this, "int")

    /**
     * Sets the previous image in the wand as the current image. 
     * 
     * It is typically used after MagickSetLastIterator(), after which its first use will set the last image as the 
     * current image (unless the wand is empty). It will return False when no more images are left to be returned
     * which happens when the wand is empty, or the current image is the first image. At that point the iterator is 
     * than reset to again process images in the forward direction, again starting with the first image in list.
     * Images added at this point are prepended.
     * 
     * Also at that point any images added to the wand using `AddImages` or `ReadImages` will be prepended before the 
     * first image. In this sense the condition is not quite exactly the same as `ResetIterator`.
     * 
     * @returns {Boolean} 1 if there are more images left in the wand, 0 otherwise
     */
    PreviousImage() {
        result := DllCall("CORE_RL_MagickWand_\MagickPreviousImage", "ptr", this, "int")
        this.ThrowForMagickException()
        return result
    }

    /**
     * Indicates whether or not the wand has a previous image
     * @type {Boolean}
     */
    HasPrevious => DllCall("CORE_RL_MagickWand_\MagickHasPreviousImage", "ptr", this, "int")

    /**
     * Enumerates Image pointers in the wand in ascending order (first-last)
     */
    __Enum(numVars) {
        if(numVars < 0 || numVars > 2)
            throw ValueError("Invalid number of variables passed to enumerator", -1, numVars)

        this.ResetItrator()
        return numVars == 1 ? EnumImages : EnumIndicesAndImages
        
        EnumImages(&img) {
            if(!this.HasNext)
                return false

            this.NextImage()
            img := this.CurrentImage
            return true
        }

        EnumIndicesAndImages(&idx, &img) {
            if(!this.HasNext)
                return false

            this.NextImage()
            idx := this.IteratorIndex
            img := this.CurrentImage
            return true
        }
    }

    ;@endregion

    ;@region Error Handling

    /**
     * Returns the exception type associated with the wand. If no exception has occurred, 0 is returned.
     * @see https://imagemagick.org/api/magick-wand.php#MagickGetExceptionType
     * @returns {Integer} The exception type assosciated with the wand.
     */
    GetExceptionType() => DllCall("CORE_RL_MagickWand_\MagickGetExceptionType", "ptr", this)

    /**
     * Clears any exceptions associated with the wand.
     * @see https://imagemagick.org/api/magick-wand.php#MagickClearException
     */
    ClearExceptions() => DllCall("CORE_RL_MagickWand_\MagickClearException", "ptr", this)

    /**
     * Retrieves the description and severity of any error that occurs when using other methods in this API.
     * @see https://imagemagick.org/api/magick-wand.php#MagickGetException
     * 
     * @param {VarRef<Integer>} severity An optional output variable which receives the severity of the error
     * @returns {String} The error description 
     */
    GetException(&severity := 0) {
        descPtr := DllCall("CORE_RL_MagickWand_\MagickGetException", "ptr", this, "uint*", severity)
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

    ;@endregion Error Handling
}