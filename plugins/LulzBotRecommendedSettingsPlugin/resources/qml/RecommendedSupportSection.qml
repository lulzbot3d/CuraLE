// Copyright (c) 2020 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3

import UM 1.2 as UM
import Cura 1.0 as Cura


//
//  Enable support
//
RecommendedSettingSection {
    id: enableSupportRow
    title: catalog.i18nc("@label", "Support")
    icon: UM.Theme.getIcon("Support")
    enableSectionSwitchVisible: supportEnabled.properties.enabled == "True"
    enableSectionSwitchChecked: supportEnabled.properties.value == "True"
    enableSectionSwitchEnabled: recommendedPrintSetup.settingsEnabled
    tooltipText: catalog.i18nc("@label", "<h3>Generate structures to support parts of the model which have overhangs. \
                    Without these structures, these parts would collapse during printing.")

    function onEnableSectionChanged(state) {
        supportEnabled.setPropertyValue("value", state)
    }

    property UM.SettingPropertyProvider supportEnabled: UM.SettingPropertyProvider {
        id: supportEnabled
        containerStack: Cura.MachineManager.activeMachine
        key: "support_enable"
        watchedProperties: [ "value", "enabled", "description" ]
        storeIndex: 0
    }

    UM.SettingPropertyProvider {
        id: supportExtruderProvider
        key: "support_extruder_nr"
        containerStack: Cura.MachineManager.activeMachine
        watchedProperties: [ "value" ]
        storeIndex: 0
    }

    contents: [

        RecommendedSettingItem {
            Layout.preferredHeight: childrenRect.height
            settingName: catalog.i18nc("@action:label", "Print with")
            tooltipText: catalog.i18nc("@label", "The extruder train to use for printing the support. This is used in multi-extrusion.")
            // Hide this component when there is only one extruder
            enabled: Cura.ExtruderManager.enabledExtruderCount > 1
            visible: Cura.ExtruderManager.enabledExtruderCount > 1
            isCompressed: enableSupportRow.isCompressed || Cura.ExtruderManager.enabledExtruderCount <= 1

            settingControl: Cura.SingleSettingExtruderSelectorBar
            {
                extruderSettingName: "support_extruder_nr"
                onSelectedIndexChanged:
                {
                    support.updateAllExtruders = true
                    support.forceUpdateSettings()
                    support.updateAllExtruders = false
                }
            }
        },

        RecommendedSettingItem {
            settingName: catalog.i18nc("@action:label", "Overhang Angle (°)")
            tooltipText: catalog.i18nc("@label", "<h3>Adjusts the minimum angle relative to vertical at which supports will begin to be generated. \
                            A higher value will lower the amount of supports generated, but could lead to unsupported overhangs collapsing during printing.</h3>")
            isCompressed: enableSupportRow.isCompressed

            settingControl: Cura.SingleSettingSlider {
                height: UM.Theme.getSize("combobox").height
                width: parent.width
                settingName: "support_angle"
                updateAllExtruders: true
                enabled: supportEnabled.properties.value == "True"

                function updateSetting(value)
                {
                    Cura.MachineManager.setSettingForAllExtruders("support_angle", "value", value)
                }
            }
        },

        RecommendedSettingItem {
            settingName: catalog.i18nc("@action:label", "Support Density (%)")
            tooltipText: catalog.i18nc("@label", "<h3>Set the percentage of support density.</h3>")
            isCompressed: enableSupportRow.isCompressed

            settingControl: Cura.SingleSettingSlider {
                height: UM.Theme.getSize("combobox").height
                width: parent.width
                settingName: "support_infill_rate"
                updateAllExtruders: true
                enabled: supportEnabled.properties.value == "True"

                function updateSetting(value) {
                    Cura.MachineManager.setSettingForAllExtruders("support_infill_rate", "value", value)
                    Cura.MachineManager.resetSettingForAllExtruders("support_line_distance")
                }
            }
        },

        RecommendedSettingItem {
            settingName: catalog.i18nc("@action:label", "Join Distance (mm)")
            tooltipText: catalog.i18nc("@label", "<h3>Set the distance in millimeters under which separate support structures will join \
                            together. Increasing this setting can help with issues regarding failure of many small support structures around a print.</h3>")
            isCompressed: enableSupportRow.isCompressed

            settingControl: SpinBox {
                id: joinDistanceSpinBox

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

                UM.SettingPropertyProvider {
                    id: supportJoinDistance
                    containerStackId: Cura.MachineManager.activeStack.id
                    key: "support_join_distance"
                    watchedProperties: [ "value" ]
                    storeIndex: 0
                }
            }
        },

        RecommendedSettingItem {
            settingName: catalog.i18nc("@action:label", "Support Roof")
            tooltipText: catalog.i18nc("@label", "<h3>Generate a dense slab of material between the top of support and the model. \
                            This will create a skin between the model and support.</h3>")
            isCompressed: enableSupportRow.isCompressed

            settingControl: CheckBox {
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
    ]
}
