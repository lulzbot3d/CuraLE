// Copyright (c) 2023 Fargo Additive Manufacturing Equipment 3D, LLC.
// Cura LE is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4

import UM 1.2 as UM
import Cura 1.0 as Cura


//
//  Z Seam
//
Item {
    id: zSeamRow
    height: childrenRect.height

    property real labelColumnWidth: Math.round(width / 3)

    Cura.IconWithText {
        id: zSeamRowTitle
        anchors.top: parent.top
        anchors.left: parent.left
        source: UM.Theme.getIcon("Zipper")
        text: catalog.i18nc("@label", "Z Seam Alignment")
        font: UM.Theme.getFont("medium")
        width: labelColumnWidth
        iconSize: UM.Theme.getSize("medium_button_icon").width
    }

    Item {
        id: zSeamAlignmentContainer
        height: zSeamAlignmentComboBox.height
        width: {
            if (zSeamPositionContainer.visible) {
                return ((parent.width - labelColumnWidth) / 1.75)
            } else { return (parent.width - labelColumnWidth) }
        }

        anchors {
            left: zSeamRowTitle.right
            verticalCenter: zSeamRowTitle.verticalCenter
        }

        Cura.ComboBoxWithOptions {
            id: zSeamAlignmentComboBox
            containerStackId: Cura.MachineManager.activeMachine.id
            settingKey: "z_seam_type"
            controlWidth: zSeamAlignmentContainer.width
        }
    }

    Binding {
        target: zSeamPositionContainer
        property: "visible"
        value: {
            return (zSeamType.properties.value == "back")
        }
    }

    Item {
        id: zSeamPositionContainer
        height: zSeamPositionComboBox.height

        visible: false

        anchors {
            left: zSeamAlignmentContainer.right
            leftMargin: UM.Theme.getSize("thin_margin").width
            right: parent.right
            verticalCenter: zSeamRowTitle.verticalCenter
        }

        Cura.ComboBoxWithOptions {
            id: zSeamPositionComboBox
            containerStackId: Cura.MachineManager.activeMachine.id
            settingKey: "z_seam_position"
            controlWidth: zSeamPositionContainer.width
        }
    }

    UM.SettingPropertyProvider {
            id: zSeamType
            containerStackId: Cura.MachineManager.activeMachine.id
            key: "z_seam_type"
            watchedProperties: [ "value" ]
    }
}
