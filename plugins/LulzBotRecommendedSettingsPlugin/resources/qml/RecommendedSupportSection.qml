// Copyright (c) 2020 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls
import QtQuick.Controls.Styles
import QtQuick.Controls 2.3 as Controls2
import QtQuick.Controls 2.15 as Controls3

import UM 1.2 as UM
import Cura 1.0 as Cura


//
//  Enable support
//
Item {
    id: enableSupportRow
    height: childrenRect.height

    property real labelColumnWidth: Math.round(width / 3)
    property bool alive: Cura.MachineManager.activeMachine != null && Cura.MachineManager.activeStack != null

    Cura.IconWithText {
        id: enableSupportRowTitle
        anchors.top: parent.top
        anchors.left: parent.left
        visible: enableSupportCheckBox.visible
        source: UM.Theme.getIcon("Support")
        text: catalog.i18nc("@label", "Support")
        font: UM.Theme.getFont("medium")
        width: labelColumnWidth
        iconSize: UM.Theme.getSize("medium_button_icon").width

        MouseArea {
            id: enableSupportMouseArea
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                base.showTooltip(enableSupportRowTitle, Qt.point(-enableSupportRowTitle.x - UM.Theme.getSize("thick_margin").width, 0),
                    catalog.i18nc("@label", "<h3>Generate structures to support parts of the model which have overhangs. \
                    Without these structures, such parts may collapse during printing.</h3>"))
            }
            onExited: base.hideTooltip()
        }
    }

    Item {
        id: enableSupportContainer
        height: enableSupportCheckBox.height

        anchors {
            left: enableSupportRowTitle.right
            right: parent.right
            verticalCenter: enableSupportRowTitle.verticalCenter
        }

        CheckBox {
            id: enableSupportCheckBox
            anchors.verticalCenter: parent.verticalCenter

            style: UM.Theme.styles.checkbox
            enabled: recommendedPrintSetup.settingsEnabled

            visible: supportEnabled.properties.enabled == "True"
            checked: supportEnabled.properties.value == "True"

            MouseArea {
                id: enableSupportCheckBoxMouseArea
                anchors.fill: parent

                onClicked: supportEnabled.setPropertyValue("value", supportEnabled.properties.value != "True")
            }

            UM.SettingPropertyProvider {
                id: supportEnabled
                containerStack: Cura.MachineManager.activeMachine
                key: "support_enable"
                watchedProperties: [ "value", "enabled", "description" ]
                storeIndex: 0
            }
        }

        Cura.ComboBox {
            id: supportExtruderCombobox

            property var extruderModel: CuraApplication.getExtrudersModel()
            property string color: "#000"
            showDropdownSwatch: true

            height: UM.Theme.getSize("setting_control").height
            anchors {
                left: enableSupportCheckBox.right
                right: parent.right
                leftMargin: UM.Theme.getSize("thin_margin").width
                verticalCenter: parent.verticalCenter
            }

            enabled: recommendedPrintSetup.settingsEnabled
            visible: enableSupportCheckBox.visible && (supportEnabled.properties.value == "True") && (extrudersEnabledCount.properties.value > 1)
            model: extruderModel
            textRole: "name"

            currentIndex: (supportExtruderNr.properties.value !== undefined) ? supportExtruderNr.properties.value : 0

            onActivated: {
                if (model.getItem(index).enabled) {
                    forceActiveFocus();
                    supportExtruderNr.setPropertyValue("value", model.getItem(index).index);
                } else {
                    currentIndex = supportExtruderNr.properties.value;  // keep the old value
                }
            }

            onCurrentIndexChanged: {
                let maybeColor = supportExtruderCombobox.model.getItem(supportExtruderCombobox.currentIndex).color
                if(maybeColor) {
                    supportExtruderCombobox.color = maybeColor
                }
            }

            Connections {
                target: supportExtruderCombobox.extruderModel
                function onModelChanged() {
                    let maybeColor = supportExtruderCombobox.model.getItem(supportExtruderCombobox.currentIndex).color
                    if (maybeColor) {
                        supportExtruderCombobox.color = maybeColor
                    }
                }
            }

            Rectangle {
                id: selectedSwatch
                height: Math.round(parent.height / 2)
                width: height
                radius: Math.round(width / 2)
                anchors.right: parent.indicator.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: UM.Theme.getSize("thin_margin").width

                color: supportExtruderCombobox.color
            }
        }
    }

    Label {
        id: supportOverhangLabel
        visible: enableSupportCheckBox.checked
        anchors {
            top: supportOverhangContainer.top
            bottom: supportOverhangContainer.bottom
            left: parent.left
            leftMargin: UM.Theme.getSize("wide_margin").width
            right: supportOverhangContainer.left
        }
        text: catalog.i18nc("@label", "Overhang Angle (°)")
        font: UM.Theme.getFont("small")
        renderType: Text.NativeRendering
        color: UM.Theme.getColor("text")
        verticalAlignment: Text.AlignVCenter

        MouseArea {
            id: supportOverhangMouseArea
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                base.showTooltip(supportOverhangLabel, Qt.point(-supportOverhangLabel.x - UM.Theme.getSize("thick_margin").width, 0),
                    catalog.i18nc("@label", "<h3>Adjusts the minimum angle relative to vertical at which supports will begin to be generated. \
                    A higher value will lower the amount of supports generated, but could lead to unsupported overhangs collapsing during printing.</h3>"))
            }
            onExited: base.hideTooltip()
        }
    }

    Binding {
        target: supportOverhangSlider
        property: "value"
        value: parseInt(supportOverhang.properties.value) - supportOverhangSlider.allowedMinimum
    }

    Item {
        id: supportOverhangContainer
        height: supportOverhangContainer.visible ? supportOverhangSlider.height : 0
        visible: enableSupportCheckBox.checked

        anchors {
            top: enableSupportContainer.bottom
            topMargin: supportOverhangContainer.visible ? UM.Theme.getSize("default_margin").height: 0
            left: enableSupportContainer.left
            right: parent.right
        }

        Slider {
            id: supportOverhangSlider

            width: parent.width
            height: UM.Theme.getSize("print_setup_slider_handle").height // The handle is the widest element of the slider

            minimumValue: 0 // Actually 40
            property int allowedMinimum: 40
            maximumValue: 40 // Actually 80
            stepSize: 1
            tickmarksEnabled: true
            property int tickmarkSpacing: 4
            wheelEnabled: false

            // disable slider when support is disabled
            enabled: enableSupportCheckBox.checked

            // set initial value from stack
            value: parseInt(supportOverhang.properties.value) - allowedMinimum

            style: UM.Theme.styles.setup_selector_slider

            onValueChanged: {
                let current = parseInt(supportOverhang.properties.value)

                if (current == value + allowedMinimum) {
                    return
                }
                if (current < allowedMinimum && value == minimumValue) {
                    return
                }
                if (current > maximumValue + allowedMinimum && value == maximumValue) {
                    return
                }

                // Round the slider value to nearest even number
                var roundedSliderValue = Math.round(supportOverhangSlider.value / 2) * 2

                // Update the slider value to represent the rounded value
                supportOverhangSlider.value = roundedSliderValue

                // Update value only if the Recommended mode is Active,
                // Otherwise if I change the value in the Custom mode the Recommended view will try to repeat
                // same operation
                var active_mode = UM.Preferences.getValue("cura/active_mode")

                if (active_mode == 0 || active_mode == "simple") {
                    Cura.MachineManager.setSettingForAllExtruders("support_angle", "value", roundedSliderValue + supportOverhangSlider.allowedMinimum)
                }
            }
        }

        UM.SettingPropertyProvider {
            id: supportOverhang
            containerStackId: alive ? Cura.MachineManager.activeMachine.id : null
            key: "support_angle"
            watchedProperties: ["value"]
            storeIndex: 0
        }
    }

    Label {
        id: supportDensityLabel
        visible: enableSupportCheckBox.checked
        anchors {
            top: supportDensityContainer.top
            bottom: supportDensityContainer.bottom
            left: parent.left
            leftMargin: UM.Theme.getSize("wide_margin").width
            right: supportDensityContainer.left
        }
        text: catalog.i18nc("@label", "Support Density (%)")
        font: UM.Theme.getFont("small")
        renderType: Text.NativeRendering
        color: UM.Theme.getColor("text")
        verticalAlignment: Text.AlignVCenter

        MouseArea {
            id: supportDensityMouseArea
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                base.showTooltip(supportDensityLabel, Qt.point(-supportDensityLabel.x - UM.Theme.getSize("thick_margin").width, 0),
                    catalog.i18nc("@label", "<h3>Set the percentage of support density.</h3>"))
            }
            onExited: base.hideTooltip()
        }
    }

    Binding {
        target: supportDensitySlider
        property: "value"
        value: parseInt(supportDensity.properties.value)
    }

    Item {
        id: supportDensityContainer
        height: supportDensityContainer.visible ? supportDensitySlider.height : 0
        visible: enableSupportCheckBox.checked

        anchors {
            top: supportOverhangContainer.bottom
            topMargin: supportDensityContainer.visible ? UM.Theme.getSize("thick_margin").height : 0
            left: enableSupportContainer.left
            right: parent.right
        }

        Slider {
            id: supportDensitySlider

            width: parent.width
            height: UM.Theme.getSize("print_setup_slider_handle").height // The handle is the widest element of the slider

            minimumValue: 0
            property int allowedMinimum: 0
            maximumValue: 100
            stepSize: 1
            tickmarksEnabled: true
            property int tickmarkSpacing: 10
            wheelEnabled: false

            // disable slider when support is disabled
            enabled: enableSupportCheckBox.checked

            // set initial value from stack
            value: parseInt(supportDensity.properties.value) - allowedMinimum

            style: UM.Theme.styles.setup_selector_slider

            onValueChanged: {
                // Don't round the value if it's already the same
                if (parseInt(supportDensity.properties.value) == supportDensitySlider.value) {
                    return
                }

                // Round the slider value to the nearest multiple of 5 (simulate step size of 5)
                var roundedSliderValue = Math.round(supportDensitySlider.value / 5) * 5

                // Update the slider value to represent the rounded value
                supportDensitySlider.value = roundedSliderValue

                // Update value only if the Recommended mode is Active,
                // Otherwise if I change the value in the Custom mode the Recommended view will try to repeat
                // same operation
                var active_mode = UM.Preferences.getValue("cura/active_mode")

                if (active_mode == 0 || active_mode == "simple") {
                    Cura.MachineManager.setSettingForAllExtruders("support_infill_rate", "value", roundedSliderValue)
                    Cura.MachineManager.resetSettingForAllExtruders("support_line_distance")
                }
            }
        }

        UM.SettingPropertyProvider {
            id: supportDensity
            containerStackId: Cura.MachineManager.activeStackId
            key: "support_infill_rate"
            watchedProperties: ["value"]
            storeIndex: 0
        }
    }

    Label {
        id: joinDistanceLabel
        visible: enableSupportCheckBox.checked
        anchors {
            top: joinDistanceContainer.top
            bottom: joinDistanceContainer.bottom
            left: parent.left
            leftMargin: UM.Theme.getSize("wide_margin").width
            right: joinDistanceContainer.left
        }
        text: catalog.i18nc("@label", "Join Distance (mm)")
        font: UM.Theme.getFont("small")
        renderType: Text.NativeRendering
        color: UM.Theme.getColor("text")
        verticalAlignment: Text.AlignVCenter

        MouseArea {
            id: joinDistanceMouseArea
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                base.showTooltip(joinDistanceLabel, Qt.point(-joinDistanceLabel.x - UM.Theme.getSize("thick_margin").width, 0),
                    catalog.i18nc("@label", "<h3>Set the distance in millimeters under which separate support structures will join \
                    together. Increasing this setting can help with issues regarding failure of many small support structures around a print.</h3>"))
            }
            onExited: base.hideTooltip()
        }
    }

    Binding {
        target: joinDistanceSpinBox
        property: "value"
        value: parseInt(supportJoinDistance.properties.value)
    }

    Item {
        id: joinDistanceContainer
        width: Math.round((parent.width - labelColumnWidth) / 1.8)
        height: joinDistanceContainer.visible ? joinDistanceSpinBox.height : 0
        visible: enableSupportCheckBox.checked

        anchors {
            top: supportDensityContainer.bottom
            topMargin: supportOverhangContainer.visible ? UM.Theme.getSize("thick_margin").height : 0
            left: enableSupportContainer.left
        }

        Controls3.SpinBox {
            id: joinDistanceSpinBox

            anchors.verticalCenter: parent.verticalCenter

            height: enableSupportRowTitle.height
            width: parent.width

            from: 0
            to: 15
            editable: true
            stepSize: 1

            value: parseInt(supportJoinDistance.properties.value)

            onValueChanged: {
                // Don't round the value if it's already the same
                let current = parseInt(supportJoinDistance.properties.value)
                if (current == value) {
                    return
                }
                if (current > to && value == to) {
                    return
                }

                // Update value only if the Recommended mode is Active,
                // Otherwise if I change the value in the Custom mode the Recommended view will try to repeat
                // same operation
                var active_mode = UM.Preferences.getValue("cura/active_mode")

                if (active_mode == 0 || active_mode == "simple") {
                    Cura.MachineManager.setSettingForAllExtruders("support_join_distance", "value", joinDistanceSpinBox.value)
                }
            }
        }

        UM.SettingPropertyProvider {
            id: supportJoinDistance
            containerStackId: alive ? Cura.MachineManager.activeStack.id : null
            key: "support_join_distance"
            watchedProperties: [ "value" ]
            storeIndex: 0
        }
    }

    Label {
        id: supportRoofLabel
        visible: enableSupportCheckBox.checked
        anchors {
            top: supportRoofContainer.top
            bottom: supportRoofContainer.bottom
            left: parent.left
            leftMargin: UM.Theme.getSize("wide_margin").width
            right: supportRoofContainer.left
        }
        text: catalog.i18nc("@label", "Support Roof")
        font: UM.Theme.getFont("small")
        renderType: Text.NativeRendering
        color: UM.Theme.getColor("text")
        verticalAlignment: Text.AlignVCenter

        MouseArea {
            id: supportRoofMouseArea
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                base.showTooltip(supportRoofLabel, Qt.point(-supportRoofLabel.x - UM.Theme.getSize("thick_margin").width, 0),
                    catalog.i18nc("@label", "<h3>Generate a dense slab of material between the top of support and the model. \
                    This will create a skin between the model and support.</h3>"))
            }
            onExited: base.hideTooltip()
        }
    }

    Item {
        id: supportRoofContainer
        width: Math.round((parent.width - labelColumnWidth) / 2)
        height: supportRoofContainer.visible ? supportRoofCheckBox.height : 0
        visible: enableSupportCheckBox.checked

        anchors {
            top: joinDistanceContainer.bottom
            topMargin: supportOverhangContainer.visible ? UM.Theme.getSize("thin_margin").height : 0
            left: enableSupportContainer.left
        }

        CheckBox {
            id: supportRoofCheckBox
            anchors.verticalCenter: parent.verticalCenter

            style: UM.Theme.styles.checkbox
            enabled: recommendedPrintSetup.settingsEnabled

            checked: supportRoofEnabled.properties.value == "True"

            MouseArea {
                id: supportRoofCheckBoxMouseArea
                anchors.fill: parent

                onClicked: supportRoofEnabled.setPropertyValue("value", supportRoofEnabled.properties.value != "True")
            }

            UM.SettingPropertyProvider {
                id: supportRoofEnabled
                containerStack: Cura.MachineManager.activeMachine
                key: "support_roof_enable"
                watchedProperties: [ "value" ]
                storeIndex: 0
            }
        }
    }

    UM.SettingPropertyProvider {
        id: supportExtruderNr
        containerStack: Cura.MachineManager.activeMachine
        key: "support_extruder_nr"
        watchedProperties: [ "value" ]
        storeIndex: 0
    }

    UM.SettingPropertyProvider {
        id: machineExtruderCount
        containerStack: Cura.MachineManager.activeMachine
        key: "machine_extruder_count"
        watchedProperties: ["value"]
        storeIndex: 0
    }
}
