Submitting bug reports
----------------------
<<<<<<< HEAD:contributing.md
Please submit bug reports for all of Cura LulzBot Edition and CuraEngineLE to the [Cura LulzBot Edition repository](https://gitlab.com/lulzbot3d/cura-le/cura-lulzbot/-/issues). Depending on the type of issue, we will usually ask for the CuraLE log or a project file.
=======
Please submit bug reports for all of Cura and CuraEngine to the [Cura repository](https://github.com/Ultimaker/Cura/issues). There will be a template there to fill in. Depending on the type of issue, we will usually ask for the [Cura log](https://github.com/Ultimaker/Cura/wiki/Reporting#cura-log) or a project file.
>>>>>>> ulti-5.6:CONTRIBUTING.md

If a bug report would contain private information, such as a proprietary 3D model, you may also e-mail us. Ask for contact information in the issue.

Requesting features
-------------------
<<<<<<< HEAD:contributing.md
When requesting a feature, please describe clearly what you need and why you think this is valuable to users or what problem it solves. Please make sure that feature requests are relevant to CuraLE as an application, hardware requests for LulzBot printers are better handled by our support team.
=======
When requesting a feature, please describe clearly what you need and why you think this is valuable to users or what problem it solves.

Making pull requests
--------------------
If you want to propose a change to Cura's source code, please create a pull request in the appropriate repository. Since Cura has multiple repositories that influence it, we've listed the most important ones below:
* [Cura](https://github.com/Ultimaker/Cura)
* [Uranium](https://github.com/Ultimaker/Uranium)
* [CuraEngine](https://github.com/Ultimaker/CuraEngine)
* [fdm_materials](https://github.com/Ultimaker/fdm_materials)
* [libArcus](https://github.com/Ultimaker/libArcus)
* [libSavitar](https://github.com/Ultimaker/libSavitar)
* [libCharon](https://github.com/Ultimaker/libCharon)
* [cura-binary-data](https://github.com/Ultimaker/cura-binary-data)) 

If your change requires changes on multiple of these repositories, please link them together so that we know to merge & review them together.

The style guide for code contributions to Cura and other Ultimaker projects can be found [here](https://github.com/Ultimaker/Meta/blob/master/general/generic_code_conventions.md).

Some of these repositories will have automated tests running when you create a pull request, indicated by green check marks or red crosses in the Github web page. If you see a red cross, that means that a test has failed. If the test doesn't fail on the Main branch but does fail on your branch, that indicates that you've probably made a mistake and you need to do that. Click on the cross for more details, or run the test locally by running `cmake . && ctest --verbose`.
>>>>>>> ulti-5.6:CONTRIBUTING.md
