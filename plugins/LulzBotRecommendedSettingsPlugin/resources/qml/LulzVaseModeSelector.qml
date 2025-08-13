// Copyright (c) 2018 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4

import UM 1.2 as UM
import Cura 1.0 as Cura


//
//  Vase Mode
//
Item {
    id: enableVaseModeRow
    height: childrenRect.height

    property real labelColumnWidth: Math.round(width / 3)
    property bool alive: Cura.MachineManager.activeMachine != null
    property var curaRecommendedMode: Cura.RecommendedMode {}

    Cura.IconWithText {
        id: enableVaseModeRowTitle
        anchors.top: parent.top
        anchors.left: parent.left
        source: UM.Theme.getIcon("Vase")
        text: catalog.i18nc("@label", "Vase Mode")
        font: UM.Theme.getFont("medium")
        width: labelColumnWidth
        iconSize: UM.Theme.getSize("medium_button_icon").width

        MouseArea {
            id: enableVaseModeMouseArea
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                base.showTooltip(enableVaseModeRowTitle, Qt.point(-enableVaseModeRowTitle.x - UM.Theme.getSize("thick_margin").width, 0),
                    catalog.i18nc("@label", "<h3>FOR ADVANCED USE ONLY</h3><h3>Vase Mode prints objects with continuous walls \
                    by extruding in a spiral pattern. This mode eliminates the need for layer-by-layer printing and infill, \
                    resulting in fast prints that only have a single wall. For best results, experiment with increasing your Line Width.</h3>\
                    <h3>This will enable a setting called \"Spiralize Outer Contour\". You can find this setting in the \"Special Modes\" section of the \
                    Custom menu.</h3>"))
            }
            onExited: base.hideTooltip()
        }
    }

    Item {
        id: enableVaseModeContainer
        height: vaseModeCheckBox.height

        anchors {
            left: enableVaseModeRowTitle.right
            right: parent.right
            verticalCenter: enableVaseModeRowTitle.verticalCenter
        }

        CheckBox {
            id: vaseModeCheckBox
            anchors.verticalCenter: parent.verticalCenter

            style: UM.Theme.styles.checkbox

            checked: magicSpiralize.properties.value == "True"

            MouseArea {
                id: vaseModeCheckBoxMouseArea
                anchors.fill: parent

                onClicked: magicSpiralize.setPropertyValue("value", magicSpiralize.properties.value != "True")
            }

            UM.SettingPropertyProvider {
                id: magicSpiralize
                containerStack: Cura.MachineManager.activeMachine
                key: "magic_spiralize"
                watchedProperties: [ "value" ]
                storeIndex: 0
            }
        }
    }
}
