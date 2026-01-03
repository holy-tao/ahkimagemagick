#Requires AutoHotkey v2.0

#DllLoad CORE_RL_MagickWand_.dll

/**
 * Represents an image as a blob (a formatted "file" in memory). `MagickImageBlob` is 
 * {@link https://www.autohotkey.com/docs/v2/lib/Buffer.htm#like buffer-like}, so can be used
 * like a native buffer and passed to NumGet, DllCall, and so forth.
 * 
 * MagickBlob will relinquish its memory when the AutoHotkey object falls out of scope
 */
class MagickBlob {
    __New(format, ptr, size) {
        this.format := format
        this.ptr := ptr
        this.size := size
    }

    __Delete() => DllCall("CORE_RL_MagickWand_\MagickRelinquishMemory", "ptr", this)
}