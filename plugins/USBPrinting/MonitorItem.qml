// Copyright (c) 2018 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3

import UM 1.2 as UM
import Cura 1.0 as Cura

Component {

    Item {

        Rectangle {
            color: UM.Theme.getColor("main_background")
            anchors.right: parent.right
            width: parent.width * 0.25
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            Cura.PrintMonitor {
                id: printMonitor
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.left: parent.left
                anchors.bottom: footerSeparator.top
            }

            Rectangle {
                id: footerSeparator
                width: parent.width
                height: UM.Theme.getSize("wide_lining").height
                color: UM.Theme.getColor("wide_lining")
                anchors.bottom: monitorButton.top
                anchors.bottomMargin: UM.Theme.getSize("thick_margin").height
            }

            // MonitorButton is actually the bottom footer panel.
            Cura.MonitorButton {
                id: monitorButton
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
            }
        }
    }
}