// Copyright (c) 2022 UltiMaker
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 2.15

import UM 1.7 as UM
import Cura 1.7 as Cura

// This spinbox allows changing of a single setting. Only the setting name has to be passed in to "settingName".
// All of the setting updating logic is handled by this component.
// This component allows you to choose values between minValue -> maxValue using intervals of stepSize.
// If the setting is limited to a single extruder or is settable with different values per extruder use "updateAllExtruders: true"
SpinBox {
    id: control

    height: UM.Theme.getSize("setting_control").height

    property alias settingName: propertyProvider.key

    // If true, all extruders will have "settingName" property updated.
    // The displayed value will be read from the extruder with index "defaultExtruderIndex" instead of the machine.
    property bool updateAllExtruders: false
    // This is only used if updateAllExtruders == true
    property int defaultExtruderIndex: Cura.ExtruderManager.activeExtruderIndex

    // set stepSize to 1
    stepSize: 1

    UM.SettingPropertyProvider {
        id: propertyProvider
        containerStackId: {
            let output = "";
            if (updateAllExtruders) {
                if (Cura.ExtruderManager.extruderIds[defaultExtruderIndex] != undefined) {
                    output = Cura.ExtruderManager.extruderIds[defaultExtruderIndex];
                }
                else if (Cura.MachineManager.activeMachine != null) {
                    output = Cura.MachineManager.activeMachine.id;
                }
            }
            return output;
        }
        watchedProperties: ["value", "minimum_value", "maximum_value", "resolve"]
        removeUnusedValue: false
        storeIndex: 0
    }

    Connections {
        target: propertyProvider
        function onContainerStackChanged() {
            updateTimer.restart()
        }
        function onIsValueUsedChanged() {
            updateTimer.restart()
        }
    }

    // set initial value from stack
    value: parseInt(propertyProvider.properties.value)

    // set range from minimum_value to maximum_value
    from: parseInt(propertyProvider.properties.minimum_value);
    to: parseInt(propertyProvider.properties.maximum_value) != 0 ? parseInt(propertyProvider.properties.maximum_value) : 50

    onValueModified: control.updateSetting(control.value)

    Timer {
        id: updateTimer
        interval: 100
        repeat: false
        onTriggered: parseValueUpdateSetting(false)
    }

    function parseValueUpdateSetting(triggerUpdate) {
        // Only run when the setting value is updated by something other than the slider.
        // This sets the slider value based on the setting value, it does not update the setting value.

        if (parseInt(propertyProvider.properties.value) == control.value) {
            return
        }

        control.value = propertyProvider.properties.value
    }

    // Override this function to update a setting differently
    function updateSetting(value) {
        if (updateAllExtruders) {
            Cura.MachineManager.setSettingForAllExtruders(propertyProvider.key, "value", value)
        }
        else {
            propertyProvider.setPropertyValue("value", value)
        }
    }

    contentItem: UM.Label {
        id: contentLabel
        text: control.textFromValue(control.value, control.locale)

        horizontalAlignment: Qt.AlignHCenter
        verticalAlignment: Qt.AlignVCenter
    }

    up.indicator: Rectangle {
        x: control.mirrored ? 0 : parent.width - width
        height: parent.height
        width: height
        //color: control.up.pressed ? UM.Theme.getColor("setting_control_button_hover") : control.up.hovered ? UM.Theme.getColor("setting_control_button_hover") : UM.Theme.getColor("setting_control_button")
        //border.color: enabled ? UM.Theme.getColor("setting_control_border") : UM.Theme.getColor("setting_control_disabled_border")

        UM.UnderlineBackground {
            color: control.up.pressed ? control.palette.mid : UM.Theme.getColor("detail_background")
        }

        UM.ColorImage {
            anchors.centerIn: parent
            height: parent.height / 2.5
            width: height
            color: enabled ? UM.Theme.getColor("text") : UM.Theme.getColor("text_disabled")
            source: UM.Theme.getIcon("Plus")
        }
    }

    down.indicator: Rectangle {
        x: control.mirrored ? parent.width - width : 0
        height: parent.height
        width: height
        // color: control.up.pressed ? UM.Theme.getColor("setting_control_button_hover") : control.up.hovered ? UM.Theme.getColor("setting_control_button_hover") : UM.Theme.getColor("setting_control_button")
        // border.color: enabled ? UM.Theme.getColor("setting_control_border") : UM.Theme.getColor("setting_control_disabled_border")

        UM.UnderlineBackground {
            color: control.down.pressed ? control.palette.mid : UM.Theme.getColor("detail_background")
        }

        UM.ColorImage
        {
            anchors.centerIn: parent
            height: parent.height / 2.5
            width: height
            color: enabled ? UM.Theme.getColor("text") : UM.Theme.getColor("text_disabled")
            source: UM.Theme.getIcon("Minus")
        }
    }

    background: Rectangle {
        implicitWidth: 140
        border.color: enabled ? UM.Theme.getColor("setting_control_border") : UM.Theme.getColor("setting_control_disabled_border")
    }
}