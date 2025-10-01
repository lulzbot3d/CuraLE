// Copyright (c) 2023 Fargo Additive Manufacturing Equipment 3D, LLC.
// Cura LE is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls

import UM 1.2 as UM
import Cura 1.0 as Cura


//
//  Z Seam
//
Cura.RecommendedSettingSection {
    id: zSeamRow

    title: catalog.i18nc("@label", "Z Seam Alignment")
    icon: UM.Theme.getIcon("Zipper")
    enableSectionSwitchVisible: false
    enableSectionSwitchChecked: true
    enableSectionSwitchEnabled: false
    tooltipText: catalog.i18nc("@label", '<h3>Select where the Z Seam of the print will be generated. The "Z Seam" \
                    refers to the point on the outer walls of your print where the layer starts and ends. These layer \
                    transitions can often leave a small bump or dip that can affect the cosmetics of the finished part.</h3> \
                    <h3>"Shortest" will prioritize print speed; "Random" will place the seam in a random place each layer, \
                    which reduces its prominence; "Sharpest Corner" attempts to place the seam in the sharpest corner of \
                    the print, which tends to disguise it well; and "User Specified" will allow you to choose which side \
                    of the print the seam is generated on.</h3>')

    UM.SettingPropertyProvider {
        id: zSeamTypeProvider
        containerStackId: Cura.ExtruderManager.activeExtruderStackId
        key: "z_seam_type"
        watchedProperties: [ "value", "options" ]
        storeIndex: 0
    }

    contents: [

        Cura.RecommendedSettingItem {
            settingName: catalog.i18nc("@action:label", "Z Seam Type")
            tooltipText: catalog.i18nc("@label", "")
            isCompressed: zSeamRow.isCompressed

            settingControl: Cura.SingleSettingComboBox {
                width: parent.width
                settingName: "z_seam_type"
                updateAllExtruders: true
            }
        },

        Cura.RecommendedSettingItem {
            settingName: catalog.i18nc("@action:label", "Z Seam Position")
            tooltipText: catalog.i18nc("@label", "")
            isCompressed: zSeamRow.isCompressed

            settingControl: Cura.SingleSettingComboBox {
                width: parent.width
                settingName: "z_seam_position"
                updateAllExtruders: true
            }
        }
    ]
}
