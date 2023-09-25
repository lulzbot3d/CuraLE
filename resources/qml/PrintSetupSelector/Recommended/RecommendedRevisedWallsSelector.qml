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
    property var curaRecommendedMode: Cura.RecommendedMode {}

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
                    Cura.MachineManager.setSettingForAllExtruders("wall_line_count", "value", wallCountSlider.value) //roundedSliderValue)
                }
            }
        }
    }

    UM.SettingPropertyProvider {
        id: wallCount
        containerStackId: Cura.MachineManager.activeStackId
        key: "wall_line_count"
        watchedProperties: [ "value" ]
        storeIndex: 0
    }
}
