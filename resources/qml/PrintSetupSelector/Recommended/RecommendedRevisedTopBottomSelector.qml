// Copyright (c) 2018 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4

import UM 1.2 as UM
import Cura 1.0 as Cura


//
//  Top/Bottom
//
Item {
    id: topBottomPatternRow
    height: childrenRect.height

    property real labelColumnWidth: Math.round(width / 3)
    property var curaRecommendedMode: Cura.RecommendedMode {}

    Cura.IconWithText {
        id: topBottomPatternRowTitle
        anchors.top: parent.top
        anchors.left: parent.left
        source: UM.Theme.getIcon("PrintTopBottom")
        text: catalog.i18nc("@label", "Top/Bottom Pattern")
        font: UM.Theme.getFont("medium")
        width: labelColumnWidth
        iconSize: UM.Theme.getSize("medium_button_icon").width
    }

    Item {
        id: topBottomPatternContainer
        height: topBottomPatternComboBox.height

        anchors {
            left: topBottomPatternRowTitle.right
            right: parent.right
            verticalCenter: topBottomPatternRowTitle.verticalCenter
        }

        Cura.ComboBoxWithOptions {
            id: topBottomPatternComboBox
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            containerStackId: Cura.MachineManager.activeMachine.id
            settingKey: "top_bottom_pattern"
            controlWidth: parent.width
        }
    }
}
