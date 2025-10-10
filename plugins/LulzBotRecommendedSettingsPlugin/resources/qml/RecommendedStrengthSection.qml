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
RecommendedSettingSection {
    id: strengthSection

    title: catalog.i18nc("@label", "Strength")
    icon: UM.Theme.getIcon("Hammer")
    enableSectionSwitchVisible: false
    enableSectionSwitchEnabled: false
    tooltipText: catalog.i18nc("@label", "<h3><b>Settings in this section are most important for determining overall part strength.</b></h3>")

    UM.SettingPropertyProvider {
        id: infillSteps
        containerStackId: Cura.MachineManager.activeStackId
        key: "gradual_infill_steps"
        watchedProperties: ["value", "enabled"]
        storeIndex: 0
    }

    contents: [
        //
        // Infill Chunk
        //
        RecommendedSettingItem {
            settingName: catalog.i18nc("@action:label", "Infill Pattern")
            tooltipText: catalog.i18nc("@label", "<h3>Set the pattern used for the infill of your print. \"Grid\" is our recommended pattern as it is relatively efficient \
                            both in print time and plastic usage while still giving your prints good structural integrity. \"Gyroid\" has excellent \
                            compressibility properties. There are additional patterns that may prove useful.</h3>")


            settingControl: Cura.SingleSettingComboBox {
                width: parent.width
                settingName: "infill_pattern"
                updateAllExtruders: true
            }
        },

        RecommendedSettingItem {
            settingName: catalog.i18nc("@action:label", "Infill (%)")
            tooltipText: catalog.i18nc("@label", "<h3>Set the percentage of the interior that will be filled with infill by volume.</h3>")
            settingControl: Cura.SingleSettingSlider {
                height: UM.Theme.getSize("combobox").height
                width: parent.width
                settingName: "infill_sparse_density"
                updateAllExtruders: true
                // disable slider when gradual support is enabled
                enabled: parseInt(infillSteps.properties.value) === 0

                function updateSetting(value) {
                    Cura.MachineManager.setSettingForAllExtruders("infill_sparse_density", "value", value)
                    Cura.MachineManager.resetSettingForAllExtruders("infill_line_distance")
                }
            }
        },

        //
        // Wall Chunk
        //
        RecommendedSettingItem {
            settingName: catalog.i18nc("@action:label", "Wall Count")
            tooltipText: catalog.i18nc("@label", "<h3>Set the number of solid walls that will be generated on the sides of your print. \
                            This number plays a large factor in the overall strength of your part.</h3>")
                            //<h3>In the dropdown to the right, you can select textured walls. This will enable a setting called \"Fuzzy Skin\".\
                            //You can fine-tune this setting in the \"Experimental\" section of the Custom menu.</h3>

            settingControl: Cura.SingleSettingSpinBox {
                settingName: "wall_line_count"
                width: parent.width
                updateAllExtruders: true
            }
        },

        RecommendedSettingItem {
            settingName: catalog.i18nc("@label:action", "Fuzzy Skin")
            tooltipText: catalog.i18nc("@label", "")

            UM.SettingPropertyProvider {
                id: magicFuzzySkin
                containerStackId: Cura.ExtruderManager.activeExtruderStackId
                key: "magic_fuzzy_skin_enabled"
                watchedProperties: [ "value" ]
                storeIndex: 0
            }

            UM.SettingPropertyProvider {
                id: zSeamType
                containerStackId: Cura.ExtruderManager.activeExtruderStackId
                key: "z_seam_type"
                watchedProperties: [ "value" ]
                storeIndex: 0
            }

            settingControl: Cura.ComboBox {
                id: wallFuzzyComboBox
                height: UM.Theme.getSize("combobox").height
                width: parent.width
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
        },

        //
        // Top/Bottom Chunk
        //
        RecommendedSettingItem {
            settingName: catalog.i18nc("@label:action", "Top/Bottom Count")
            tooltipText: catalog.i18nc("@label", "<h3>Set the number of solid layers that will be generated on the top and bottom of your print.</h3> \
                            <h3>In the dropdown to the right, you can also set the pattern that those layers will be created with.</h3>")

            settingControl: SpinBox {
                id: topBottomCountSpinBox

                anchors.verticalCenter: parent.verticalCenter

                height: UM.Theme.getSize("combobox").height
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
        },

        RecommendedSettingItem {
            settingName: catalog.i18nc("@label:action", "Top/Bottom Pattern")
            tooltipText: catalog.i18nc("@label", "")

            settingControl: Cura.SingleSettingComboBox {
                width: parent.width
                settingName: "top_bottom_pattern"
                updateAllExtruders: true
            }
        }
    ]
}
