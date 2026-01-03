# AHK ImageMagick
[![Unit Tests](https://github.com/holy-tao/ahkimagemagick/actions/workflows/unit-tests.yml/badge.svg)](https://github.com/holy-tao/ahkimagemagick/actions/workflows/unit-tests.yml)

Modern [ImageMagick](https://imagemagick.org/) bindings for AutoHotkey v2. 

> ImageMagick[®](https://tsdr.uspto.gov/#caseNumber=78333969&caseType=SERIAL_NO&searchType=statusSearch) is a [free](https://imagemagick.org/script/license.php#gsc.tab=0), open-source software suite, used for editing and manipulating digital images. It can be used to create, edit, compose, or convert bitmap images, and supports a wide range of file [formats](https://imagemagick.org/script/formats.php#gsc.tab=0), including JPEG, PNG, GIF, TIFF, and Ultra HDR.

ImageMagick was previously accessible to AHK via a [ComObject](https://www.autohotkey.com/boards/viewtopic.php?f=6&t=77#p492) that was packaged with the installer, but the project has since been [deprecated](https://github.com/ImageMagick/ImageMagick/issues/4820) and is no longer supported; the git repository is [archived](https://github.com/ImageMagick/contrib/tree/main/win32/ATL7/ImageMagickObject). This project uses the modern C API to interact with the program.

This project implements ImageMagick bindings via the **MagickWand** interface. A MagickWand is an object that allows you to load, save, and apply effects to images or series' of images. 


```autohotkey
#Include <ImageMagick/Wand/MagickWand>
#Include <ImageMagick/Wand/Enums/NoiseType>

wand := MagickWand()

wand.ReadImage("path/to/input.png")
wand.AddNoise(NoiseType.Gaussian, 1.0)
wand.WriteImage("path/to/output.jpg")
```

This project does not include the [DrawingWand](https://imagemagick.org/api/drawing-wand.php), but might in the future. It also does not include any of the lower level MagickCore APIs, but similarly might in the future. This project is very much a work in progress.

No ImageMagick code is distributed with this project, and ImageMagick is governed by its own [license](https://imagemagick.org/script/license.php).

### Installation
Begin by [installing ImageMagick](https://imagemagick.org/script/download.php#windows) on your computer. 
> [!IMPORTANT]
> You ***must*** install a version of ImageMagick that **includes dll files**. When running the installer, ensure that you **check** the option to add ImageMagick to your PATH, or [`#DllLoad`](https://www.autohotkey.com/docs/v2/lib/_DllLoad.htm) may be unable to find it.

This library is tested with `ImageMagick-7.1.2-12-Q16-HDRI-x64-dll.exe`, but any 64-bit distribution should work. The 32-bit distributions _might_ also work, but I make no guarantees and cannot test them. I also can't test the arm64 distributions, but I am less hesitant about those.

Once you've confirmed that ImageMagick is installed correctly, clone this repository into an [AutoHotkey library directory](https://www.autohotkey.com/docs/v2/Scripts.htm#lib):
```bash
git clone git@github.com:holy-tao/ahkimagemagick.git ImageMagick
```

To verify that everything works, run the following script and ensure that the version you see matches the version you installed:
```autohotkey
#Include <ImageMagick/Wand/MagickWand>

MsgBox(MagickWand.Version)
```

### Usage

A `MagickWand` object can manipulate one or more images. You can read in images from files or as binary data by passing a filepath or buffer to `ReadImage`. Once you've loaded one or more images, you can apply any number of effects to them, and then write them out to a file. Most wand operations can be chained, but do read the documentation, as some will return _new_ `MagickWand`s:
```autohotkey
#Include <ImageMagick/Wand/MagickWand>
#Include <ImageMagick/Wand/Enums/NoiseType>
#Include <ImageMagick/Wand/Enums/CompositeOperator>

; For demonstration only - this does not produce a nice effect
wand := MagickWand()
    .ReadImage("path/to/input.png")
    .AddNoise(NoiseType.Gaussian, 1.0)
    .BlueShift(2)
    .Border(PixelWand("#e60eb7"), 4, 4, CompositeOperator.Over)
    .WriteImage("path/to/output.jpg")
```

Many ImageMagick methods take enumeration values; those can be found at [Wand/Enums/](./Wand/Enums/)

#### Error Handling
MagickWand operations may throw [`MagickError`](./Wand/Errors/MagickError.ahk)s if they fail. In addition to the normal properties of Error objects, `MagickError` objects have:
- `Severity`: either "Success", "Warning", "Error", or "Fatal"
- `ExceptionType`: a String grouper name for the [exception type](./Wand/Errors/MagickExceptionType.ahk) of exception - "BlobError", "DelegateFatalError", etc
- `Number`: the numeric error code of the exception. This encodes severity and exception type

ImageMagick can also produce warnings. By default these are ignored, but you can instruct a `MagickWand` to throw errors for warnings by setting its `ThrowForWarnings` property to `true`.

You can read more about ImageMagick errors and warnings on their [website](https://imagemagick.org/script/exception.php#gsc.tab=0).

#### The MagickWand environment
An MagickWand environment is initialized whenever you create a `MagickWand` object if it was not already, and by default persists until your script terminates. You can manually uninitialize it by calling `MagickWand.Terminus()` once you're done using MagickWand to free resources; creating another `MagickWand` object will reinitialize it. To check whether the environment is initialized or not, check `MagickWand.IsInstantiated`. You can manually initialize the enivornment by calling `MagickWand.Genesis()`.