// Copyright (c) 2023 Fargo Additive Manufacturing Equipment 3D, LLC.
// Cura LE is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 1.4 as OldControls // Funny...
import QtQuick.Controls 2.15
import QtQuick.Controls.Styles 1.4

import UM 1.2 as UM
import Cura 1.0 as Cura


//
// Strength Section
// This section contains some useful settings related to overall part strength
//
Item {
    id: strengthSection
    height: childrenRect.height

    property real labelColumnWidth: Math.round(width / 3)
    property bool alive: Cura.MachineManager.activeMachine != null && Cura.MachineManager.activeStack != null

    Cura.IconWithText {
        id: strengthSectionTitle
        anchors {
            top: parent.top
            left: parent.left
        }
        source: UM.Theme.getIcon("Hammer")
        text: catalog.i18nc("@label", "Strength")
        font: UM.Theme.getFont("medium")
        width: labelColumnWidth
        iconSize: UM.Theme.getSize("medium_button_icon").width

        MouseArea {
            id: strengthMouseArea
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                base.showTooltip(strengthSectionTitle, Qt.point(-strengthSectionTitle.x - UM.Theme.getSize("thick_margin").width, 0),
                    catalog.i18nc("@label", '<b>Settings in this section are most important for determining overall part strength.</b>\
                    <p>Set the pattern used for the infill of your print. "Grid" is our recommended pattern as it is relatively efficient \
                    both in print time and plastic usage while still giving your prints good structural integrity. "Gyroid" has excellent \
                    compressibility properties. There are additional patterns that may prove useful.</p>'))
            }
            onExited: base.hideTooltip()
        }
    }

    // We're gonna slap the infill pattern up here for the moment, I guess
    Item {
        id: infillPatternContainer
        height: infillPatternComboBox.height

        anchors {
            //top: strengthSectionTitle.top
            // topMargin: UM.Theme.getSize("thick_margin").height
            left: strengthSectionTitle.right
            right: parent.right
            verticalCenter: strengthSectionTitle.verticalCenter
        }

        Cura.ComboBoxWithOptions {
            id: infillPatternComboBox
            containerStackId: Cura.ExtruderManager.activeExtruderStackId
            settingKey: "infill_pattern"
            controlWidth: infillPatternContainer.width
            useInBuiltTooltip: false
        }
    }

    //
    // Infill Chunk
    //

    // Create a binding to update the icon when the infill density changes
    Binding {
        target: infillSliderTitle
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

    Cura.IconWithText {
        id: infillSliderTitle
        anchors {
            top: strengthSectionTitle.bottom
            topMargin: UM.Theme.getSize("default_margin").height
            left: parent.left
            right: strengthSectionTitle.right
            leftMargin: UM.Theme.getSize("wide_margin").width
        }
        source: UM.Theme.getIcon("Infill1")
        text: catalog.i18nc("@label", "Infill") + " (%)"
        font: UM.Theme.getFont("small")
        iconSize: UM.Theme.getSize("medium_button_icon").width

        MouseArea {
            id: infillMouseArea
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                base.showTooltip(infillSliderTitle, Qt.point(-infillSliderTitle.x - UM.Theme.getSize("thick_margin").width, 0),
                    catalog.i18nc("@label", "Set the percentage of the interior that will be filled with infill by volume."))
            }
            onExited: base.hideTooltip()
        }
    }

    Item {
        id: infillSliderContainer
        height: childrenRect.height

        anchors {
            left: infillSliderTitle.right
            right: parent.right
            verticalCenter: infillSliderTitle.verticalCenter
        }

        OldControls.Slider {
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

    // We're moving setting up to where the "Strength" header is? Something about saving room.
    // Cura.IconWithText {
    //     id: patternLabel
    //     anchors {
    //         top: infillPatternContainer.top
    //         bottom: infillPatternContainer.bottom
    //         left: parent.left
    //         leftMargin: UM.Theme.getSize("wide_margin").width
    //         right: infillPatternContainer.left
    //     }
    //     source: UM.Theme.getIcon("InfillGyroid")
    //     iconSize: UM.Theme.getSize("medium_button_icon").width // I sure am glad I spent time on this if we're not even gonna use it... :D
    //     text: catalog.i18nc("@label", "Infill Pattern")
    //     font: UM.Theme.getFont("small")

    //     MouseArea {
    //         id: infillPatternMouseArea
    //         anchors.fill: parent
    //         hoverEnabled: true

    //         onEntered: {
    //             base.showTooltip(patternLabel, Qt.point(-patternLabel.x - UM.Theme.getSize("thick_margin").width, 0),
    //                 catalog.i18nc("@label", 'Set the pattern used for the infill of your print. "Grid" is our recommended pattern as it is relatively efficient both in print time and plastic usage while still giving your prints good structural integrity. "Gyroid" has excellent compressibility properties. There are additional patterns that may prove useful.'))
    //         }
    //         onExited: base.hideTooltip()
    //     }
    // }

    // Item {
    //     id: infillPatternContainer
    //     height: infillPatternComboBox.height

    //     anchors {
    //         top: infillSliderContainer.bottom
    //         topMargin: UM.Theme.getSize("thick_margin").height
    //         left: infillSliderContainer.left
    //         right: parent.right
    //     }

    //     Cura.ComboBoxWithOptions {
    //         id: infillPatternComboBox
    //         containerStackId: Cura.ExtruderManager.activeExtruderStackId
    //         settingKey: "infill_pattern"
    //         controlWidth: infillPatternContainer.width
    //         useInBuiltTooltip: false
    //     }
    // }

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


    //
    // Wall Chunk
    //

    Cura.IconWithText {
        id: wallCountRowTitle
        anchors {
            // Changed these due to pattern moving up
            // top: infillPatternContainer.bottom
            top: infillSliderContainer.bottom
            // topMargin: UM.Theme.getSize("thin_margin").height
            topMargin: UM.Theme.getSize("thick_margin").height
            left: infillSliderTitle.left
            right: strengthSectionTitle.right
        }
        source: UM.Theme.getIcon("PrintWalls")
        text: catalog.i18nc("@label", "Wall Count")
        font: UM.Theme.getFont("small")
        width: labelColumnWidth
        iconSize: UM.Theme.getSize("medium_button_icon").width

        MouseArea {
            id: wallCountMouseArea
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                base.showTooltip(wallCountRowTitle, Qt.point(-wallCountRowTitle.x - UM.Theme.getSize("thick_margin").width, 0),
                    catalog.i18nc("@label", "Set the number of solid walls that will be generated on the sides of your print. \
                    This number plays a large factor in the overall strength of your part."))
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
        width: Math.round((parent.width - labelColumnWidth) / 1.8)

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


    //
    // Top/Bottom Chunk
    //

    Cura.IconWithText {
        id: topBottomRowTitle
        anchors {
            top: wallCountContainer.bottom
            topMargin: UM.Theme.getSize("thick_margin").height
            left: infillSliderTitle.left
            right: strengthSectionTitle.right
        }
        source: UM.Theme.getIcon("PrintTopBottom")
        text: catalog.i18nc("@label", "Top/Bottom Count")
        font: UM.Theme.getFont("small")
        width: labelColumnWidth
        iconSize: UM.Theme.getSize("medium_button_icon").width

        MouseArea {
            id: topBottomMouseArea
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                base.showTooltip(topBottomRowTitle, Qt.point(-topBottomRowTitle.x - UM.Theme.getSize("thick_margin").width, 0),
                    catalog.i18nc("@label", "Set the number of solid layers that will be generated on the top and bottom of your print. \
                    In the dropdown to the right, you can also set the pattern that those layers will be created with."))
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
        width: Math.round((parent.width - labelColumnWidth) / 1.8)

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
            containerStackId: Cura.ExtruderManager.activeExtruderStackId
            settingKey: "top_bottom_pattern"
            controlWidth: parent.width
            useInBuiltTooltip: false
        }
    }
}
