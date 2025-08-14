// Copyright (c) 2018 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4

import UM 1.2 as UM
import Cura 1.0 as Cura


//
//  Print Sequence
//
Item {
    id: printSequenceRow
    height: childrenRect.height

    property real labelColumnWidth: Math.round(width / 3)
    property bool alive: Cura.MachineManager.activeMachine != null
    property var curaRecommendedMode: Cura.RecommendedMode {}

    Cura.IconWithText {
        id: printSequenceRowTitle
        anchors.top: parent.top
        anchors.left: parent.left
        source: UM.Theme.getIcon("FoodBeverages")
        text: catalog.i18nc("@label", "Print Sequence")
        font: UM.Theme.getFont("medium")
        width: labelColumnWidth
        iconSize: UM.Theme.getSize("medium_button_icon").width

        MouseArea {
            id: printSequenceMouseArea
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                base.showTooltip(printSequenceRowTitle, Qt.point(-printSequenceRowTitle.x - UM.Theme.getSize("thick_margin").width, 0),
                    catalog.i18nc("@label", '<h3>FOR ADVANCED USE ONLY</h3><h3>Set whether to print all parts on the build plate "All at Once" or "One at a Time". \
                    Note that if you print parts "One at a Time", special care should be taken to ensure the Tool Head does not \
                    run into pieces that have been completed. This can be done by previewing the gcode and ensuring parts print \
                    in the order intended.</h3>'))
            }
            onExited: base.hideTooltip()
        }
    }

    Item {
        id: printSequenceContainer
        height: printSequenceComboBox.height

        anchors {
            left: printSequenceRowTitle.right
            right: parent.right
            verticalCenter: printSequenceRowTitle.verticalCenter
        }

        Cura.ComboBoxWithOptions {
            id: printSequenceComboBox
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            containerStackId: alive ? Cura.MachineManager.activeMachine.id : null
            settingKey: "print_sequence"
            controlWidth: parent.width
            useInBuiltTooltip: false
        }
    }
}
