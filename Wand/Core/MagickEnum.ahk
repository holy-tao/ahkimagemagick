#Requires AutoHotkey v2.0

/**
 * Base class for ImageMagick Enumerations - holds shared helper methods
 */
class MagickEnum {
    /**
     * Gets the name of an enumeration value.
     * 
     *      MagickExceptionType.GetName(795) ; "ConfigureFatalError"
     * 
     * @param {Integer} value The value to get the name of 
     * @returns {String} The name of the value
     */
    static GetName(value) {
        if(!IsInteger(value))
            throw TypeError("Expected an Integer but got a(n) " Type(value), -1, value)

        for(key, enumValue in this.OwnProps()){
            if(enumValue == value)
                return key
        }

        throw ValueError(Format("Not a(n) {1} error code", this.Prototype.__Class), -1, value)
    }
}