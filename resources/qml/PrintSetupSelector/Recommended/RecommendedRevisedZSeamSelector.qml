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
    property bool alive: Cura.MachineManager.activeMachine != null

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
                    catalog.i18nc("@label", 'Select where the Z Seam of the print will be generated. The "Z Seam" refers to the point on the outer walls of your print where the layer starts and ends. These layer transitions can often leave a small bump or dip that can affect the cosmetics of the finished part. "Shortest" will prioritize print speed; "Random" will place the seam in a random place each layer, which reduces its prominence; "Sharpest Corner" attempts to place the seam in the sharpest corner of the print, which tends to disguise it well; and "User Specified" will allow you to choose which side of the print the seam is generated on.'))
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
            containerStackId: alive ? Cura.MachineManager.activeMachine.id : null
            settingKey: "z_seam_type"
            controlWidth: zSeamAlignmentContainer.width
            useInBuiltTooltip: false
            // settingStoreIndex: 0
            // setValueFunction: function setFunction(newValue) {
            //     Cura.MachineManager.setSettingForAllExtruders("z_seam_type", "value", newValue)
            // }
        }

        // Cura.ComboBox {
        //     id: zSeamAlignmentComboBox
        //     width: zSeamAlignmentContainer.width
        //     height: UM.Theme.getSize("setting_control").height
        //     model: zSeamTypeOptionsModel
        //     textRole: "text"

        //     currentIndex: {
        //         var currentValue = zSeamType.properties.value
        //         var index = 0
        //         for (var i = 0; i < model.count; i++)
        //         {
        //             if (model.get(i).value == currentValue)
        //             {
        //                 index = i
        //                 break
        //             }
        //         }
        //         return index
        //     }

        //     onActivated: {
        //         let newValue = model.get(index).value
        //         console.log(newValue)
        //         console.log(zSeamType.properties.value)
        //         if (zSeamType.properties.value == newValue) {
        //             console.log("Same value, not attempting to change")
        //             return
        //         }

        //         var active_mode = UM.Preferences.getValue("cura/active_mode")
        //         if (active_mode == 0 || active_mode == "simple") {
        //             //zSeamType.setPropertyValue("value", newValue)
        //             Cura.MachineManager.setSettingForAllExtruders("z_seam_type", "value", newValue)
        //         }
        //     }

        //     Binding {
        //         target: zSeamAlignmentComboBox
        //         property: "currentIndex"
        //         value: {
        //             var currentValue = zSeamType.properties.value
        //             //console.log("Current Value: " + currentValue)
        //             var index = 0
        //             for (var i = 0; i < zSeamAlignmentComboBox.model.count; i++) {
        //                 if (zSeamAlignmentComboBox.model.get(i).value == currentValue) {
        //                     index = i
        //                     break
        //                 }
        //             }
        //             return index
        //         }
        //     }

        //     ListModel {
        //         id: zSeamTypeOptionsModel

        //         function updateModel() {
        //             clear()
        //             // Options come in as a string-representation of an OrderedDict
        //             if(zSeamType.properties.options) {
        //                 var options = zSeamType.properties.options.match(/^OrderedDict\(\[\((.*)\)\]\)$/);
        //                 if(options) {
        //                     options = options[1].split("), (");
        //                     for(var i = 0; i < options.length; i++) {
        //                         var option = options[i].substring(1, options[i].length - 1).split("', '");
        //                         append({ text: option[1], value: option[0] });
        //                     }
        //                 }
        //             }
        //         }

        //         Component.onCompleted: updateModel()
        //     }

        //     Connections {
        //         target: zSeamType
        //         function onContainerStackChanged() { zSeamTypeOptionsModel.updateModel() }
        //         function onIsValueUsedChanged() { zSeamTypeOptionsModel.updateModel() }
        //     }

        UM.SettingPropertyProvider {
            id: zSeamType
            containerStackId: alive ? Cura.MachineManager.activeMachine.id : null
            key: "z_seam_type"
            watchedProperties: [ "value", "options" ]
            storeIndex: 0
        }
        //}
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
            containerStackId: alive ? Cura.MachineManager.activeMachine.id : null
            settingKey: "z_seam_position"
            controlWidth: zSeamPositionContainer.width
            useInBuiltTooltip: false
        }
    }
}
