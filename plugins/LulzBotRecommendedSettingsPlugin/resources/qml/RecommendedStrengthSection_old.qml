// Copyright (c) 2023 Fargo Additive Manufacturing Equipment 3D, LLC.
// Cura LE is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 2.15

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

            // onEntered: {
            //     base.showTooltip(strengthSectionTitle, Qt.point(-strengthSectionTitle.x - UM.Theme.getSize("thick_margin").width, 0),
            //         catalog.i18nc("@label", '<h3><b>Settings in this section are most important for determining overall part strength.</b></h3>\
            //         <h3>Set the pattern used for the infill of your print. "Grid" is our recommended pattern as it is relatively efficient \
            //         both in print time and plastic usage while still giving your prints good structural integrity. "Gyroid" has excellent \
            //         compressibility properties. There are additional patterns that may prove useful.</h3>'))
            // }
            // onExited: base.hideTooltip()
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
            // useInBuiltTooltip: false
        }
    }

    //
    // Infill Chunk
    //

    // Create a binding to update the icon when the infill density changes
    /* Binding {
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
    }*/

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

            // onEntered: {
            //     base.showTooltip(infillSliderTitle, Qt.point(-infillSliderTitle.x - UM.Theme.getSize("thick_margin").width, 0),
            //         catalog.i18nc("@label", "<h3>Set the percentage of the interior that will be filled with infill by volume.</h3>"))
            // }
            // onExited: base.hideTooltip()
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

        /* Slider {
            id: infillSlider

            width: parent.width
            height: UM.Theme.getSize("print_setup_slider_handle").height // The handle is the widest element of the slider

            from: 0
            property int allowedMinimum: 0
            to: 100
            stepSize: 1
            property int tickmarkSpacing: 10
            wheelEnabled: false

            // disable slider when gradual support is enabled
            // enabled: parseInt(infillSteps.properties.value) == 0

            // set initial value from stack
            value: parseInt(infillDensity.properties.value) - allowedMinimum

            onValueChanged: {
                // Don't round the value if it's already the same
                if (parseInt(infillDensity.properties.value) == infillSlider.value) {
                    return
                }

                // Round the slider value to the nearest multiple of 5 (simulate step size of 5)
                var roundedSliderValue = Math.round(infillSlider.value / 5) * 5

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
        }*/
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

            // onEntered: {
            //     base.showTooltip(wallCountRowTitle, Qt.point(-wallCountRowTitle.x - UM.Theme.getSize("thick_margin").width, 0),
            //         catalog.i18nc("@label", "<h3>Set the number of solid walls that will be generated on the sides of your print. \
            //         This number plays a large factor in the overall strength of your part.</h3>\
            //         <h3>In the dropdown to the right, you can select textured walls. This will enable a setting called \"Fuzzy Skin\".\
            //         You can fine-tune this setting in the \"Experimental\" section of the Custom menu.</h3>"))
            // }
            // onExited: base.hideTooltip()
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

    Item {
        id: wallFuzzyContainer
        height: wallFuzzyComboBox.height

        anchors {
            left: wallCountContainer.right
            leftMargin: UM.Theme.getSize("thin_margin").width
            right: parent.right
            verticalCenter: wallCountRowTitle.verticalCenter
        }

        Cura.ComboBox {
            id: wallFuzzyComboBox
            width: parent.width
            height: UM.Theme.getSize("setting_control").height
            anchors {
                verticalCenter: parent.verticalCenter
                horizontalCenter: parent.horizontalCenter
            }

            model: ListModel {
                ListElement { key: "smooth"; value: "Smooth" }
                ListElement { key: "textured"; value: "Textured" }
            }
            textRole: "value"

            currentIndex: {
                let currentValue = magicFuzzySkin.properties.value
                if (currentValue === "True") {
                    return 1
                } else {
                    return 0
                }
            }

            onActivated: {
                let newValue = false
                let oldValue = false
                if (magicFuzzySkin.properties.value === "True") {
                    oldValue = true
                }
                if (index == 1) {
                    newValue = true
                }
                if (oldValue != newValue) {
                    if (newValue) {
                        console.log(zSeamType.properties.value)
                        zSeamType.setPropertyValue("value", "random")
                    } else {
                        zSeamType.setPropertyValue("value", "sharpest_corner")
                    }
                    magicFuzzySkin.setPropertyValue("value", newValue)
                }
            }
        }

        UM.SettingPropertyProvider {
            id: magicFuzzySkin
            containerStackId: alive ? Cura.ExtruderManager.activeExtruderStackId : null
            key: "magic_fuzzy_skin_enabled"
            watchedProperties: [ "value" ]
            storeIndex: 0
        }

        UM.SettingPropertyProvider {
            id: zSeamType
            containerStackId: alive ? Cura.ExtruderManager.activeExtruderStackId : null
            key: "z_seam_type"
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

            // onEntered: {
            //     base.showTooltip(topBottomRowTitle, Qt.point(-topBottomRowTitle.x - UM.Theme.getSize("thick_margin").width, 0),
            //         catalog.i18nc("@label", "<h3>Set the number of solid layers that will be generated on the top and bottom of your print.</h3> \
            //         <h3>In the dropdown to the right, you can also set the pattern that those layers will be created with.</h3>"))
            // }
            // onExited: base.hideTooltip()
        }
    }

    Binding {
        target: topBottomCountSpinBox
        property: "value"
        value: Math.max(parseInt(bottomLayers.properties.value), parseInt(topLayers.properties.value))
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
                let current = Math.max(parseInt(topLayers.properties.value), parseInt(bottomLayers.properties.value))
                if (current == topBottomCountSpinBox.value) {
                    return
                }

                var active_mode = UM.Preferences.getValue("cura/active_mode")

                if (active_mode == 0 || active_mode == "simple") {
                    Cura.MachineManager.setSettingForAllExtruders("top_layers", "value", topBottomCountSpinBox.value)
                    Cura.MachineManager.setSettingForAllExtruders("bottom_layers", "value", topBottomCountSpinBox.value)
                }
            }
        }

        UM.SettingPropertyProvider {
            id: bottomLayers
            containerStackId: alive ? Cura.MachineManager.activeStack.id : null
            key: "bottom_layers"
            watchedProperties: [ "value" ]
            storeIndex: 0
        }

        UM.SettingPropertyProvider {
            id: topLayers
            containerStackId: alive ? Cura.MachineManager.activeStack.id : null
            key: "top_layers"
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
            // useInBuiltTooltip: false
        }
    }
}
