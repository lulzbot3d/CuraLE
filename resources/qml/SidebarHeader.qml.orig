// Copyright (c) 2017 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1

import UM 1.2 as UM
import Cura 1.0 as Cura

import "Menus"
import "Preferences"

Column
{
    id: base;

    property int currentExtruderIndex: Cura.ExtruderManager.activeExtruderIndex;
    property bool currentExtruderVisible: extrudersList.visible;

    spacing: Math.floor(UM.Theme.getSize("sidebar_margin").width * 0.9)

    signal showTooltip(Item item, point location, string text)
    signal hideTooltip()

    Item
    {
        anchors
        {
            left: parent.left
            right: parent.right
        }
        visible: extruderSelectionRow.visible
        height: UM.Theme.getSize("default_lining").height
        width: height
    }

    // Extruder Row
    Item
    {
        id: extruderSelectionRow
        width: parent.width
        height: Math.floor(UM.Theme.getSize("sidebar_tabs").height * 2 / 3)
        visible: machineExtruderCount.properties.value > 1 && !sidebar.monitoringPrint

        anchors
        {
            left: parent.left
            leftMargin: Math.floor(UM.Theme.getSize("sidebar_margin").width * 0.7)
            right: parent.right
            rightMargin: Math.floor(UM.Theme.getSize("sidebar_margin").width * 0.7)
            topMargin: UM.Theme.getSize("sidebar_margin").height
        }

        ListView
        {
            id: extrudersList
            property var index: 0
            height: UM.Theme.getSize("sidebar_header_mode_tabs").height
            width: Math.floor(parent.width)
            boundsBehavior: Flickable.StopAtBounds
            anchors
            {
                left: parent.left
                leftMargin: Math.floor(UM.Theme.getSize("default_margin").width / 2)
                right: parent.right
                rightMargin: Math.floor(UM.Theme.getSize("default_margin").width / 2)
                verticalCenter: parent.verticalCenter
            }

            ExclusiveGroup { id: extruderMenuGroup; }

            orientation: ListView.Horizontal

            model: Cura.ExtrudersModel { id: extrudersModel; }

            Connections
            {
                target: Cura.MachineManager
                onGlobalContainerChanged: forceActiveFocus() // Changing focus applies the currently-being-typed values so it can change the displayed setting values.
            }

            delegate: Button
            {
                height: ListView.view.height
                width: ListView.view.width / extrudersModel.rowCount()

                text: model.name
                tooltip: model.name
                exclusiveGroup: extruderMenuGroup
                checked: base.currentExtruderIndex == index

                onClicked:
                {
                    forceActiveFocus() // Changing focus applies the currently-being-typed values so it can change the displayed setting values.
                    Cura.ExtruderManager.setActiveExtruderIndex(index);
                }

                style: ButtonStyle
                {
                    background: Item
                    {
                        Rectangle
                        {
                            anchors.fill: parent
                            border.width: control.checked ? UM.Theme.getSize("default_lining").width * 2 : UM.Theme.getSize("default_lining").width
                            border.color: (control.checked || control.pressed) ? UM.Theme.getColor("action_button_active_border") :
                                          control.hovered ? UM.Theme.getColor("action_button_hovered_border") :
                                          UM.Theme.getColor("action_button_border")
                            color: (control.checked || control.pressed) ? UM.Theme.getColor("action_button_active") :
                                   control.hovered ? UM.Theme.getColor("action_button_hovered") :
                                   UM.Theme.getColor("action_button")
                            Behavior on color { ColorAnimation { duration: 50; } }
                        }

                        Item
                        {
                            id: extruderButtonFace
                            anchors.centerIn: parent
                            width: {
                                var extruderTextWidth = extruderStaticText.visible ? extruderStaticText.width : 0;
                                var iconWidth = extruderIconItem.width;
                                return Math.floor(extruderTextWidth + iconWidth + UM.Theme.getSize("default_margin").width / 2);
                            }

                            // Static text "Extruder"
                            Label
                            {
                                id: extruderStaticText
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left

                                color: (control.checked || control.pressed) ? UM.Theme.getColor("action_button_active_text") :
                                       control.hovered ? UM.Theme.getColor("action_button_hovered_text") :
                                       UM.Theme.getColor("action_button_text")

                                font: UM.Theme.getFont("large_nonbold")
                                text: catalog.i18nc("@label", "Extruder")
                                visible: width < (control.width - extruderIconItem.width - UM.Theme.getSize("default_margin").width)
                                elide: Text.ElideRight
                            }

                            // Everthing for the extruder icon
                            Item
                            {
                                id: extruderIconItem
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right

                                property var sizeToUse:
                                {
                                    var minimumWidth = control.width < UM.Theme.getSize("button").width ? control.width : UM.Theme.getSize("button").width;
                                    var minimumHeight = control.height < UM.Theme.getSize("button").height ? control.height : UM.Theme.getSize("button").height;
                                    var minimumSize = minimumWidth < minimumHeight ? minimumWidth : minimumHeight;
                                    minimumSize -= Math.floor(UM.Theme.getSize("default_margin").width / 2);
                                    return minimumSize;
                                }

                                width: sizeToUse
                                height: sizeToUse

                                UM.RecolorImage {
                                    id: mainCircle
                                    anchors.fill: parent

                                    sourceSize.width: parent.width
                                    sourceSize.height: parent.width
                                    source: UM.Theme.getIcon("extruder_button")

                                    color: extruderNumberText.color
                                }

                                Label
                                {
                                    id: extruderNumberText
                                    anchors.centerIn: parent
                                    text: index + 1;
                                    color: (control.checked || control.pressed) ? UM.Theme.getColor("action_button_active_text") :
                                           control.hovered ? UM.Theme.getColor("action_button_hovered_text") :
                                           UM.Theme.getColor("action_button_text")
                                    font: UM.Theme.getFont("default_bold")
                                }

                                // Material colour circle
                                // Only draw the filling colour of the material inside the SVG border.
                                Rectangle
                                {
                                    id: materialColorCircle

                                    anchors
                                    {
                                        right: parent.right
                                        top: parent.top
                                        rightMargin: parent.sizeToUse * 0.01
                                        topMargin: parent.sizeToUse * 0.05
                                    }

                                    color: model.color

                                    width: parent.width * 0.35
                                    height: parent.height * 0.35
                                    radius: width / 2

                                    border.width: 1
                                    border.color: UM.Theme.getColor("extruder_button_material_border")

                                    opacity: !control.checked ? 0.6 : 1.0
                                }
                            }
                        }
                    }
                    label: Item {}
                }
            }
        }
    }

    Item
    {
        id: variantRowSpacer
        height: UM.Theme.getSize("sidebar_margin").height / 4
        width: height
        visible: !extruderSelectionRow.visible
    }

    Row
    {
        id: categoryRow

        height: UM.Theme.getSize("sidebar_setup").height
        visible: Cura.MachineManager.hasMaterials && !sidebar.monitoringPrint && !sidebar.hideSettings

        anchors
        {
            left: parent.left
            leftMargin: UM.Theme.getSize("sidebar_margin").width
            right: parent.right
            rightMargin: UM.Theme.getSize("sidebar_margin").width
        }

        Label
        {
            id: categoryLabel
            text: "Category"

            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.45 - UM.Theme.getSize("sidebar_margin").width
            font: UM.Theme.getFont("default");
            color: UM.Theme.getColor("text");
        }

        ToolButton {
            id: categorySelection
            text: Cura.MachineManager.currentCategory
            tooltip: Cura.MachineManager.currentCategory
            anchors.verticalCenter: parent.verticalCenter

            height: UM.Theme.getSize("setting_control").height
            width: parent.width * 0.55 + UM.Theme.getSize("sidebar_margin").width
            style: UM.Theme.styles.sidebar_header_button
            activeFocusOnPress: true;

            menu: CategoryMenu {}
        }
    }

    Row
    {
        id: materialRow
        height: UM.Theme.getSize("sidebar_setup").height
        visible: Cura.MachineManager.hasMaterials && !sidebar.monitoringPrint && !sidebar.hideSettings

        anchors
        {
            left: parent.left
            leftMargin: UM.Theme.getSize("sidebar_margin").width
            right: parent.right
            rightMargin: UM.Theme.getSize("sidebar_margin").width
        }

        Label
        {
            id: materialLabel
            text: catalog.i18nc("@label","Material");
            width: parent.width * 0.45 - UM.Theme.getSize("sidebar_margin").width - infoButton.width
            font: UM.Theme.getFont("default");
            color: UM.Theme.getColor("text");
        }

        Item
        {
            width: UM.Theme.getSize("setting_control").height
            height: UM.Theme.getSize("setting_control").height

            UM.SimpleButton
            {
                id: infoButton

                color: hovered ? UM.Theme.getColor("text") : UM.Theme.getColor("info_button");
                iconSource: UM.Theme.getIcon("notice");

                anchors.fill: parent
                visible: Cura.MachineManager.currentMaterialHasInfo

                onClicked:
                {
                    Cura.MachineManager.openCurrentMaterialInfo()
                }
                onEntered:
                {
                    var content = catalog.i18nc("@tooltip", "Material Info")
                    base.showTooltip(materialRow, Qt.point(-UM.Theme.getSize("default_margin").width, parent.height/4),  content)
                }
                onExited: base.hideTooltip()
            }
        }

        ToolButton
        {
            id: materialSelection

            text: Cura.MachineManager.activeMaterialName
            tooltip: Cura.MachineManager.activeMaterialName
            visible: Cura.MachineManager.hasMaterials
            enabled: !extrudersList.visible || base.currentExtruderIndex  > -1
            height: UM.Theme.getSize("setting_control").height
            width: parent.width * 0.55 + UM.Theme.getSize("sidebar_margin").width
            style: UM.Theme.styles.sidebar_header_button
            activeFocusOnPress: true;
            menu: MaterialMenu {
                extruderIndex: base.currentExtruderIndex
            }

            property var valueError: !isMaterialSupported()
            property var valueWarning: ! Cura.MachineManager.isActiveQualitySupported

            function isMaterialSupported () {
                return Cura.ContainerManager.getContainerMetaDataEntry(Cura.MachineManager.activeMaterialId, "compatible") == "True"
            }
        }
    }
    Row
    {
        id: adhesionRow

        height: UM.Theme.getSize("sidebar_setup").height*4
        visible: (Cura.MachineManager.hasVariants || Cura.MachineManager.hasMaterials) && !sidebar.monitoringPrint && !sidebar.hideSettings && Cura.ContainerManager.getContainerMetaDataEntry(Cura.MachineManager.activeMaterialId ,"adhesion_info") != ""

        anchors
        {
            left: parent.left
            leftMargin: UM.Theme.getSize("sidebar_margin").width
            right: parent.right
            rightMargin: UM.Theme.getSize("sidebar_margin").width
        }

        Label
        {
            height: parent.rowHeight;
            verticalAlignment: Qt.AlignVCenter;
            text: catalog.i18nc("@label", "Adhesion Info")

            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.45 - UM.Theme.getSize("sidebar_margin").width
            font: UM.Theme.getFont("default");
            color: UM.Theme.getColor("text");
        }

        TextArea
        {
            text: Cura.ContainerManager.getContainerMetaDataEntry(Cura.MachineManager.activeMaterialId ,"adhesion_info")
            wrapMode: Text.WordWrap;
            readOnly: true;
            selectByKeyboard: false
            selectByMouse: false
            menu: null

            width: parent.width * 0.55 + UM.Theme.getSize("sidebar_margin").width
            height: parent.height;
            font: UM.Theme.getFont("default");
        }
    }
    //Variant row
    Item
    {
        id: variantRow
        height: UM.Theme.getSize("sidebar_setup").height
        visible: Cura.MachineManager.hasVariants && !sidebar.monitoringPrint && !sidebar.hideSettings

        anchors
        {
            left: parent.left
            leftMargin: UM.Theme.getSize("sidebar_margin").width
            right: parent.right
            rightMargin: UM.Theme.getSize("sidebar_margin").width
        }

        Label
        {
            id: variantLabel
            text: Cura.MachineManager.activeDefinitionVariantsName;
            width: parent.width * 0.45 - UM.Theme.getSize("sidebar_margin").width
            font: UM.Theme.getFont("default");
            color: UM.Theme.getColor("text");
        }

        ToolButton {
            id: variantSelection
            text: Cura.MachineManager.activeVariantName
            tooltip: Cura.MachineManager.activeVariantName;
            visible: Cura.MachineManager.hasVariants

            height: UM.Theme.getSize("setting_control").height
            width: parent.width * 0.55 + UM.Theme.getSize("sidebar_margin").width
            style: UM.Theme.styles.sidebar_header_button
            activeFocusOnPress: true;

            menu: NozzleMenu { extruderIndex: base.currentExtruderIndex }
        }
    }

    // Material info row
    Item
    {
        id: materialInfoRow
        height: Math.floor(UM.Theme.getSize("sidebar_setup").height / 2)
        visible: (Cura.MachineManager.hasVariants || Cura.MachineManager.hasMaterials) && !sidebar.monitoringPrint && !sidebar.hideSettings && !Cura.MachineManager.isCurrentSetupSupported

        anchors
        {
            left: parent.left
            leftMargin: UM.Theme.getSize("sidebar_margin").width
            right: parent.right
            rightMargin: UM.Theme.getSize("sidebar_margin").width
        }

        Item {
            height: UM.Theme.getSize("sidebar_setup").height
            anchors.right: parent.right
            width: Math.floor(parent.width * 0.7 + UM.Theme.getSize("sidebar_margin").width)

            UM.RecolorImage {
                id: warningImage
                anchors.right: parent.right
                anchors.rightMargin: UM.Theme.getSize("default_margin").width
                anchors.verticalCenter: parent.Bottom
                source: UM.Theme.getIcon("warning")
                width: UM.Theme.getSize("section_icon").width
                height: UM.Theme.getSize("section_icon").height
                color: UM.Theme.getColor("material_compatibility_warning")
            }
        }
    }

    Item
    {
        id: globalProfileRow
        height: UM.Theme.getSize("sidebar_setup").height
        visible: !sidebar.monitoringPrint && !sidebar.hideSettings

        anchors
        {
            left: parent.left
            leftMargin: UM.Theme.getSize("sidebar_margin").width
            right: parent.right
            rightMargin: UM.Theme.getSize("sidebar_margin").width
        }

        Label
        {
            id: globalProfileLabel
            text: catalog.i18nc("@label","Profile");
            width: Math.floor(parent.width * 0.45 - UM.Theme.getSize("sidebar_margin").width - 2)
            font: UM.Theme.getFont("default");
            color: UM.Theme.getColor("text");
            verticalAlignment: Text.AlignVCenter
            anchors.top: parent.top
            anchors.bottom: parent.bottom
        }

        ToolButton
        {
            id: globalProfileSelection

            text: generateActiveQualityText()
            enabled: !header.currentExtruderVisible || header.currentExtruderIndex > -1
            width: Math.floor(parent.width * 0.55)
            height: UM.Theme.getSize("setting_control").height
            anchors.left: globalProfileLabel.right
            anchors.right: parent.right
            tooltip: Cura.MachineManager.activeQualityName
            style: UM.Theme.styles.sidebar_header_button
            activeFocusOnPress: true
            menu: ProfileMenu { }

            function generateActiveQualityText () {
                var result = Cura.MachineManager.currentQualityName;

                if (Cura.MachineManager.isActiveQualitySupported) {
                    if (Cura.MachineManager.activeQualityLayerHeight > 0) {
                        result += " <font color=\"" + UM.Theme.getColor("text_detail") + "\">"
                        result += " - "
                        result += Cura.MachineManager.activeQualityLayerHeight.toFixed(3) + "mm"
                        result += "</font>"
                    }
                }

                return result
            }

            UM.SimpleButton
            {
                id: customisedSettings

                visible: Cura.MachineManager.hasUserSettings
                height: Math.floor(parent.height * 0.6)
                width: Math.floor(parent.height * 0.6)

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: UM.Theme.getSize("setting_preferences_button_margin").width - UM.Theme.getSize("sidebar_margin").width

                color: hovered ? UM.Theme.getColor("setting_control_button_hover") : UM.Theme.getColor("setting_control_button");
                iconSource: UM.Theme.getIcon("star");

                onClicked:
                {
                    forceActiveFocus();
                    Cura.Actions.manageProfiles.trigger()
                }
                onEntered:
                {
                    var content = catalog.i18nc("@tooltip","Some setting/override values are different from the values stored in the profile.\n\nClick to open the profile manager.")
                    base.showTooltip(globalProfileRow, Qt.point(-UM.Theme.getSize("sidebar_margin").width, 0),  content)
                }
                onExited: base.hideTooltip()
            }
        }
    }


    UM.SettingPropertyProvider
    {
        id: machineExtruderCount

        containerStackId: Cura.MachineManager.activeMachineId
        key: "machine_extruder_count"
        watchedProperties: [ "value" ]
        storeIndex: 0
    }

    UM.I18nCatalog { id: catalog; name:"cura" }
}
