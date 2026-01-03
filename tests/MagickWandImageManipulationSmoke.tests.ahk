#Requires AutoHotkey v2.0

#Include ./YUnit/Yunit.ahk
#Include ./YUnit/Stdout.ahk
#Include ./YUnit/Assert.ahk

#Include ../Wand/MagickWand.ahk
#Include ../Wand/PixelWand.ahk

#Include ../Wand/Enums/NoiseType.ahk
#Include ../Wand/Enums/AutoThresholdMethod.ahk
#Include ../Wand/Enums/CompositeOperator.ahk

class MagickWandImageManipulationTests {

    AdaptiveBlur_Smoke() {
        wand := MagickWand()

        wand.ReadImage("logo.png")
        wand.AdaptiveBlur(5, 2)
        wand.WriteImage(A_ThisFunc ".png")

        YUnit.Assert(FileExist(A_ThisFunc ".png"))
    }

    AdaptiveResize_Smoke() {
        wand := MagickWand()

        wand.ReadImage("logo.png")
        wand.AdaptiveResize(400, 400)
        wand.WriteImage(A_ThisFunc ".png")

        YUnit.Assert(FileExist(A_ThisFunc ".png"))
    }

    AdaptiveSharpen_Smoke() {
        wand := MagickWand()

        wand.ReadImage("logo.png")
        wand.AdaptiveSharpen(0, 4.5)
        wand.WriteImage(A_ThisFunc ".png")

        YUnit.Assert(FileExist(A_ThisFunc ".png"))
    }

    AdaptiveThreshold_Smoke() {
        wand := MagickWand()

        wand.ReadImage("logo.png")
        wand.AdaptiveThreshold(2, 4, 2)
        wand.WriteImage(A_ThisFunc ".png")

        YUnit.Assert(FileExist(A_ThisFunc ".png"))
    }

    AddNoise_Smoke() {
        wand := MagickWand()

        wand.ReadImage("logo.png")
        wand.AddNoise(NoiseType.Random, 1.0)
        wand.WriteImage(A_ThisFunc ".png")

        YUnit.Assert(FileExist(A_ThisFunc ".png"))
    }

    AppendImages_Smoke() {
        /** 
         * @type {MagickWand} 
         * */
        wand := MagickWand()

        wand.ReadImage("logo.png")
        wand.ReadImage("logo.png")
        wand.AddNoise(NoiseType.Laplacian, 1.0)
        wand.ReadImage("logo.png")

        wand.SetFirstIterator()
        appendWand := wand.AppendImages(true)

        ;TODO check append wand image length / width

        Assert.IsType(appendWand, MagickWand)
        appendWand.WriteImage(A_ThisFunc ".png")
        YUnit.Assert(FileExist(A_ThisFunc ".png"))
    }

    AutoGamma_Smoke() {
        wand := MagickWand()

        wand.ReadImage("logo.png")
        wand.AutoGamma()
        wand.WriteImage(A_ThisFunc ".png")

        YUnit.Assert(FileExist(A_ThisFunc ".png"))
    }

    AutoLevel_Smoke() {
        wand := MagickWand()

        wand.ReadImage("logo.png")
        wand.AutoLevel()
        wand.WriteImage(A_ThisFunc ".png")

        YUnit.Assert(FileExist(A_ThisFunc ".png"))
    }

    AutoOrient_Smoke() {
        wand := MagickWand()

        wand.ReadImage("logo.png")
        wand.AutoOrient()
        wand.WriteImage(A_ThisFunc ".png")

        YUnit.Assert(FileExist(A_ThisFunc ".png"))
    }

    AutoThreshold_Smoke() {
        wand := MagickWand()

        wand.ReadImage("logo.png")
        wand.AutoThreshold(AutoThresholdMethod.OTSU)
        wand.WriteImage(A_ThisFunc ".png")

        YUnit.Assert(FileExist(A_ThisFunc ".png"))
    }

    BilateralBlur_Smoke() {
        /** 
         * @type {MagickWand} 
         * */
        wand := MagickWand()

        wand.ReadImage("logo.png")
        wand.BilateralBlur(2.5, 1, 5.0, 2)

        wand.WriteImage(A_ThisFunc ".png")

        YUnit.Assert(FileExist(A_ThisFunc ".png"))
    }

    BlueShift_Smoke() {
        wand := MagickWand()

        wand.ReadImage("logo.png")
        wand.AutoThreshold(AutoThresholdMethod.OTSU)
        wand.WriteImage(A_ThisFunc ".png")

        YUnit.Assert(FileExist(A_ThisFunc ".png"))
    }

    Border_Smoke() {
        wand := MagickWand()

        wand.ReadImage("logo.png")
        wand.Border(PixelWand("#e60eb7"), 4, 4, CompositeOperator.Over)
        wand.WriteImage(A_ThisFunc ".png")

        YUnit.Assert(FileExist(A_ThisFunc ".png"))
    }

    BrightnessContrast_Smoke() {
        wand := MagickWand()

        wand.ReadImage("logo.png")
        wand.BrightnessContrast(10.0, -50)
        wand.WriteImage(A_ThisFunc ".png")

        YUnit.Assert(FileExist(A_ThisFunc ".png"))
    }

    CannyEdge_Smoke() {
        wand := MagickWand()

        wand.ReadImage("logo.png")
        wand.CannyEdge(2.5, 1, .5, .5)
        wand.WriteImage(A_ThisFunc ".png")

        YUnit.Assert(FileExist(A_ThisFunc ".png"))
    }

    ChannelFx_Smoke() {
        wand := MagickWand()

        wand.ReadImage("logo.png")
        outWand := wand.ChannelFx("red; green; blue")

        Assert.IsType(outWand, MagickWand)
        outWand.SetLastIterator()
        Assert.Equals(outWand.IteratorIndex, 2)
    }

    Charcoal_Smoke() {
            wand := MagickWand()

        wand.ReadImage("logo.png")
        wand.Charcoal(2.5, 1)
        wand.WriteImage(A_ThisFunc ".png")

        YUnit.Assert(FileExist(A_ThisFunc ".png"))
    }
}

if(A_ScriptName == "MagickWandImageManipulationSmoke.tests.ahk") {
    Yunit.Use(YUnitStdOut).Test(MagickWandImageManipulationTests)
}