// Copyright (c) 2018 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls

import UM 1.8 as UM
import Cura 1.0 as Cura


//
//  Vase Mode
//
RecommendedSettingSection {
    id: enableVaseModeRow

    title: catalog.i18nc("@label", "Vase Mode")
    icon: UM.Theme.getIcon("Vase")
    enableSectionSwitchVisible: vaseModeEnabled.properties.enabled == "True"
    enableSectionSwitchChecked: vaseModeEnabled.properties.value == "True"
    enableSectionSwitchEnabled: recommendedPrintSetup.settingsEnabled
    tooltipText: catalog.i18nc("@label", "<h3>FOR ADVANCED USE ONLY</h3><h3>Vase Mode prints objects with continuous walls \
                    by extruding in a spiral pattern. This mode eliminates the need for layer-by-layer printing and infill, \
                    resulting in fast prints that only have a single wall. For best results, experiment with increasing your Line Width.</h3>\
                    <h3>This will enable a setting called \"Spiralize Outer Contour\". You can find this setting in the \"Special Modes\" section of the \
                    Custom menu.</h3>")

    function onEnableSectionChanged(state)
    {
        vaseModeEnabled.setPropertyValue("value", state)
    }

    property UM.SettingPropertyProvider vaseModeEnabled: UM.SettingPropertyProvider
    {
        id: vaseModeEnabled
        containerStack: Cura.MachineManager.activeMachine
        key: "magic_spiralize"
        watchedProperties: [ "value", "enabled", "description" ]
        storeIndex: 0
    }

    contents: []
}
