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
Cura.SpinBox {
    id: settingSpinBox

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

    // set initial value from stack
    value: parseInt(propertyProvider.properties.value)

    // set range from minimum_value to maximum_value
    from: parseInt(propertyProvider.properties.minimum_value); to: parseInt(propertyProvider.properties.maximum_value)

    Connections {
        target: propertyProvider
        function onContainerStackChanged() {
            updateTimer.restart()
        }
        function onIsValueUsedChanged() {
            updateTimer.restart()
        }
    }

    // Updates to the setting are delayed by interval. This reduces lag by waiting a bit after a setting change to update the spinbox contents.
    Timer {
        id: updateTimer
        interval: 100
        repeat: false
        onTriggered: parseValueUpdateSetting(false)
    }

    function updateSpinBox(value) {
        settingSpinBox.value = value
    }

    function parseValueUpdateSetting(triggerUpdate) {
        // Only run when the setting value is updated by something other than the slider.
        // This sets the slider value based on the setting value, it does not update the setting value.

        if (parseInt(propertyProvider.properties.value) == settingSpinBox.value) {
            return
        }

        settingSpinBox.value = propertyProvider.properties.value
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
}