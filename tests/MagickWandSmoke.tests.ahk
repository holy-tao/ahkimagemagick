#Requires AutoHotkey v2.0

#Include ./YUnit/Yunit.ahk
#Include ./YUnit/Stdout.ahk
#Include ./YUnit/Assert.ahk

#Include ../Wand/MagickWand.ahk

class MagickWandSmokeTests {
    Version_Smoke() {
        Yunit.Assert(!IsSpace(MagickWand.Version))
        Yunit.Assert(!IsSpace(MagickWand.LibVersion))
    }

    IsInstantiated_Smoke() {
        YUnit.Assert(MagickWand.IsInstantiated)
    }

    ReadImage_WithFilePath_ReadsImage() {
        wand := MagickWand()
        wand.ReadImage("logo.png")
        Assert.Equals(wand.ImageFilename, "logo.png")
    }

    ReadImage_WithBuffer_ReadsImage() {
        wand := MagickWand()
        imgBuf := FileRead("logo.png", "raw")
        wand.ReadImage(imgBuf)

        Assert.Equals(wand.ImageFilename, "") ; Not accessible when read from memory
        Assert.Equals(wand.ImageFormat, "PNG")
    }

    WriteImage_WithFilePath_WritesImage() {
        wand := MagickWand()
        wand.ReadImage("logo.png")
        wand.WriteImage("logo.jpg")

        Yunit.Assert(FileExist("logo.jpg"))
        FileDelete("logo.jpg")
    }

    GetImageBlob_GetsImageBlob() {
        wand := MagickWand()
        imgBuf := FileRead("logo.png", "raw")
        wand.ReadImage(imgBuf)

        wand.ImageFormat := "png"
        blob := wand.GetImageBlob()

        Assert.IsType(blob, MagickBlob)
        ; TODO check image similarity? Maybe with ImageMagick?
    }

    FilePath_Set_SetsFilePath() {
        wand := MagickWand()
        wand.ReadImage("logo.png")

        wand.ImageFilename := A_ThisFunc "logo.jpg"
        wand.WriteImage()

        YUnit.Assert(FileExist(A_ThisFunc "logo.jpg"))
        FileDelete(A_ThisFunc "logo.jpg")
    }

    ImageArtifacts_GetSet_Smoke() {
        wand := MagickWand()
        wand.ReadImage("logo.png")

        wand.ImageArtifacts["testkey"] := "testvalue"

        Assert.Equals(wand.ImageArtifacts["testkey"], "testvalue")
    }

    GetImageArtifacts_Smoke() {
        wand := MagickWand()
        wand.ReadImage("logo.png")

        wand.ImageArtifacts["testkey"] := "testvalue"

        Assert.Equals(wand.GetImageArtifacts()[1], "testkey")
    }

    ImageArtifacts_Get_WithKeyNotFound_ReturnsEmptyString() {
        wand := MagickWand()
        wand.ReadImage("logo.png")

        Assert.Equals(wand.ImageArtifacts["ooglyboogly"], "")
    }

    ImageArtifacts_Set_WithEmptyString_DeletesProperty() {
        wand := MagickWand()
        wand.ReadImage("logo.png")

        wand.ImageArtifacts["testkey"] := "testvalue"
        wand.ImageArtifacts["testkey"] := ""

        Assert.Equals(wand.ImageArtifacts["testkey"], "")
        Assert.Equals(wand.GetImageArtifacts().Length, 0)
    }

    HomeURL_Smoke() {
        wand := MagickWand()

        SplitPath(wand.HomeUrl, &outName)

        Assert.Equals(outName, "index.html")
    }

    ImageProperty_Get_Smoke() {
        wand := MagickWand()

        wand.ReadImage("logo.png")

        Yunit.Assert(!IsSpace(wand.ImageProperties["date:create"]))
        Yunit.Assert(IsSpace(wand.ImageProperties["not a property"]))
    }

    GetImageProperties_Smoke() {
        wand := MagickWand()

        wand.ReadImage("logo.png")

        Yunit.Assert(wand.GetImageProperties().Length > 0)
    }

    IteratorIndex_Smoke() {
        wand := MagickWand()

        wand.ReadImage("logo.png")

        Assert.Equals(wand.IteratorIndex, 0)
        Assert.Equals(wand.HasNext, false)
        Assert.Equals(wand.HasPrevious, false)
    }

    SetFirstLastImage_Smoke() {
        wand := MagickWand()

        wand.ReadImage("logo.png")
        wand.ReadImage("logo.png")
        wand.ReadImage("logo.png")

        wand.SetLastIterator()
        Assert.Equals(wand.IteratorIndex, 2)
        Assert.Equals(wand.HasPrevious, true)

        wand.SetFirstIterator()
        Assert.Equals(wand.IteratorIndex, 0)
        Assert.Equals(wand.HasNext, true)
    }

    Enum_EnumeratesImages() {
        wand := MagickWand()

        wand.ReadImage("logo.png")
        wand.ReadImage("logo.png")
        wand.ReadImage("logo.png")

        ; Ensure we reset the iterator and make it through everything in the wand
        wand.IteratorIndex := 1

        loopCount := 0
        for(index, image in wand) {
            Assert.Equals(index, A_Index - 1)
            Yunit.Assert(image != 0)
            loopCount++
        }

        Assert.Equals(loopCount, 3)
        Assert.Equals(wand.IteratorIndex, 2)
        Assert.Equals(wand.HasPrevious, true)
        Assert.Equals(wand.HasNext, false)
    }
}

if(A_ScriptName == "MagickWandSmoke.tests.ahk") {
    Yunit.Use(YUnitStdOut).Test(MagickWandSmokeTests)
}