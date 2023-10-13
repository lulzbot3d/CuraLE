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
    property bool alive: Cura.MachineManager.activeStack != null

    Cura.IconWithText {
        id: wallCountRowTitle
        anchors.top: parent.top
        anchors.left: parent.left
        source: UM.Theme.getIcon("PrintWalls")
        text: catalog.i18nc("@label", "Wall Count")
        font: UM.Theme.getFont("medium")
        width: labelColumnWidth
        iconSize: UM.Theme.getSize("medium_button_icon").width

        MouseArea {
            id: wallCountMouseArea
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                base.showTooltip(wallCountRowTitle, Qt.point(-wallCountRowTitle.x - UM.Theme.getSize("thick_margin").width, 0),
                    catalog.i18nc("@label", "Set the number of solid walls that will be generated on the sides of your print. This number plays a large factor in the overall strength of your part."))
            }
            onExited: base.hideTooltip()
        }
    }

    Binding {
        target: wallCountSpinBox
        property: "value"
        value: parseInt(wallCount.properties.value)
    }

    Item {
        id: wallCountContainer
        height: Math.ceil(wallCountSpinBox)
        width: Math.round((parent.width - labelColumnWidth) / 2)

        anchors {
            left: wallCountRowTitle.right
            verticalCenter: wallCountRowTitle.verticalCenter
        }

        SpinBox {
            id: wallCountSpinBox

            anchors.verticalCenter: parent.verticalCenter

            height: wallCountRowTitle.height
            width: parent.width

            from: 0
            to: 999999
            editable: true
            stepSize: 1

            value: parseInt(wallCount.properties.value)

            onValueChanged: {
                var current = parseInt(wallCount.properties.value)
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
            containerStackId: alive ? Cura.MachineManager.activeStack.id : null
            key: "wall_line_count"
            watchedProperties: [ "value" ]
            storeIndex: 0
        }
    }
}
