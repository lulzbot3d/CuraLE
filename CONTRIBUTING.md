# Contributing

## Submitting bug reports

Please submit bug reports for all of Cura LulzBot Edition and CuraEngineLE to the [Cura LulzBot Edition repository](https://github.com/lulzbot3d/CuraLE/issues). Depending on the type of issue, we will usually ask for the CuraLE log or a project file.

## Requesting features

### Making pull requests

If you want to propose a change to Cura's source code, please create a pull request in the appropriate repository.

Since CuraLE has multiple repositories that influence it, we've listed the most important ones below:

* [CuraLE](https://github.com/lulzbot3d/CuraLE)
* [UraniumLE](https://github.com/lulzbot3d/UraniumLE)
* [CuraEngineLE](https://github.com/lulzbot3d/CuraEngineLE)
<!--* [FDM_MaterialsLE](https://github.com/lulzbot3d/FDM_MaterialsLE)-->
* [libArcusLE](https://github.com/lulzbot3d/libArcusLE)
* [libSavitarLE](https://github.com/lulzbot3d/libSavitarLE)
<!--* [libCharonLE](https://github.com/lulzbot3d/libCharonLE)-->
* [CuraLE_Binary_Data](https://github.com/lulzbot3d/CuraLE_Binary_Data)

If your change requires changes on multiple of these repositories, please link them together so that we know to merge & review them together.

The style guide for code contributions to Cura and other Ultimaker projects can be found [here](https://github.com/Ultimaker/Meta/blob/master/general/generic_code_conventions.md).

Some of these repositories will have automated tests running when you create a pull request, indicated by green check marks or red crosses in the Github web page. If you see a red cross, that means that a test has failed. If the test doesn't fail on the Main branch but does fail on your branch, that indicates that you've probably made a mistake and you need to do that. Click on the cross for more details, or run the test locally by running `cmake . && ctest --verbose`.
