// Copyright (c) 2022 UltiMaker
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Layouts 1.3

import UM 1.5 as UM
import Cura 1.7 as Cura


Item {
    id: enableAdhesionRow
    height: childrenRect.height

    property real labelColumnWidth: Math.round(width / 3)
    property bool alive: Cura.MachineManager.activeMachine != null
    property var curaRecommendedMode: Cura.RecommendedMode {}

    Cura.IconWithText {
        id: enableAdhesionRowTitle
        anchors.top: parent.top
        anchors.left: parent.left
        source: UM.Theme.getIcon("Adhesion")
        text: catalog.i18nc("@label", "Bed Adhesion")
        font: UM.Theme.getFont("medium")
        width: labelColumnWidth
        iconSize: UM.Theme.getSize("medium_button_icon").width

        MouseArea {
            id: enableAdhesionMouseArea
            anchors.fill: parent
            hoverEnabled: true

            // onEntered: {
            //     base.showTooltip(enableAdhesionRowTitle, Qt.point(-enableAdhesionRowTitle.x - UM.Theme.getSize("thick_margin").width, 0),
            //         catalog.i18nc("@label", '<h3>Select a form of bed adhesion. "Skirt" is useful for observing adequate bed leveling and z-offsets \
            //         prior to the actual print, while "Brim" or "Raft" are useful for helping ensure a part stays adhered to the bed and can also \
            //         potentially help with warping issues. Choosing "None" is a way to print to the full extent of the build volume.</h3>'))
            // }
            // onExited: base.hideTooltip()
        }
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
            containerStackId: alive ? Cura.MachineManager.activeMachine.id : null
            settingKey: "adhesion_type"
            controlWidth: parent.width
            //useInBuiltTooltip: false
        }
    }
}
