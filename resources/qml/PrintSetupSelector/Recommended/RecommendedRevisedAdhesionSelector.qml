// Copyright (c) 2018 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4

import UM 1.2 as UM
import Cura 1.0 as Cura


//
//  Adhesion
//
Item {
    id: enableAdhesionRow
    height: childrenRect.height

    property real labelColumnWidth: Math.round(width / 3)
    property var curaRecommendedMode: Cura.RecommendedMode {}

    Cura.IconWithText {
        id: enableAdhesionRowTitle
        anchors.top: parent.top
        anchors.left: parent.left
        source: UM.Theme.getIcon("Adhesion")
        text: catalog.i18nc("@label", "Adhesion")
        font: UM.Theme.getFont("medium")
        width: labelColumnWidth
        iconSize: UM.Theme.getSize("medium_button_icon").width
    }

    Item {
        id: enableAdhesionContainer
        height: adhesionTypeComboBox.height

        anchors {
            left: enableAdhesionRowTitle.right
            right: parent.right
            verticalCenter: enableAdhesionRowTitle.verticalCenter
        }

        Cura.ComboBoxWithOptions {
            id: adhesionTypeComboBox
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            containerStackId: Cura.MachineManager.activeMachine.id
            settingKey: "adhesion_type"
            controlWidth: parent.width - UM.Theme.getSize("default_margin").width
        }
    }
}
