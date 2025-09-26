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

    title: catalog.i18nc("@label", "Z Seam Alignment")
    icon: UM.Theme.getIcon("Zipper")
    enableSectionSwitchVisible: false //supportEnabled.properties.enabled == "True"
    enableSectionSwitchChecked: true //supportEnabled.properties.value == "True"
    enableSectionSwitchEnabled: false //recommendedPrintSetup.settingsEnabled
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
            tooltipText: catalog.i18nc("@label", "Chooses between the techniques available to generate support. \n\n\"Normal\" support creates a support structure directly below the overhanging parts and drops those areas straight down. \n\n\"Tree\" support creates branches towards the overhanging areas that support the model on the tips of those branches, and allows the branches to crawl around the model to support it from the build plate as much as possible.")
            isCompressed: zSeamRow.isCompressed

            settingControl: Cura.ComboBoxWithOptions {
                id: zSeamAlignmentComboBox
                containerStackId: Cura.ExtruderManager.activeExtruderStackId
                settingKey: "z_seam_type"
                controlWidth: zSeamAlignmentContainer.width
            }


        }

        Binding {
            target: zSeamPositionContainer
            property: "visible"
            value: {
                return (zSeamType.properties.value == "back")
            }
        }

        RecommendedSettingItem {
            id: zSeamPositionContainer

            Cura.ComboBoxWithOptions {
                id: zSeamPositionComboBox
                containerStackId: Cura.ExtruderManager.activeExtruderStackId
                settingKey: "z_seam_position"
                controlWidth: zSeamPositionContainer.width
                // useInBuiltTooltip: false
            }
        }
    ]
}
