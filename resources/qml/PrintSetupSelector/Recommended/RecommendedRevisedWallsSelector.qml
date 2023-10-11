// Copyright (c) 2018 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 2.15
import QtQuick.Controls.Styles 1.4

import UM 1.2 as UM
import Cura 1.0 as Cura


//
//  Walls
//
Item {
    id: wallCountRow
    height: childrenRect.height

    property real labelColumnWidth: Math.round(width / 3)

    // Binding {
    //     target: wallCountSlider
    //     property: "value"
    //     value: parseInt(wallCount.properties.value) - wallCountSlider.allowedMinimum
    // }

    Cura.IconWithText {
        id: wallCountRowTitle
        anchors.top: parent.top
        anchors.left: parent.left
        source: UM.Theme.getIcon("PrintWalls")
        text: catalog.i18nc("@label", "Wall Count")
        font: UM.Theme.getFont("medium")
        width: labelColumnWidth
        iconSize: UM.Theme.getSize("medium_button_icon").width
    }

    Item {
        id: wallCountContainer
        height: wallCountSpinBox

        anchors {
            left: wallCountRowTitle.right
            right: parent.right
            verticalCenter: wallCountRowTitle.verticalCenter
        }

        SpinBox {
            id: wallCountSpinBox

            anchors.verticalCenter: parent.verticalCenter

            height: wallCountRowTitle.height
            width: parent.width

            from: 0
            to: 10
            stepSize: 1

            value: parseInt(wallCount.properties.value)

            onValueChanged: {
                current = parseInt(wallCount.properties.value)
                if (current == wallCountSpinBox.value || current > wallCountSpinBox.to) {
                    return
                }

                var active_mode = UM.Preferences.getValue("cura/active_mode")

                if (active_mode == 0 || active_mode == "simple") {
                    Cura.MachineManager.setSettingForAllExtruders("wall_line_count", "value", wallCountSpinBox.value)
                }
            }
        }

        UM.SettingPropertyProvider {
            id: wallCount
            containerStackId: Cura.MachineManager.activeStack.id
            key: "wall_line_count"
            watchedProperties: [ "value" ]
            storeIndex: 0
        }
    }
}
