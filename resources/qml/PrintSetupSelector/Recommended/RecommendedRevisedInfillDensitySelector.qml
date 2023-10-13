// Copyright (c) 2018 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4

import UM 1.2 as UM
import Cura 1.0 as Cura


//
// Infill
//
Item {
    id: infillRow
    height: childrenRect.height

    property real labelColumnWidth: Math.round(width / 3)
    property bool alive: Cura.MachineManager.activeMachine != null && Cura.MachineManager.activeStack != null

    // Create a binding to update the icon when the infill density changes
    Binding {
        target: infillRowTitle
        property: "source"
        value: {
            var density = parseInt(infillDensity.properties.value)
            if (parseInt(infillSteps.properties.value) != 0) {
                return UM.Theme.getIcon("InfillGradual")
            }
            if (density <= 0) {
                return UM.Theme.getIcon("Infill0")
            }
            if (density < 40) {
                return UM.Theme.getIcon("Infill3")
            }
            if (density < 90) {
                return UM.Theme.getIcon("Infill2")
            }
            return UM.Theme.getIcon("Infill100")
        }
    }

    // We use a binding to make sure that after manually setting infillSlider.value it is still bound to the property provider
    Binding {
        target: infillSlider
        property: "value"
        value: parseInt(infillDensity.properties.value) - infillSlider.allowedMinimum
    }

    // Here are the elements that are shown in the left column
    Cura.IconWithText {
        id: infillRowTitle
        anchors.top: parent.top
        anchors.left: parent.left
        source: UM.Theme.getIcon("Infill1")
        text: catalog.i18nc("@label", "Infill") + " (%)"
        font: UM.Theme.getFont("medium")
        width: labelColumnWidth
        iconSize: UM.Theme.getSize("medium_button_icon").width
    }

    Item {
        id: infillSliderContainer
        height: childrenRect.height

        anchors {
            left: infillRowTitle.right
            right: parent.right
            verticalCenter: infillRowTitle.verticalCenter
        }

        Slider {
            id: infillSlider

            width: parent.width
            height: UM.Theme.getSize("print_setup_slider_handle").height // The handle is the widest element of the slider

            minimumValue: 0
            property int allowedMinimum: 0
            maximumValue: 100
            stepSize: 1
            tickmarksEnabled: true
            property int tickmarkSpacing: 10
            wheelEnabled: false

            // disable slider when gradual support is enabled
            enabled: parseInt(infillSteps.properties.value) == 0

            // set initial value from stack
            value: parseInt(infillDensity.properties.value) - allowedMinimum

            style: UM.Theme.styles.setup_selector_slider

            onValueChanged: {
                // Don't round the value if it's already the same
                if (parseInt(infillDensity.properties.value) == infillSlider.value) {
                    return
                }

                // Round the slider value to the nearest multiple of 10 (simulate step size of 10)
                var roundedSliderValue = Math.round(infillSlider.value / 10) * 10

                // Update the slider value to represent the rounded value
                infillSlider.value = roundedSliderValue

                // Update value only if the Recommended mode is Active,
                // Otherwise if I change the value in the Custom mode the Recommended view will try to repeat
                // same operation
                var active_mode = UM.Preferences.getValue("cura/active_mode")

                if (active_mode == 0 || active_mode == "simple") {
                    Cura.MachineManager.setSettingForAllExtruders("infill_sparse_density", "value", roundedSliderValue)
                    Cura.MachineManager.resetSettingForAllExtruders("infill_line_distance")
                }
            }
        }
    }

    Label {
        id: patternLabel
        anchors {
            top: infillPatternContainer.top
            bottom: infillPatternContainer.bottom
            left: parent.left
            leftMargin: UM.Theme.getSize("wide_margin").width
            right: infillPatternContainer.left
        }
        text: catalog.i18nc("@label", "Infill Pattern")
        font: UM.Theme.getFont("small")
        renderType: Text.NativeRendering
        color: UM.Theme.getColor("text")
        verticalAlignment: Text.AlignVCenter
    }

    Item {
        id: infillPatternContainer
        height: infillPatternComboBox.height

        anchors {
            top: infillSliderContainer.bottom
            topMargin: UM.Theme.getSize("thick_margin").height
            left: infillSliderContainer.left
            right: parent.right
        }

        Cura.ComboBoxWithOptions {
            id: infillPatternComboBox
            containerStackId: alive ? Cura.MachineManager.activeMachine.id : null
            settingKey: "infill_pattern"
            controlWidth: infillPatternContainer.width
        }
    }

    UM.SettingPropertyProvider {
        id: infillDensity
        containerStackId: alive ? Cura.MachineManager.activeStack.id : null
        key: "infill_sparse_density"
        watchedProperties: [ "value" ]
        storeIndex: 0
    }

    UM.SettingPropertyProvider {
        id: infillSteps
        containerStackId: Cura.MachineManager.activeStackId
        key: "gradual_infill_steps"
        watchedProperties: ["value", "enabled"]
        storeIndex: 0
    }
}
