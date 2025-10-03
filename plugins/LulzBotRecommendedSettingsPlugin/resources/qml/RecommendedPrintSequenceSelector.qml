// Copyright (c) 2018 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls

import UM 1.2 as UM
import Cura 1.0 as Cura


//
//  Print Sequence
//
RecommendedSettingSection {
    id: printSequenceRow

    title: catalog.i18nc("@label", "Multi-Part")
    icon: UM.Theme.getIcon("")
    enableSectionSwitchVisible: false
    enableSectionSwitchChecked: true
    enableSectionSwitchEnabled: false
    tooltipText: catalog.i18nc("@label", "<h3>FOR ADVANCED USE ONLY</h3><h3>Set whether to print all parts on the build plate \"All at Once\" or \"One at a Time\". \
                    Note that if you print parts \"One at a Time\", special care should be taken to ensure the Tool Head does not \
                    run into pieces that have been completed. This can be done by previewing the gcode and ensuring parts print \
                    in the order intended.</h3>")

    contents: [
        RecommendedSettingItem {
            id: printSequenceContainer
            settingName: catalog.i18nc("@action:label", "Print Sequence")
            tooltipText: catalog.i18nc("@label", "Starting point of each path in a layer. When paths in consecutive layers start at the same point a vertical seam may show on the print. When aligning these near a user specified location, the seam is easiest to remove. When placed randomly the inaccuracies at the paths' start will be less noticeable. When taking the shortest path the print will be quicker.")
            isCompressed: printSequenceRow.isCompressed

            settingControl: Cura.SingleSettingComboBox {
                width: parent.width
                settingName: "print_sequence"
                updateAllExtruders: true
            }
        }
    ]
}
