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
UM.Switch {
    id: control

    height: UM.Theme.getSize("setting_control").height
    enabled: propertyProvider.properties.enabled == "True"

    property alias settingName: propertyProvider.key

    // If true, all extruders will have "settingName" property updated.
    // The displayed value will be read from the extruder with index "defaultExtruderIndex" instead of the machine.
    property bool updateAllExtruders: false
    // This is only used if updateAllExtruders == true
    property int defaultExtruderIndex: Cura.ExtruderManager.activeExtruderIndex

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
        watchedProperties: ["value", "resolve", enabled]
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

    // set initial checked value from stack
    checked: propertyProvider.properties.value == "True"

    onToggled: control.updateSetting(control.checked)

    Timer {
        id: updateTimer
        interval: 100
        repeat: false
        onTriggered: parseValueUpdateSetting(false)
    }

    function parseValueUpdateSetting(triggerUpdate) {
        // Only run when the setting value is updated by something other than the switch.
        // This sets the switch status based on the setting value, it does not update the setting value.

        let new_value = propertyProvider.properties.value == "True"

        if (new_value == control.checked) {
            return
        }

        control.checked = new_value
    }

    // Override this function to update a setting differently
    function updateSetting(value) {
        propertyProvider.setPropertyValue("value", value)
    }
}