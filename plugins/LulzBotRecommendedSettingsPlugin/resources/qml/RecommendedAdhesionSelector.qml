// Copyright (c) 2022 UltiMaker
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Layouts 1.3

import UM 1.5 as UM
import Cura 1.7 as Cura


RecommendedSettingSection {
    id: enableAdhesionRow
    title: catalog.i18nc("@label", "Bed Adhesion")
    icon: UM.Theme.getIcon("Adhesion")
    enableSectionSwitchVisible: false
    enableSectionSwitchChecked: true
    enableSectionSwitchEnabled: false
    tooltipText: catalog.i18nc("@label", "<h3>Select a form of bed adhesion. \"Skirt\" is useful for observing adequate bed leveling and z-offsets \
                    prior to the actual print, while \"Brim\" or \"Raft\" are useful for helping ensure a part stays adhered to the bed and can also \
                    potentially help with warping issues. Choosing \"None\" is a way to print to the full extent of the build volume.</h3>")

    contents: [
        RecommendedSettingItem {
            settingName: catalog.i18nc("@action:label", "Adhesion Type")
            tooltipText: catalog.i18nc("@label", "")
            isCompressed: enableAdhesionRow.isCompressed

            settingControl: Cura.SingleSettingComboBox {
                width: parent.width
                settingName: "adhesion_type"
                updateAllExtruders: true
            }
        }
    ]
}
