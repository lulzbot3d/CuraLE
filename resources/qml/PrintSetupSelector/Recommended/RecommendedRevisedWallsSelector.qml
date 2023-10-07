// Copyright (c) 2018 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 1.4
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

    Binding {
        target: wallCountSlider
        property: "value"
        value: parseInt(wallCount.properties.value)
    }

    Cura.IconWithText {
        id: wallCountRowTitle
        anchors.top: parent.top
        anchors.left: parent.left
        source: UM.Theme.getIcon("PrintShell")
        text: catalog.i18nc("@label", "Wall Count")
        font: UM.Theme.getFont("medium")
        width: labelColumnWidth
        iconSize: UM.Theme.getSize("medium_button_icon").width
    }

    Item {
        id: wallCountContainer
        height: wallCountSlider.height

        anchors {
            left: wallCountRowTitle.right
            right: parent.right
            verticalCenter: wallCountRowTitle.verticalCenter
        }

        Slider {
            id: wallCountSlider

            width: parent.width
            height: UM.Theme.getSize("print_setup_slider_handle").height // The handle is the widest element of the slider

            minimumValue: 1
            maximumValue: 5
            stepSize: 1
            tickmarksEnabled: true
            property int tickmarkSpacing: 1
            wheelEnabled: false

            // set initial value from stack
            value: parseInt(wallCount.properties.value)

            style: UM.Theme.styles.setup_selector_slider

            onValueChanged: {
                // Don't round the value if it's already the same
                if (parseInt(wallCount.properties.value) == wallCountSlider.value) {
                    return
                }

                // Update value only if the Recommended mode is Active,
                // Otherwise if I change the value in the Custom mode the Recommended view will try to repeat
                // same operation
                var active_mode = UM.Preferences.getValue("cura/active_mode")

                if (active_mode == 0 || active_mode == "simple") {
                    Cura.MachineManager.setSettingForAllExtruders("wall_line_count", "value", wallCountSlider.value)
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

    Label {
        id: zSeamAlignmentLabel
        anchors {
            top: zSeamAlignmentContainer.top
            bottom: zSeamAlignmentContainer.bottom
            left: parent.left
            leftMargin: UM.Theme.getSize("wide_margin").width
            right: zSeamAlignmentContainer.left
        }
        text: catalog.i18nc("@label", "Z Seam Alignment")
        font: UM.Theme.getFont("small")
        renderType: Text.NativeRendering
        color: UM.Theme.getColor("text")
        verticalAlignment: Text.AlignVCenter
    }

    Item {
        id: zSeamAlignmentContainer
        height: zSeamAlignmentComboBox.height

        anchors {
            top: wallCountContainer.bottom
            topMargin: UM.Theme.getSize("thick_margin").height
            left: wallCountContainer.left
            right: parent.right
        }

        Cura.ComboBoxWithOptions {
            id: zSeamAlignmentComboBox
            containerStackId: Cura.MachineManager.activeMachine.id
            settingKey: "z_seam_type"
            controlWidth: zSeamAlignmentContainer.width
        }
    }

    Label {
        id: zSeamPositionLabel
        anchors {
            top: zSeamPositionContainer.top
            bottom: zSeamPositionContainer.bottom
            left: parent.left
            leftMargin: UM.Theme.getSize("wide_margin").width
            right: zSeamPositionContainer.left
        }
        text: catalog.i18nc("@label", "Z Seam Position")
        font: UM.Theme.getFont("small")
        renderType: Text.NativeRendering
        color: UM.Theme.getColor("text")
        verticalAlignment: Text.AlignVCenter
    }

    Item {
        id: zSeamPositionContainer
        height: visible ? zSeamPositionComboBox.height : 0

        anchors {
            top: zSeamAlignmentContainer.bottom
            topMargin: 5
            left: wallCountContainer.left
            right: parent.right
        }

        Cura.ComboBoxWithOptions {
            id: zSeamPositionComboBox
            containerStackId: Cura.MachineManager.activeMachine.id
            settingKey: "z_seam_position"
            controlWidth: zSeamPositionContainer.width
        }
    }
}
