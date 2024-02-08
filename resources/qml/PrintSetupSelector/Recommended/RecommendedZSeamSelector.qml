// Copyright (c) 2023 Fargo Additive Manufacturing Equipment 3D, LLC.
// Cura LE is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4

import UM 1.2 as UM
import Cura 1.0 as Cura


//
//  Z Seam
//
Item {
    id: zSeamRow
    height: childrenRect.height

    property real labelColumnWidth: Math.round(width / 3)

    Cura.IconWithText {
        id: zSeamRowTitle
        anchors.top: parent.top
        anchors.left: parent.left
        source: UM.Theme.getIcon("Zipper")
        text: catalog.i18nc("@label", "Z Seam Alignment")
        font: UM.Theme.getFont("medium")
        width: labelColumnWidth
        iconSize: UM.Theme.getSize("medium_button_icon").width

        MouseArea {
            id: zSeamMouseArea
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                base.showTooltip(zSeamRowTitle, Qt.point(-zSeamRowTitle.x - UM.Theme.getSize("thick_margin").width, 0),
                    catalog.i18nc("@label", '<h3>Select where the Z Seam of the print will be generated. The "Z Seam" \
                    refers to the point on the outer walls of your print where the layer starts and ends. These layer \
                    transitions can often leave a small bump or dip that can affect the cosmetics of the finished part.</h3> \
                    <h3>"Shortest" will prioritize print speed; "Random" will place the seam in a random place each layer, \
                    which reduces its prominence; "Sharpest Corner" attempts to place the seam in the sharpest corner of \
                    the print, which tends to disguise it well; and "User Specified" will allow you to choose which side \
                    of the print the seam is generated on.</h3>'))
            }
            onExited: base.hideTooltip()
        }
    }

    Item {
        id: zSeamAlignmentContainer
        height: zSeamAlignmentComboBox.height
        width: {
            if (zSeamPositionContainer.visible) {
                return ((parent.width - labelColumnWidth) / 1.75)
            } else { return (parent.width - labelColumnWidth) }
        }

        anchors {
            left: zSeamRowTitle.right
            verticalCenter: zSeamRowTitle.verticalCenter
        }

        Cura.ComboBoxWithOptions {
            id: zSeamAlignmentComboBox
            containerStackId: Cura.ExtruderManager.activeExtruderStackId
            settingKey: "z_seam_type"
            controlWidth: zSeamAlignmentContainer.width
            useInBuiltTooltip: false
        }

        UM.SettingPropertyProvider {
            id: zSeamType
            containerStackId: Cura.ExtruderManager.activeExtruderStackId
            key: "z_seam_type"
            watchedProperties: [ "value", "options" ]
            storeIndex: 0
        }
    }

    Binding {
        target: zSeamPositionContainer
        property: "visible"
        value: {
            return (zSeamType.properties.value == "back")
        }
    }

    Item {
        id: zSeamPositionContainer
        height: zSeamPositionComboBox.height

        visible: false

        anchors {
            left: zSeamAlignmentContainer.right
            leftMargin: UM.Theme.getSize("thin_margin").width
            right: parent.right
            verticalCenter: zSeamRowTitle.verticalCenter
        }

        Cura.ComboBoxWithOptions {
            id: zSeamPositionComboBox
            containerStackId: Cura.ExtruderManager.activeExtruderStackId
            settingKey: "z_seam_position"
            controlWidth: zSeamPositionContainer.width
            useInBuiltTooltip: false
        }
    }
}
