// Copyright (c) 2023 Fargo Additive Manufacturing Equipment 3D, LLC.
// Cura LE is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls

import UM 1.2 as UM
import Cura 1.0 as Cura


//
//  Z Seam
//
RecommendedSettingSection {
    id: zSeamRow

    title: catalog.i18nc("@label", "Z Seam")
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

        RecommendedSettingItem {
            settingName: catalog.i18nc("@action:label", "Z Seam Type")
            tooltipText: catalog.i18nc("@label", "Starting point of each path in a layer. When paths in consecutive layers start at the same point a vertical seam may show on the print. When aligning these near a user specified location, the seam is easiest to remove. When placed randomly the inaccuracies at the paths' start will be less noticeable. When taking the shortest path the print will be quicker.")
            isCompressed: zSeamRow.isCompressed

            settingControl: Cura.SingleSettingComboBox {
                width: parent.width
                settingName: "z_seam_type"
                updateAllExtruders: true
            }
        },

        RecommendedSettingItem {
            settingName: catalog.i18nc("@action:label", "Z Seam Position")
            tooltipText: catalog.i18nc("@label", "The position near where to start printing each part in a layer.")
            isCompressed: zSeamRow.isCompressed

            settingControl: Cura.SingleSettingComboBox {
                width: parent.width
                settingName: "z_seam_position"
                updateAllExtruders: true
            }
        }
    ]
}
