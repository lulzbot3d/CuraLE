// Copyright (c) 2018 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 2.15
import QtQuick.Controls.Styles 1.4

import UM 1.2 as UM
import Cura 1.0 as Cura


//
//  Top/Bottom
//
Item {
    id: topBottomRow
    height: childrenRect.height

    property real labelColumnWidth: Math.round(width / 3)
    property bool alive: Cura.MachineManager.activeMachine != null && Cura.MachineManager.activeStack != null
    property var curaRecommendedMode: Cura.RecommendedMode {}

    Cura.IconWithText {
        id: topBottomRowTitle
        anchors.top: parent.top
        anchors.left: parent.left
        source: UM.Theme.getIcon("PrintTopBottom")
        text: catalog.i18nc("@label", "Top/Bottom Count")
        font: UM.Theme.getFont("medium")
        width: labelColumnWidth
        iconSize: UM.Theme.getSize("medium_button_icon").width

        MouseArea {
            id: topBottomMouseArea
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                base.showTooltip(topBottomRowTitle, Qt.point(-topBottomRowTitle.x - UM.Theme.getSize("thick_margin").width, 0),
                    catalog.i18nc("@label", "Set the number of solid layers that will be generated on the top and bottom of your print. In the dropdown to the right, you can also set the pattern that will be used to create those solid layers."))
            }
            onExited: base.hideTooltip()
        }
    }

    Binding {
        target: topBottomCountSpinBox
        property: "value"
        value: Math.ceil(parseFloat(topBottomThickness.properties.value) / parseFloat(layerHeight.properties.value))
    }

    Item {
        id: topBottomCountContainer
        height: Math.ceil(topBottomCountSpinBox)
        width: Math.round((parent.width - labelColumnWidth) / 2)

        anchors {
            left: topBottomRowTitle.right
            verticalCenter: topBottomRowTitle.verticalCenter
        }

        SpinBox {
            id: topBottomCountSpinBox

            anchors.verticalCenter: parent.verticalCenter

            height: topBottomRowTitle.height
            width: parent.width

            from: 0
            to: 999999
            editable: true
            stepSize: 1

            onValueChanged: {
                let current = Math.ceil(parseFloat(topBottomThickness.properties.value) / parseFloat(layerHeight.properties.value))
                if (current == topBottomCountSpinBox.value) {
                    return
                }

                let layerCountToHeight = topBottomCountSpinBox.value * parseFloat(layerHeight.properties.value)

                var active_mode = UM.Preferences.getValue("cura/active_mode")

                if (active_mode == 0 || active_mode == "simple") {
                    Cura.MachineManager.setSettingForAllExtruders("top_bottom_thickness", "value", layerCountToHeight)
                }
            }
        }

        UM.SettingPropertyProvider {
            id: machineHeight
            containerStackId: alive ? Cura.MachineManager.activeStack.id : null
            key: "machine_height"
            watchedProperties: [ "value" ]
        }

        UM.SettingPropertyProvider {
            id: layerHeight
            containerStackId: alive ? Cura.MachineManager.activeStack.id : null
            key: "layer_height"
            watchedProperties: [ "value" ]
        }

        UM.SettingPropertyProvider {
            id: topBottomThickness
            containerStackId: alive ? Cura.MachineManager.activeStack.id : null
            key: "top_bottom_thickness"
            watchedProperties: [ "value" ]
            storeIndex: 0
        }
    }

    Item {
        id: topBottomPatternContainer
        height: topBottomPatternComboBox.height

        anchors {
            left: topBottomCountContainer.right
            leftMargin: UM.Theme.getSize("thin_margin").width
            right: parent.right
            verticalCenter: topBottomRowTitle.verticalCenter
        }

        Cura.ComboBoxWithOptions {
            id: topBottomPatternComboBox
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            containerStackId: alive ? Cura.MachineManager.activeMachine.id : null
            settingKey: "top_bottom_pattern"
            controlWidth: parent.width
            useInBuiltTooltip: false
        }
    }
}
