Cura LulzBot Edition
====
Cura LulzBot Edition is a re-work of [Cura 4.13 by Ultimaker](https://github.com/Ultimaker/Cura/tree/4.13) with modified tooling code for ease of use with LulzBot brand printers.

This repository consists of the main application which is based on a underlying Uranium framework.

* (On Windows) The log as produced by dxdiag (start -> run -> dxdiag -> save output)
* The Cura GUI log file, located at
  * `%APPDATA%\cura-lulzbot\<Cura LE version>\cura.log` (Windows), or usually `C:\Users\\<your username>\AppData\Roaming\cura-lulzbot\<Cura LE version>\cura-lulzbot.log`
  * `$USER/Library/Application Support/cura-lulzbot/<Cura LE version>/cura-lulzbot.log` (OSX)
  * `$USER/.local/share/cura-lulzbot/<Cura LE version>/cura-lulzbot.log` (Ubuntu/Linux)

For additional support, you could also ask in the #cura channel on FreeNode IRC. For help with development, there is also the #cura-dev channel.

Dependencies
------------
To keep versioning consistent for the build script, forks had been made of most major dependencies. Linked are first the main repository for each given project followed by the repository for the fork used for the LulzBot Edition build.

* [Uranium](https://github.com/Ultimaker/Uranium)
  * [LulzBot Fork](https://gitlab.com/lulzbot3d/cura-le/uranium)

Cura LE is built on top of the Uranium framework.

* [CuraEngine](https://github.com/Ultimaker/CuraEngine)
  * [LulzBot Fork](https://gitlab.com/lulzbot3d/cura-le/cura-engine-le)

This will be needed at runtime to perform the actual slicing.

* [PySerial](https://github.com/pyserial/pyserial)
   * [LulzBot Fork](https://gitlab.com/lulzbot3d/cura-le/pyserial)

Only required for USB printing support.

* [python-zeroconf](https://github.com/jstasiak/python-zeroconf)
  * [LulzBot Fork](https://gitlab.com/lulzbot3d/cura-le/python-zeroconf)

Only required to detect mDNS-enabled printers

Build scripts
-------------
Please check out [curabuild-lulzbot](https://gitlab.com/lulzbot3d/cura-le/curabuild-lulzbot) for detailed building instructions.

License
----------------
Cura and Cura LE are released under the terms of the LGPLv3 or higher. A copy of this license should be included with the software.
