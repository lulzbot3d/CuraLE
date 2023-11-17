// Copyright (c) 2023 Fargo Additive Manufacturing Equipment 3D, LLC
// Cura LE is released under the terms of the LGPLv3 or higher.

import QtQuick 2.11
import QtQuick.Controls 1.1
import UM 1.2 as UM

Item {
    id: filamentChangeIconItem

    implicitWidth: UM.Theme.getSize("extruder_icon").width
    implicitHeight: UM.Theme.getSize("extruder_icon").height

    property bool checked: true
    property alias iconSize: mainIcon.sourceSize
    property string iconVariant: "default"

    Item {
        anchors.fill: parent

        UM.RecolorImage {
            id: mainIcon
            anchors.fill: parent
            sourceSize: UM.Theme.getSize("extruder_icon", iconVariant)
            color: UM.Theme.getColor("icon")

            source: UM.Theme.getIcon("Spool")
        }
    }
}
