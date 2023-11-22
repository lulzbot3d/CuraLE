// Copyright (c) 2023 Fargo Additive Manufacturing Equipment 3D, LLC
// Cura LE is released under the terms of the LGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 2.3

import UM 1.2 as UM
import Cura 1.0 as Cura

UM.PointingRectangle {
        id: panelBorder

        property alias panelVisible: panel.visible

        //target: Qt.point(parent.width, Math.round(UM.Theme.getSize("button").height / 2))
        arrowSize: UM.Theme.getSize("default_arrow").width

        width: panel.visible ? panel.width + (2 * UM.Theme.getSize("default_margin").width) : 0
        height: panel.visible ? panel.height + (2 * UM.Theme.getSize("default_margin").height) : 0

        opacity: panel.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 100 } }


        color: UM.Theme.getColor("tool_panel_background")
        borderColor: UM.Theme.getColor("lining")
        borderWidth: UM.Theme.getSize("default_lining").width

        MouseArea { //Catch all mouse events (so scene doesn't handle them)
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onWheel: wheel.accepted = true
        }

        FilamentChangePanelContents {
            id: panel

            visible: base.checked

            x: UM.Theme.getSize("default_margin").width
            y: UM.Theme.getSize("default_margin").height
        }
    }