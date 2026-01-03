#Requires AutoHotkey v2.0

#Include ./YUnit/YUnit.ahk
#Include ./YUnit/ResultCounter.ahk
#Include ./YUnit/JUnit.ahk
#Include ./YUnit/Stdout.ahk

#Include ./MagickWandSmoke.tests.ahk
#Include ./MagickWandImageManipulationSmoke.tests.ahk

FileAppend("Starting unit tests using ImageMagick version " MagickWand.LibVersion "`n", "*")

YUnit.Use(YunitResultCounter, YUnitJUnit, YUnitStdOut).Test(
	MagickWandSmokeTests,
	MagickWandImageManipulationTests
)

Exit(-YunitResultCounter.failures)