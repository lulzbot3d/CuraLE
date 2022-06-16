// Copyright (c) 2017 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.8
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.3

import UM 1.2 as UM
import Cura 1.2 as Cura

Item
{
    id: base

    signal showTooltip(Item item, point location, string text);
    signal hideTooltip();

    property Action configureSettings;
    property variant minimumPrintTime: PrintInformation.minimumPrintTime;
    property variant maximumPrintTime: PrintInformation.maximumPrintTime;
    property bool settingsEnabled: Cura.ExtruderManager.activeExtruderStackId || machineExtruderCount.properties.value == 1

    Component.onCompleted: PrintInformation.enabled = true
    Component.onDestruction: PrintInformation.enabled = false
    UM.I18nCatalog { id: catalog; name: "cura" }

    ScrollView
    {
        visible: Cura.MachineManager.activeMachineName != "" // If no printers added then the view is invisible
        anchors.fill: parent
        height: childrenRect.height
        style: UM.Theme.styles.scrollview
        flickableItem.flickableDirection: Flickable.VerticalFlick

        Rectangle
        {
            width: parseInt( UM.Theme.getSize("sidebar").width )
            height: childrenRect.height
            color: UM.Theme.getColor("sidebar")
            anchors.top: parent.top

            //
            // Infill
            //
            Item
            {
                id: infillCellLeft

                anchors.top: parent.top
                anchors.left: parent.left
                width: parseInt(UM.Theme.getSize("sidebar").width * .45 - UM.Theme.getSize("sidebar_margin").width)

                Label
                {
                    id: infillLabel
                    text: catalog.i18nc("@label", "Infill")
                    font: UM.Theme.getFont("default")
                    color: UM.Theme.getColor("text")

                    anchors.top: parent.top
                    anchors.topMargin: parseInt(UM.Theme.getSize("sidebar_margin").height * 1.7)
                    anchors.left: parent.left
                    anchors.leftMargin: UM.Theme.getSize("sidebar_margin").width
                }
            }

            Item
            {
                id: infillCellRight

                height: infillSlider.height + UM.Theme.getSize("sidebar_margin").height + enableGradualInfillCheckBox.visible * (enableGradualInfillCheckBox.height + UM.Theme.getSize("sidebar_margin").height)
                width: parseInt(UM.Theme.getSize("sidebar").width * .55)

                anchors.left: infillCellLeft.right
                anchors.top: infillCellLeft.top
                anchors.topMargin: UM.Theme.getSize("sidebar_margin").height

                Label {
                    id: selectedInfillRateText

                    //anchors.top: parent.top
                    anchors.left: infillSlider.left
                    anchors.leftMargin: parseInt((infillSlider.value / infillSlider.stepSize) * (infillSlider.width / (infillSlider.maximumValue / infillSlider.stepSize)) - 10 * screenScaleFactor)
                    anchors.right: parent.right

                    text: parseInt(infillDensity.properties.value) + "%"
                    horizontalAlignment: Text.AlignLeft

                    color: infillSlider.enabled ? UM.Theme.getColor("quality_slider_available") : UM.Theme.getColor("quality_slider_unavailable")
                }

                // We use a binding to make sure that after manually setting infillSlider.value it is still bound to the property provider
                Binding {
                    target: infillSlider
                    property: "value"
                    value: parseInt(infillDensity.properties.value)
                }

                Slider
                {
                    id: infillSlider

                    anchors.top: selectedInfillRateText.bottom
                    anchors.left: parent.left
                    anchors.right: infillIcon.left
                    anchors.rightMargin: UM.Theme.getSize("sidebar_margin").width

                    height: UM.Theme.getSize("sidebar_margin").height
                    width: parseInt(infillCellRight.width - UM.Theme.getSize("sidebar_margin").width - style.handleWidth)

                    minimumValue: 0
                    maximumValue: 100
                    stepSize: 1
                    tickmarksEnabled: true

                    // disable slider when gradual support is enabled
                    enabled: parseInt(infillSteps.properties.value) == 0

                    // set initial value from stack
                    value: parseInt(infillDensity.properties.value)

                    onValueChanged: {

                        // Don't round the value if it's already the same
                        if (parseInt(infillDensity.properties.value) == infillSlider.value) {
                            return
                        }

                        // Round the slider value to the nearest multiple of 10 (simulate step size of 10)
                        var roundedSliderValue = Math.round(infillSlider.value / 10) * 10

                        // Update the slider value to represent the rounded value
                        infillSlider.value = roundedSliderValue

                        // Explicitly cast to string to make sure the value passed to Python is an integer.
                        infillDensity.setPropertyValue("value", String(roundedSliderValue))
                    }

                    style: SliderStyle
                    {
                        groove: Rectangle {
                            id: groove
                            implicitWidth: 200 * screenScaleFactor
                            implicitHeight: 2 * screenScaleFactor
                            color: control.enabled ? UM.Theme.getColor("quality_slider_available") : UM.Theme.getColor("quality_slider_unavailable")
                            radius: 1
                        }

                        handle: Item {
                            Rectangle {
                                id: handleButton
                                anchors.centerIn: parent
                                color: control.enabled ? UM.Theme.getColor("quality_slider_available") : UM.Theme.getColor("quality_slider_unavailable")
                                implicitWidth: 10 * screenScaleFactor
                                implicitHeight: 10 * screenScaleFactor
                                radius: 10 * screenScaleFactor
                            }
                        }

                        tickmarks: Repeater {
                            id: repeater
                            model: control.maximumValue / control.stepSize + 1

                            // check if a tick should be shown based on it's index and wether the infill density is a multiple of 10 (slider step size)
                            function shouldShowTick (index) {
                                if (index % 10 == 0) {
                                    return true
                                }
                                return false
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                color: control.enabled ? UM.Theme.getColor("quality_slider_available") : UM.Theme.getColor("quality_slider_unavailable")
                                width: 1 * screenScaleFactor
                                height: 6 * screenScaleFactor
                                y: 0
                                x: styleData.handleWidth / 2 + index * ((repeater.width - styleData.handleWidth) / (repeater.count-1))
                                visible: shouldShowTick(index)
                            }
                        }
                    }
                }

                Rectangle
                {
                    id: infillIcon

                    width: (parent.width / 5) - (UM.Theme.getSize("sidebar_margin").width)
                    height: width

                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: parseInt(UM.Theme.getSize("sidebar_margin").height / 2)

                    // we loop over all density icons and only show the one that has the current density and steps
                    Repeater
                    {
                        id: infillIconList
                        model: infillModel
                        anchors.fill: parent

                        function activeIndex () {
                            for (var i = 0; i < infillModel.count; i++) {
                                var density = parseInt(infillDensity.properties.value)
                                var steps = parseInt(infillSteps.properties.value)
                                var infillModelItem = infillModel.get(i)

                                if (infillModelItem != "undefined"
                                    && density >= infillModelItem.percentageMin
                                    && density <= infillModelItem.percentageMax
                                    && steps >= infillModelItem.stepsMin
                                    && steps <= infillModelItem.stepsMax
                                ){
                                    return i
                                }
                            }
                            return -1
                        }

                        Rectangle
                        {
                            anchors.fill: parent
                            visible: infillIconList.activeIndex() == index

                            border.width: UM.Theme.getSize("default_lining").width
                            border.color: UM.Theme.getColor("quality_slider_unavailable")

                            UM.RecolorImage {
                                anchors.fill: parent
                                anchors.margins: 2 * screenScaleFactor
                                sourceSize.width: width
                                sourceSize.height: width
                                source: UM.Theme.getIcon(model.icon)
                                color: UM.Theme.getColor("quality_slider_unavailable")
                            }
                        }
                    }
                }

                //  Gradual Support Infill Checkbox
                CheckBox {
                    id: enableGradualInfillCheckBox
                    property alias _hovered: enableGradualInfillMouseArea.containsMouse

                    anchors.top: infillSlider.bottom
                    anchors.topMargin: parseInt(UM.Theme.getSize("sidebar_margin").height / 2) // closer to slider since it belongs to the same category
                    anchors.left: infillCellRight.left

                    style: UM.Theme.styles.checkbox
                    enabled: base.settingsEnabled
                    visible: baseSettingsLayout.visible ? infillSteps.properties.enabled == "True" : false
                    checked: parseInt(infillSteps.properties.value) > 0

                    MouseArea {
                        id: enableGradualInfillMouseArea

                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: true

                        property var previousInfillDensity: parseInt(infillDensity.properties.value)

                        onClicked: {
                            // Set to 90% only when enabling gradual infill
                            if (parseInt(infillSteps.properties.value) == 0) {
                                previousInfillDensity = parseInt(infillDensity.properties.value)
                                infillDensity.setPropertyValue("value", String(90))
                            } else {
                                infillDensity.setPropertyValue("value", String(previousInfillDensity))
                            }

                            infillSteps.setPropertyValue("value", (parseInt(infillSteps.properties.value) == 0) ? 5 : 0)
                        }

                        onEntered: {
                            base.showTooltip(enableGradualInfillCheckBox, Qt.point(-infillCellRight.x, 0),
                                catalog.i18nc("@label", "Gradual infill will gradually increase the amount of infill towards the top."))
                        }

                        onExited: {
                            base.hideTooltip()
                        }
                    }

                    Label {
                        id: gradualInfillLabel
                        anchors.left: enableGradualInfillCheckBox.right
                        anchors.leftMargin: parseInt(UM.Theme.getSize("sidebar_margin").width / 2)
                        text: catalog.i18nc("@label", "Enable gradual")
                        font: UM.Theme.getFont("default")
                        color: UM.Theme.getColor("text")
                    }
                }

                //  Infill list model for mapping icon
                ListModel
                {
                    id: infillModel
                    Component.onCompleted:
                    {
                        infillModel.append({
                            percentageMin: -1,
                            percentageMax: 0,
                            stepsMin: -1,
                            stepsMax: 0,
                            icon: "hollow"
                        })
                        infillModel.append({
                            percentageMin: 0,
                            percentageMax: 40,
                            stepsMin: -1,
                            stepsMax: 0,
                            icon: "sparse"
                        })
                        infillModel.append({
                            percentageMin: 40,
                            percentageMax: 89,
                            stepsMin: -1,
                            stepsMax: 0,
                            icon: "dense"
                        })
                        infillModel.append({
                            percentageMin: 90,
                            percentageMax: 9999999999,
                            stepsMin: -1,
                            stepsMax: 0,
                            icon: "solid"
                        })
                        infillModel.append({
                            percentageMin: 0,
                            percentageMax: 9999999999,
                            stepsMin: 1,
                            stepsMax: 9999999999,
                            icon: "gradual"
                        })
                    }
                }
            }


            Item
            {
                id: baseSettingsLayout
                anchors.top: infillCellRight.bottom


                visible: !syringeSettings.visible

                height: childrenRect.height

                GridLayout
                {
                    columns: 2
                    rows: 4
                    Label
                    {
                        id: enableSupportLabel
                        visible: enableSupportCheckBox.visible

                        Layout.column: 1
                        Layout.row: 1
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height

                        text: catalog.i18nc("@label", "Generate Support");
                        font: UM.Theme.getFont("default");
                        color: UM.Theme.getColor("text");
                        elide: Text.ElideRight
                    }

                    CheckBox
                    {
                        id: enableSupportCheckBox
                        property alias _hovered: enableSupportMouseArea.containsMouse

                        Layout.column: 2
                        Layout.row: 1
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width

                        style: UM.Theme.styles.checkbox;
                        enabled: base.settingsEnabled

                        visible: supportEnabled.properties.enabled == "True"
                        checked: supportEnabled.properties.value == "True";

                        MouseArea
                        {
                            id: enableSupportMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: true
                            onClicked:
                            {
                                // The value is a string "True" or "False"
                                supportEnabled.setPropertyValue("value", supportEnabled.properties.value != "True");
                            }
                            onEntered:
                            {
                                base.showTooltip(enableSupportCheckBox, Qt.point(-enableSupportCheckBox.x, 0),
                                    catalog.i18nc("@label", "Generate structures to support parts of the model which have overhangs. Without these structures, such parts would collapse during printing."));
                            }
                            onExited:
                            {
                                base.hideTooltip();
                            }
                        }
                    }

                    Label
                    {
                        id: supportExtruderLabel
                        visible: supportExtruderCombobox.visible

                        Layout.column: 1
                        Layout.row: 2
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height

                        text: catalog.i18nc("@label", "Support Extruder");
                        font: UM.Theme.getFont("default");
                        color: UM.Theme.getColor("text");
                        elide: Text.ElideRight
                    }

                    ComboBox
                    {
                        id: supportExtruderCombobox
                        visible: enableSupportCheckBox.visible && (supportEnabled.properties.value == "True") && (machineExtruderCount.properties.value > 1)
                        model: extruderModel

                        property string color_override: ""  // for manually setting values
                        property string color:  // is evaluated automatically, but the first time is before extruderModel being filled
                        {
                            var current_extruder = extruderModel.get(currentIndex);
                            color_override = "";
                            if (current_extruder === undefined) return ""
                            return (current_extruder.color) ? current_extruder.color : "";
                        }

                        textRole: "text"  // this solves that the combobox isn't populated in the first time Cura is started

                        Layout.column: 2
                        Layout.row: 2
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width
                        Layout.preferredWidth: UM.Theme.getSize("sidebar").width * .55

                        height: ((supportEnabled.properties.value == "True") && (machineExtruderCount.properties.value > 1)) ? UM.Theme.getSize("setting_control").height : 0

                        Behavior on height { NumberAnimation { duration: 100 } }

                        style: UM.Theme.styles.combobox_color
                        enabled: base.settingsEnabled
                        property alias _hovered: supportExtruderMouseArea.containsMouse

                        currentIndex: supportExtruderNr.properties !== null ? parseFloat(supportExtruderNr.properties.value) : 0
                        onActivated:
                        {
                            // Send the extruder nr as a string.
                            supportExtruderNr.setPropertyValue("value", String(index));
                        }
                        MouseArea
                        {
                            id: supportExtruderMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: base.settingsEnabled
                            acceptedButtons: Qt.NoButton
                            onEntered:
                            {
                                base.showTooltip(supportExtruderCombobox, Qt.point(-supportExtruderCombobox.x, 0),
                                    catalog.i18nc("@label", "Select which extruder to use for support. This will build up supporting structures below the model to prevent the model from sagging or printing in mid air."));
                            }
                            onExited:
                            {
                                base.hideTooltip();
                            }
                        }

                        function updateCurrentColor()
                        {
                            var current_extruder = extruderModel.get(currentIndex);
                            if (current_extruder !== undefined) {
                                supportExtruderCombobox.color_override = current_extruder.color;
                            }
                        }

                    }

                    Label
                    {
                        id: adhesionHelperLabel

                        Layout.column: 1
                        Layout.row: 3
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width

                        width: parent.width * .45 - 3 * UM.Theme.getSize("default_margin").width
                        text: catalog.i18nc("@label", "Build Plate Adhesion");
                        font: UM.Theme.getFont("default");
                        color: UM.Theme.getColor("text");
                        elide: Text.ElideRight
                    }

                    ComboBox
                    {
                        id: adhesionComboBox

                        Layout.column: 2
                        Layout.row: 3
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width
                        Layout.preferredWidth: UM.Theme.getSize("sidebar").width * .55


                        style: UM.Theme.styles.combobox;
                        enabled: base.settingsEnabled

                        model: ListModel {
                            id: cbItems
                            ListElement { text: "Skirt"; type: "skirt" }
                            ListElement { text: "Brim"; type: "brim" }
                            ListElement { text: "Raft"; type: "raft" }
                            ListElement { text: "None"; type: "none" }
                        }

                        onActivated:
                        {
                            var adhesionType = cbItems.get(index).type;
                            platformAdhesionType.setPropertyValue("value", adhesionType);
                        }

                        function updateValue()
                        {
                            var adhesionType = platformAdhesionType.getRawPropertyValue("value");
                            for(var i = 0; i < cbItems.count; i++)
                            {
                                if(cbItems.get(i).type == adhesionType)
                                {
                                    adhesionComboBox.currentIndex = i;
                                    break;
                                }
                            }
                        }

                        Component.onCompleted:
                        {
                            updateValue()
                        }

                        Connections
                        {
                            target: platformAdhesionType
                            onPropertiesChanged:
                            {
                                adhesionComboBox.updateValue()
                            }
                        }

                        Connections
                        {
                            target: Cura.MachineManager
                            onActiveQualityChanged:
                            {
                                adhesionComboBox.updateValue()
                            }
                        }

                        MouseArea
                        {
                            id: adhesionMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: base.settingsEnabled
                            acceptedButtons: Qt.NoButton

                            onEntered:
                            {
                                base.showTooltip(adhesionComboBox, Qt.point(-adhesionComboBox.x, 0),
                                    catalog.i18nc("@label", "Enable printing a brim, skirt, or raft. This will add a flat area around or under your object which is easy to cut off afterwards."));
                            }
                            onExited:
                            {
                                base.hideTooltip();
                            }
                        }
                    }

                    Label
                    {
                        id: adhesionExtruderHelperLabel
                        visible: adhesionExtruderCombobox.visible

                        Layout.column: 1
                        Layout.row: 4
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width

                        text: catalog.i18nc("@label", "Adhesion Extruder");
                        font: UM.Theme.getFont("default");
                        color: UM.Theme.getColor("text");
                    }

                    ComboBox
                    {
                        id: adhesionExtruderCombobox
                        visible: (platformAdhesionType.properties.value == "brim" || platformAdhesionType.properties.value == "raft") && (machineExtruderCount.properties.value > 1)
                        model: extruderModel

                        property string color_override: ""  // for manually setting values
                        property string color:  // is evaluated automatically, but the first time is before extruderModel being filled
                        {
                            var current_extruder = extruderModel.get(currentIndex);
                            color_override = "";
                            if (current_extruder === undefined) return ""
                            return (current_extruder.color) ? current_extruder.color : "";
                        }

                        textRole: "text"  // this solves that the combobox isn't populated in the first time Cura is started

                        Layout.column: 2
                        Layout.row: 4
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width
                        Layout.preferredWidth: UM.Theme.getSize("sidebar").width * .55

                        height: visible ? UM.Theme.getSize("setting_control").height : 0

                        Behavior on height { NumberAnimation { duration: 100 } }

                        style: UM.Theme.styles.combobox_color
                        enabled: base.settingsEnabled
                        property alias _hovered: adhesionExtruderMouseArea.containsMouse

                        currentIndex: adhesionExtruderNr.properties !== null ? parseFloat(adhesionExtruderNr.properties.value) : 0
                        onActivated:
                        {
                            // Send the extruder nr as a string.
                            adhesionExtruderNr.setPropertyValue("value", String(index));
                        }
                        MouseArea
                        {
                            id: adhesionExtruderMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: base.settingsEnabled
                            acceptedButtons: Qt.NoButton
                            onEntered:
                            {
                                base.showTooltip(adhesionExtruderCombobox, Qt.point(-adhesionExtruderCombobox.x, 0),
                                    catalog.i18nc("@label", "The extruder train to use for printing the brim/raft."));
                            }
                            onExited:
                            {
                                base.hideTooltip();
                            }
                        }

                        function updateCurrentColor()
                        {
                            var current_extruder = extruderModel.get(currentIndex);
                            if (current_extruder !== undefined) {
                                adhesionExtruderCombobox.color_override = current_extruder.color;
                            }
                        }

                    }
                    ListModel
                    {
                        id: extruderModel
                        Component.onCompleted: populateExtruderModel()
                    }

                    Cura.ExtrudersModel
                    {
                        id: extruders
                        onModelChanged: populateExtruderModel()
                    }

                    UM.SettingPropertyProvider
                    {
                        id: infillExtruderNumber
                        containerStackId: Cura.MachineManager.activeStackId
                        key: "infill_extruder_nr"
                        watchedProperties: [ "value" ]
                        storeIndex: 0
                    }

                    UM.SettingPropertyProvider
                    {
                        id: infillDensity
                        containerStackId: Cura.MachineManager.activeStackId
                        key: "infill_sparse_density"
                        watchedProperties: [ "value" ]
                        storeIndex: 0
                    }

                    UM.SettingPropertyProvider
                    {
                        id: infillSteps
                        containerStackId: Cura.MachineManager.activeStackId
                        key: "gradual_infill_steps"
                        watchedProperties: ["value", "enabled"]
                        storeIndex: 0
                    }

                    UM.SettingPropertyProvider
                    {
                        id: platformAdhesionType
                        containerStackId: Cura.MachineManager.activeMachineId
                        key: "adhesion_type"
                        watchedProperties: [ "value", "enabled" ]
                        storeIndex: 0
                    }

                    UM.SettingPropertyProvider
                    {
                        id: supportEnabled
                        containerStackId: Cura.MachineManager.activeMachineId
                        key: "support_enable"
                        watchedProperties: [ "value", "enabled", "description" ]
                        storeIndex: 0
                    }

                    UM.SettingPropertyProvider
                    {
                        id: machineExtruderCount
                        containerStackId: Cura.MachineManager.activeMachineId
                        key: "machine_extruder_count"
                        watchedProperties: [ "value" ]
                        storeIndex: 0
                    }

                    UM.SettingPropertyProvider
                    {
                        id: supportExtruderNr
                        containerStackId: Cura.MachineManager.activeMachineId
                        key: "support_extruder_nr"
                        watchedProperties: [ "value" ]
                        storeIndex: 0
                    }
                    UM.SettingPropertyProvider
                    {
                        id: adhesionExtruderNr
                        containerStackId: Cura.MachineManager.activeMachineId
                        key: "adhesion_extruder_nr"
                        watchedProperties: [ "value" ]
                        storeIndex: 0
                    }


                }
            }
        }
        Rectangle
        {
            id: syringeSettings

            visible: Cura.MachineManager.isSyringePrinter

            width: parseInt( UM.Theme.getSize("sidebar").width )
            height: childrenRect.height
            color: UM.Theme.getColor("sidebar")
            anchors.top: parent.top

            Item
            {
                anchors.top: parent.top
                height: childrenRect.height

                GridLayout
                {
                    columns: 2
                    rows: 13

                    Label
                    {
                        id: needleGaugeLabel

                        Layout.column: 1
                        Layout.row: 1
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height

                        text: catalog.i18nc("@label", "Needle Gauge");
                        font: UM.Theme.getFont("default");
                        color: UM.Theme.getColor("text");
                        elide: Text.ElideRight
                    }
                    Item
                    {
                        Layout.column: 2
                        Layout.row: 1
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height
                        Layout.preferredWidth: UM.Theme.getSize("sidebar").width * .4

                        ComboBox
                        {
                            id: needleGaugeCombobox

                            visible: !needleGaugeTextInput.visible

                            style: UM.Theme.styles.combobox;
                            width: UM.Theme.getSize("sidebar").width * .4
                            height: needleGaugeTextInput.height

                            currentIndex:
                            {
                                var needle_gauge = lineWidthPropertyProvider.properties.value
                                if (needle_gauge == 0.60)
                                    return 0
                                else if (needle_gauge == 0.26)
                                    return 1
                                else if (needle_gauge == 0.16)
                                    return 2
                                else
                                    return 3

                            }

                            model: ListModel
                            {
                                id: modelGaugeCombobox
                                ListElement { text: "20 ga (0.60mm)"; type: 0.60 }
                                ListElement { text: "25 ga (0.26mm)"; type: 0.26 }
                                ListElement { text: "30 ga (0.16mm)"; type: 0.16 }
                                ListElement { text: "Custom needle ID (mm)"}
                            }

                            MouseArea
                            {
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: base.settingsEnabled
                                acceptedButtons: Qt.NoButton

                                onEntered:
                                {
                                    base.showTooltip(needleGaugeLabel, Qt.point(-needleGaugeLabel.x, 0),
                                        catalog.i18nc("@label", lineWidthPropertyProvider.properties.description));
                                }
                                onExited:
                                {
                                    base.hideTooltip();
                                }
                            }

                            onActivated:
                            {
                                if(index != 3)
                                {
                                    lineWidthPropertyProvider.setPropertyValue("value", model.get(index).type)
                                }
                            }
                        }

                        Loader
                        {
                            id: needleGaugeTextInput

                            sourceComponent: numericTextFieldWithUnit
                            property string settingKey: "line_width"
                            property string unit: catalog.i18nc("@label", "mm")
                            property int storeIndex: 0
                            property bool isExtruderSetting: true

                            property var mouseAreaBinding: needleGaugeLabel
                            visible: needleGaugeCombobox.currentIndex == 3 ? true : false

                        }
                    }

                    Label
                    {
                        Layout.column: 1
                        Layout.row: 2
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height

                        text: catalog.i18nc("@label", "Syringe Internal Diameter");
                        font: UM.Theme.getFont("default");
                        color: UM.Theme.getColor("text");
                    }
                    Loader
                    {
                        id: syringeInternalDiameterField

                        Layout.column: 2
                        Layout.row: 2
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height

                        sourceComponent: numericTextFieldWithUnit
                        property string settingKey: "material_diameter"
                        property var mouseAreaBinding: syringeInternalDiameterField
                        property string unit: catalog.i18nc("@label", "mm")
                        property string tooltipText: "This setting is the internal diameter of the syringe."
                        property bool isExtruderSetting: true

                    }

                    Label
                    {
                        id: buildContainerShapeLabel

                        Layout.column: 1
                        Layout.row: 3
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height

                        text: catalog.i18nc("@label", "Build Container Shape");
                        font: UM.Theme.getFont("default");
                        color: UM.Theme.getColor("text");
                        elide: Text.ElideRight
                    }
                    Loader
                    {
                        id: buildContainerShapeCombobox

                        Layout.column: 2
                        Layout.row: 3
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height

                        sourceComponent: comboBoxWithOptions
                        property string settingKey: "machine_shape"
                        property var mouseAreaBinding: buildContainerShapeCombobox
                        property int storeIndex: 5
                    }

                    Label
                    {
                        Layout.column: 1
                        Layout.row: 4
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height

                        text: catalog.i18nc("@label", "Build Container Dimensions  X");
                        font: UM.Theme.getFont("default");
                        color: UM.Theme.getColor("text");
                        elide: Text.ElideRight
                    }
                    Loader
                    {
                        id: buildPlateVolumeXTextField

                        Layout.column: 2
                        Layout.row: 4
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height

                        sourceComponent: numericTextFieldWithUnit
                        property string settingKey: "machine_width"
                        property var mouseAreaBinding: buildPlateVolumeXTextField
                        property string unit: catalog.i18nc("@label", "mm")
                        property int storeIndex: 5

                    }

                    Label
                    {
                        id: buildPlateVolumesLabel

                        Layout.column: 1
                        Layout.row: 5
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height
                        Layout.alignment : Qt.AlignRight

                        text: catalog.i18nc("@label", "Y");
                        font: UM.Theme.getFont("default");
                        color: UM.Theme.getColor("text");
                    }
                    Loader
                    {
                        id: buildPlateVolumeYTextField

                        Layout.column: 2
                        Layout.row: 5
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height

                        sourceComponent: numericTextFieldWithUnit
                        property string settingKey: "machine_depth"
                        property var mouseAreaBinding: buildPlateVolumeYTextField
                        property string unit: catalog.i18nc("@label", "mm")
                        property int storeIndex: 5
                    }

                    Label
                    {
                        Layout.column: 1
                        Layout.row: 6
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height
                        Layout.alignment: Qt.AlignRight

                        text: catalog.i18nc("@label", "Z");
                        font: UM.Theme.getFont("default");
                        color: UM.Theme.getColor("text");
                    }
                    Loader
                    {
                        id: buildPlateVolumeZTextField

                        Layout.column: 2
                        Layout.row: 6
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height

                        sourceComponent: numericTextFieldWithUnit
                        property string settingKey: "machine_height"
                        property var mouseAreaBinding: buildPlateVolumeZTextField
                        property string unit: catalog.i18nc("@label", "mm")
                        property int storeIndex: 5
                    }

                    Label
                    {
                        id: infillPercentLabel

                        Layout.column: 1
                        Layout.row: 7
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height

                        text: catalog.i18nc("@label", "Infill %");
                        font: UM.Theme.getFont("default");
                        color: UM.Theme.getColor("text");
                        elide: Text.ElideRight

                    }
                    Loader
                    {
                        id: infillPercentCombobox

                        Layout.column: 2
                        Layout.row: 7
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height

                        sourceComponent: numericTextFieldWithUnit
                        property string settingKey: "infill_sparse_density"
                        property bool isExtruderSetting: true
                        property string unit: catalog.i18nc("@label", "%")
                        property var mouseAreaBinding: infillPercentLabel

                    }

                    Label
                    {
                        id: infillPatternLabel

                        Layout.column: 1
                        Layout.row: 8
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height

                        text: catalog.i18nc("@label", "Infill Pattern");
                        font: UM.Theme.getFont("default");
                        color: UM.Theme.getColor("text");
                        elide: Text.ElideRight

                    }
                    Loader
                    {
                        id: infillPatternCombobox

                        Layout.column: 2
                        Layout.row: 8
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height

                        sourceComponent: comboBoxWithOptions
                        property string settingKey: "infill_pattern"
                        property bool isExtruderSetting: true
                        property var mouseAreaBinding: infillPatternCombobox

                    }

                    Label
                    {
                        id: flowRateLabel

                        Layout.column: 1
                        Layout.row: 9
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height

                        text: catalog.i18nc("@label", "Flow Rate");
                        font: UM.Theme.getFont("default");
                        color: UM.Theme.getColor("text");
                        elide: Text.ElideRight
                    }
                    Loader
                    {
                        id: flowRateTextField

                        Layout.column: 2
                        Layout.row: 9
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height

                        sourceComponent: numericTextFieldWithUnit
                        property string settingKey: "material_flow"
                        property string unit: catalog.i18nc("@label", "%")
                        property bool isExtruderSetting: true
                        property var mouseAreaBinding: flowRateTextField
                    }

                    Label
                    {
                        id: wallLineCountLabel

                        Layout.column: 1
                        Layout.row: 10
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height

                        text: catalog.i18nc("@label", "Wall Line Count");
                        font: UM.Theme.getFont("default");
                        color: UM.Theme.getColor("text");
                        elide: Text.ElideRight

                    }
                    Loader
                    {
                        id: wallLineCountCombobox

                        Layout.column: 2
                        Layout.row: 10
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height

                        sourceComponent: numericTextFieldWithUnit
                        property string settingKey: "wall_line_count"
                        property bool isExtruderSetting: true
                        property string unit: catalog.i18nc("@label", "")
                        property var mouseAreaBinding: wallLineCountLabel

                    }

                    Label
                    {
                        id: topBottomPatternLabel

                        Layout.column: 1
                        Layout.row: 11
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height

                        text: catalog.i18nc("@label", "Top/Bottom Pattern");
                        font: UM.Theme.getFont("default");
                        color: UM.Theme.getColor("text");
                        elide: Text.ElideRight
                    }
                    Loader
                    {
                        id: topBottomPatternCombobox

                        Layout.column: 2
                        Layout.row: 11
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height

                        sourceComponent: comboBoxWithOptions
                        property string settingKey: "top_bottom_pattern"
                        property bool isExtruderSetting: true
                        property var mouseAreaBinding: topBottomPatternCombobox
                    }

                    Label
                    {
                        id: topLayersLabel

                        Layout.column: 1
                        Layout.row: 12
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height

                        text: catalog.i18nc("@label", "Top Layers");
                        font: UM.Theme.getFont("default");
                        color: UM.Theme.getColor("text");
                        elide: Text.ElideRight
                    }
                    Loader
                    {
                        id: topLayersField

                        Layout.column: 2
                        Layout.row: 12
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height

                        sourceComponent: numericTextFieldWithUnit
                        property string settingKey: "top_layers"
                        property string unit: catalog.i18nc("@label", "")
                        property bool isExtruderSetting: true
                        property var mouseAreaBinding: topLayersLabel
                    }

                    Label
                    {
                        id: bottomLayersLabel

                        Layout.column: 1
                        Layout.row: 13
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height

                        text: catalog.i18nc("@label", "Bottom Layers");
                        font: UM.Theme.getFont("default");
                        color: UM.Theme.getColor("text");
                        elide: Text.ElideRight
                    }
                    Loader
                    {
                        id: bottomLayersField

                        Layout.column: 2
                        Layout.row: 13
                        Layout.leftMargin: UM.Theme.getSize("sidebar_margin").width
                        Layout.minimumHeight: UM.Theme.getSize("setting_control").height

                        sourceComponent: numericTextFieldWithUnit
                        property string settingKey: "bottom_layers"
                        property string unit: catalog.i18nc("@label", "")
                        property bool isExtruderSetting: true
                        property var mouseAreaBinding: bottomLayersLabel
                    }

                    UM.SettingPropertyProvider
                    {
                        id: lineWidthPropertyProvider

                        containerStackId: Cura.ExtruderManager.activeExtruderStackId
                        key: "line_width"
                        watchedProperties: ["value","description"]
                        storeIndex: 0

                    }
                }
            }
        }
    }
    Component
    {
        id: comboBoxWithOptions
        Item
        {
            height: childrenRect.height
            width: childrenRect.width


            property bool _isExtruderSetting: (typeof(isExtruderSetting) === 'undefined') ? false : isExtruderSetting
            property var _mouseAreaBinding: (typeof(mouseAreaBinding) === 'undefined') ? 0 : mouseAreaBinding
            property int _storeIndex: (typeof(storeIndex) === 'undefined') ? 0 : storeIndex

            UM.SettingPropertyProvider
            {
                id: propertyProvider

                containerStackId: {
                    if(_isExtruderSetting)
                    {
                        return Cura.ExtruderManager.activeExtruderStackId;
                    }
                    return Cura.MachineManager.activeMachineId;
                }
                key: settingKey
                watchedProperties: [ "value", "options", "description" ]
                storeIndex: _storeIndex
            }

            ComboBox
            {
                id: comboBox
                width: UM.Theme.getSize("sidebar").width * .4
                style: UM.Theme.styles.combobox;
                model: ListModel
                {
                    id: optionsModel
                    Component.onCompleted:
                    {
                        // Options come in as a string-representation of an OrderedDict
                        var options = propertyProvider.properties.options.match(/^OrderedDict\(\[\((.*)\)\]\)$/);
                        if(options)
                        {
                            options = options[1].split("), (")
                            for(var i = 0; i < options.length; i++)
                            {
                                var option = options[i].substring(1, options[i].length - 1).split("', '")
                                optionsModel.append({text: option[1], value: option[0]});
                            }
                        }
                    }
                }

                MouseArea
                {
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: base.settingsEnabled
                    acceptedButtons: Qt.NoButton

                    onEntered:
                    {
                        base.showTooltip(_mouseAreaBinding, Qt.point(-_mouseAreaBinding.x, 0),
                            catalog.i18nc("@label", propertyProvider.properties.description));
                    }
                    onExited:
                    {
                        base.hideTooltip();
                    }
                }

                currentIndex:
                {
                    var currentValue = propertyProvider.properties.value;
                    var index = 0;
                    for(var i = 0; i < optionsModel.count; i++)
                    {
                        if(optionsModel.get(i).value == currentValue) {
                            index = i;
                            break;
                        }
                    }
                    return index
                }

                onActivated:
                {
                    if(propertyProvider.properties.value != optionsModel.get(index).value)
                    {
                        propertyProvider.setPropertyValue("value", optionsModel.get(index).value)
                    }
                }
            }
        }
    }

    Component
    {
        id: numericTextFieldWithUnit
        Item
        {
            height: childrenRect.height
            width: childrenRect.width


            property bool _isExtruderSetting: (typeof(isExtruderSetting) === 'undefined') ? false: isExtruderSetting
            property bool _allowNegative: (typeof(allowNegative) === 'undefined') ? false : allowNegative
            property int _storeIndex: (typeof(storeIndex) === 'undefined') ? 0 : storeIndex
            property string _tooltipText: (typeof(tooltipText) === 'undefined') ? propertyProvider.properties.description : tooltipText
            property var _mouseAreaBinding: (typeof(mouseAreaBinding) === 'undefined') ? 0 : mouseAreaBinding

            UM.SettingPropertyProvider
            {
                id: propertyProvider

                containerStackId: {
                    if(_isExtruderSetting)
                    {
                        return Cura.ExtruderManager.activeExtruderStackId;
                    }
                    return Cura.MachineManager.activeMachineId;
                }
                key: settingKey
                watchedProperties: [ "value", "description" ]
                storeIndex: _storeIndex

            }

            Row
            {
                spacing: UM.Theme.getSize("default_margin").width

                Item
                {
                    width: textField.width
                    height: textField.height

                    id: textFieldWithUnit
                    TextField
                    {
                        width: UM.Theme.getSize("sidebar").width * .4
                        style: UM.Theme.styles.text_field;
                        id: textField
                        text: {
                            const value = propertyProvider.properties.value;
                            return value ? value : "";
                        }
                        validator: RegExpValidator { regExp: _allowNegative ? /-?[0-9\.]{0,6}/ : /[0-9\.]{0,6}/ }
                        onEditingFinished:
                        {
                            if (propertyProvider && text != propertyProvider.properties.value)
                            {
                                propertyProvider.setPropertyValue("value", text);
                            }
                        }
                    }

                    MouseArea
                    {
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: base.settingsEnabled
                        acceptedButtons: Qt.NoButton

                        onEntered:
                        {
                            base.showTooltip(_mouseAreaBinding, Qt.point(-_mouseAreaBinding.x, 0),
                                catalog.i18nc("@label", _tooltipText));
                        }
                        onExited:
                        {
                            base.hideTooltip();
                        }
                    }


                    Label
                    {
                        text: unit
                        anchors.right: textField.right
                        anchors.rightMargin: y - textField.y
                        anchors.verticalCenter: textField.verticalCenter
                    }
                }
            }
        }
    }


    function populateExtruderModel()
    {
        extruderModel.clear();
        for(var extruderNumber = 0; extruderNumber < extruders.rowCount() ; extruderNumber++)
        {
            extruderModel.append({
                text: extruders.getItem(extruderNumber).name,
                color: extruders.getItem(extruderNumber).color
            })
        }
        supportExtruderCombobox.updateCurrentColor();
        adhesionExtruderCombobox.updateCurrentColor();
    }
}
