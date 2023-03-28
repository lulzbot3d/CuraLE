// Copyright (c) 2021 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Window 2.1

import UM 1.1 as UM

UM.Dialog
{
    id: base

    //: About dialog title
    title: catalog.i18nc("@title:window The argument is the application name.", "About %1").arg(CuraApplication.applicationDisplayName)

    minimumWidth: 500 * screenScaleFactor
    minimumHeight: 700 * screenScaleFactor
    width: minimumWidth
    height: minimumHeight

    Rectangle
    {
        id: header
        width: parent.width + 2 * margin // margin from Dialog.qml
        height: childrenRect.height + topPadding

        anchors.top: parent.top
        anchors.topMargin: -margin
        anchors.horizontalCenter: parent.horizontalCenter

        property real topPadding: UM.Theme.getSize("wide_margin").height

        color: UM.Theme.getColor("main_window_header_background")

        Image
        {
            id: logo
            width: (base.minimumWidth * 0.85) | 0
            height: (width * (UM.Theme.getSize("logo").height / UM.Theme.getSize("logo").width)) | 0
            source: UM.Theme.getImage("logo")
            sourceSize.width: width
            sourceSize.height: height
            fillMode: Image.PreserveAspectFit

            anchors.top: parent.top
            anchors.topMargin: parent.topPadding
            anchors.horizontalCenter: parent.horizontalCenter

            UM.I18nCatalog{id: catalog; name: "cura"}
        }

        Label
        {
            id: version

            text: catalog.i18nc("@label","version: %1").arg(UM.Application.version)
            font: UM.Theme.getFont("large_bold")
            color: UM.Theme.getColor("button_text")
            anchors.right : logo.right
            anchors.top: logo.bottom
            anchors.topMargin: (UM.Theme.getSize("default_margin").height / 2) | 0
        }
    }

    Label
    {
        id: description
        width: parent.width

        //: About dialog application description
        text: catalog.i18nc("@label","End-to-end solution for fused filament 3D printing.")
        font: UM.Theme.getFont("system")
        wrapMode: Text.WordWrap
        anchors.top: header.bottom
        anchors.topMargin: UM.Theme.getSize("default_margin").height
    }

    Label
    {
        id: creditsNotes
        width: parent.width

        //: About dialog application author note
        text: catalog.i18nc("@info:credit","Cura LulzBot Edition is a derivative work (developed by Fargo Additive Manufacturing Equipment 3D) of Cura, developed by Ultimaker B.V., modified specifically for use with LulzBot brand printers in cooperation with the community.\n\nCura LulzBot Edition proudly uses the following open source projects:")
        font: UM.Theme.getFont("system")
        wrapMode: Text.WordWrap
        anchors.top: description.bottom
        anchors.topMargin: UM.Theme.getSize("default_margin").height
    }

    ScrollView
    {
        id: credits
        anchors.top: creditsNotes.bottom
        anchors.topMargin: UM.Theme.getSize("default_margin").height

        width: parent.width
        height: base.height - y - (2 * UM.Theme.getSize("default_margin").height + closeButton.height)

        ListView
        {
            id: projectsList

            width: parent.width

            delegate: Row
            {
                Label
                {
                    text: "<a href='%1' title='%2'>%2</a>".arg(model.url).arg(model.name)
                    width: (projectsList.width * 0.25) | 0
                    elide: Text.ElideRight
                    onLinkActivated: Qt.openUrlExternally(link)
                }
                Label
                {
                    text: model.description
                    elide: Text.ElideRight
                    width: (projectsList.width * 0.6) | 0
                }
                Label
                {
                    text: model.license
                    elide: Text.ElideRight
                    width: (projectsList.width * 0.15) | 0
                }
            }
            model: ListModel
            {
                id: projectsModel
            }
            Component.onCompleted:
            {
                projectsModel.append({ name: "Cura LE", description: catalog.i18nc("@label", "Graphical user interface"), license: "LGPLv3", url: "https://gitlab.com/lulzbot3d/cura-le/cura-lulzbot" });
                projectsModel.append({ name: "Uranium", description: catalog.i18nc("@label", "Application framework"), license: "LGPLv3", url: "https://gitlab.com/lulzbot3d/cura-le/uranium" });
                projectsModel.append({ name: "CuraEngine LE", description: catalog.i18nc("@label", "G-code generator"), license: "AGPLv3", url: "https://gitlab.com/lulzbot3d/cura-le/cura-engine-le" });
                projectsModel.append({ name: "libArcus", description: catalog.i18nc("@label", "Interprocess communication library"), license: "LGPLv3", url: "https://gitlab.com/lulzbot3d/cura-le/libarcus" });

                projectsModel.append({ name: "Python", description: catalog.i18nc("@label", "Programming language"), license: "Python", url: "https://www.python.org/downloads/release/python-3810/" });
                projectsModel.append({ name: "Qt5", description: catalog.i18nc("@label", "GUI framework"), license: "LGPLv3", url: "https://doc.qt.io/qt-5.15/" });
                projectsModel.append({ name: "PyQt", description: catalog.i18nc("@label", "GUI framework bindings"), license: "GPL", url: "https://gitlab.com/lulzbot3d/cura-le/pyqt5_gpl" });
                projectsModel.append({ name: "SIP", description: catalog.i18nc("@label", "C/C++ Binding library"), license: "GPLv2 & GPLv3 & SIP", url: "https://riverbankcomputing.com/software/sip" });
                projectsModel.append({ name: "Protobuf", description: catalog.i18nc("@label", "Data interchange format"), license: "BSD", url: "https://developers.google.com/protocol-buffers" });
                projectsModel.append({ name: "SciPy", description: catalog.i18nc("@label", "Support library for scientific computing"), license: "BSD-new", url: "https://github.com/scipy/scipy/tree/v1.8.0rc2" });
                projectsModel.append({ name: "NumPy", description: catalog.i18nc("@label", "Support library for faster math"), license: "BSD", url: "https://github.com/numpy/numpy/tree/v1.21.5" });
                projectsModel.append({ name: "NumPy-STL", description: catalog.i18nc("@label", "Support library for handling STL files"), license: "BSD", url: "https://github.com/WoLpH/numpy-stl/tree/v2.10.1" });
                projectsModel.append({ name: "Trimesh", description: catalog.i18nc("@label", "Support library for handling triangular meshes"), license: "MIT", url: "https://github.com/mikedh/trimesh/blob/3.9.36/docs/index.rst" });
                projectsModel.append({ name: "libSavitar", description: catalog.i18nc("@label", "Support library for handling 3MF files"), license: "LGPLv3", url: "https://gitlab.com/lulzbot3d/cura-le/libsavitar/-/tree/main" });
                projectsModel.append({ name: "libCharon", description: catalog.i18nc("@label", "Support library for file metadata and streaming"), license: "LGPLv3", url: "https://gitlab.com/lulzbot3d/cura-le/libcharon" });
                projectsModel.append({ name: "PySerial", description: catalog.i18nc("@label", "Serial communication library"), license: "PSF and BSD-3-Clause", url: "https://github.com/pyserial/pyserial/tree/v3.4" });
                projectsModel.append({ name: "python-zeroconf", description: catalog.i18nc("@label", "ZeroConf discovery library"), license: "LGPL", url: "https://github.com/python-zeroconf/python-zeroconf/tree/0.31.0" });
                projectsModel.append({ name: "Clipper", description: catalog.i18nc("@label", "Polygon clipping library"), license: "Boost", url: "http://www.angusj.com/delphi/clipper.php" });
                projectsModel.append({ name: "Pyclipper", description: catalog.i18nc("@label", "Python bindings for Clipper"), license: "MIT", url: "https://github.com/fonttools/pyclipper/tree/1.3.0.post2" });
                projectsModel.append({ name: "mypy", description: catalog.i18nc("@Label", "Static type checker for Python"), license: "MIT", url: "https://github.com/python/mypy/tree/v0.740" });
                projectsModel.append({ name: "certifi", description: catalog.i18nc("@Label", "Root Certificates for validating SSL trustworthiness"), license: "MPL", url: "https://github.com/certifi/python-certifi/tree/2019.11.28" });
                projectsModel.append({ name: "cryptography", description: catalog.i18nc("@Label", "Root Certificates for validating SSL trustworthiness"), license: "APACHE and BSD", url: "https://github.com/pyca/cryptography/tree/3.4.8" });
                projectsModel.append({ name: "Sentry", description: catalog.i18nc("@Label", "Python Error tracking library"), license: "MIT", url: "https://github.com/getsentry/sentry-python/tree/0.13.5" });
                projectsModel.append({ name: "libnest2d", description: catalog.i18nc("@label", "Polygon packing library, developed by Prusa Research"), license: "LGPL", url: "https://github.com/tamasmeszaros/libnest2d" });
                projectsModel.append({ name: "pynest2d", description: catalog.i18nc("@label", "Python bindings for libnest2d"), license: "LGPL", url: "https://github.com/Ultimaker/pynest2d" });
                projectsModel.append({ name: "keyring", description: catalog.i18nc("@label", "Support library for system keyring access"), license: "MIT", url: "https://github.com/jaraco/keyring/tree/v23.0.1" });
                projectsModel.append({ name: "pywin32", description: catalog.i18nc("@label", "Python extensions for Microsoft Windows"), license: "PSF", url: "https://github.com/mhammond/pywin32/tree/b303" });
                projectsModel.append({ name: "Noto Sans", description: catalog.i18nc("@label", "Font"), license: "SIL OFL 1.1", url: "https://www.google.com/get/noto/" });
                projectsModel.append({ name: "Font-Awesome-SVG-PNG", description: catalog.i18nc("@label", "SVG icons"), license: "MIT", url: "https://github.com/encharm/Font-Awesome-SVG-PNG" });
                projectsModel.append({ name: "AppImageKit", description: catalog.i18nc("@label", "Linux cross-distribution application deployment"), license: "MIT", url: "https://github.com/AppImage/AppImageKit/releases/tag/12" });
            }
        }
    }

    rightButtons: Button
    {
        //: Close about dialog button
        id: closeButton
        text: catalog.i18nc("@action:button","Close");

        onClicked: base.visible = false;
    }
}
