// Copyright (c) 2019 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1

import UM 1.3 as UM
import Cura 1.1 as Cura


//
// This component contains the content for the "Add a printer" (network) page of the welcome on-boarding process.
//
Item
{
    UM.I18nCatalog { id: catalog; name: "cura" }
    SystemPalette { id: palette }

    Component
    {
        id: lulzbotSelector

        Item
        {
            function getMachineName()
            {
                var name = toolheadsModel.getItem(toolheadSelection.selectedIndex).name
                return name
            }

            function addMachine()
            {
                base.visible = true
                var item = toolheadsModel.getItem(toolheadSelection.selectedIndex).id
                var success = Cura.MachineManager.addMachine(item, machineName.text, lcdSelection.selectedIndex == 0, bltouchSelection.selectedIndex == 0)
                return success
            }

            function update()
            {
                machineName.text = getMachineName()
                printerSelection.lcd = printerSelectionRepeater.model.getItem(0).lcd
                printerSelection.baseMachine = printerSelectionRepeater.model.getItem(0).id
                toolheadSelection.bltouch_default = toolheadSelectionRepeater.model.getItem(0).bltouch_default
                toolheadSelection.bltouch_option = toolheadSelectionRepeater.model.getItem(0).bltouch_option
                printerSelection.selectedIndex = 0
                for (var i = 0; i < printerSelectionRepeater.count; i++)
                {
                    var item = printerSelectionRepeater.itemAt(i)
                    if (i==0)
                    {
                        item.checked = true
                    }
                    else
                    {
                        item.checked = false
                    }
                }
            }

            function updateToolheads()
            {
                for (var i = 0; i < toolheadSelectionRepeater.count; i++)
                {
                    var item = toolheadSelectionRepeater.itemAt(i)
                    if (i==0)
                    {
                        item.checked = true
                        item.clicked()
                    }
                    else
                    {
                        item.checked = false
                    }
                }
            }

            function updateOptions()
            {
                for (var i = 0; i < bltouchSelectionRepeater.count; i++)
                {
                    var item = bltouchSelectionRepeater.itemAt(i)
                    if(toolheadSelection.bltouch_default){
                        if(i==0) { item.checked = true }
                        else { item.checked = false }
                    } else {
                        if(i==0) { item.checked = false }
                        else { item.checked = true }
                    }
                }
            }

            GridLayout
            {
                anchors.fill: parent
                anchors.bottomMargin: UM.Theme.getSize("default_margin").width
                columns: 3
                rows: 2
                columnSpacing: 2
                rowSpacing: 2

                GroupBox
                {
                    id: printerSelection

                    Layout.preferredWidth: parent.width * .25

                    Layout.fillHeight: true

                    Layout.column: 0
                    Layout.rowSpan: 2

                    title: catalog.i18nc("@action:button", "LulzBot 3D Printers")
                    ExclusiveGroup { id: printerGroup }

                    property int selectedIndex: 0
                    property bool lcd: false
                    property string baseMachine: ""

                    Column
                    {
                        Repeater
                        {
                            id: printerSelectionRepeater
                            model: Cura.LulzBotPrintersModel {}
                            delegate: RadioButton
                            {
                                text: model.name

                                exclusiveGroup: printerGroup
                                checked: model.index == 0
                                onClicked: {
                                    printerSelection.selectedIndex = model.index
                                    printerSelection.lcd = model.lcd
                                    printerSelection.baseMachine = model.id
                                    printerSelectorLoader.item.updateToolheads()
                                }
                            }

                            Component.onCompleted: {
                                printerSelection.lcd = model.getItem(0).lcd;
                                printerSelection.baseMachine = model.getItem(0).id
                            }
                        }
                    }
                }

                GroupBox
                {
                    id: toolheadSelection
                    Layout.preferredWidth: parent.width * .50

                    Layout.fillHeight: true

                    Layout.column: 1
                    Layout.rowSpan: 2

                    title: catalog.i18nc("@action:button", "Tool Head | Nozzle Ø | Nozzle Material")
                    ExclusiveGroup { id: toolheadGroup }

                    property int selectedIndex: 0
                    property bool bltouch_option: false
                    property bool bltouch_default: false

                    Column
                    {

                        Repeater
                        {
                            id: toolheadSelectionRepeater
                            model: Cura.LulzBotToolheadsModel { id: toolheadsModel; baseMachineProperty: printerSelection.baseMachine }
                            delegate: RadioButton
                            {
                                text: model.toolhead
                                exclusiveGroup: toolheadGroup
                                checked: model.index == 0
                                onClicked: {
                                    toolheadSelection.selectedIndex = model.index
                                    machineName.text = model.name
                                    toolheadSelection.bltouch_option = model.bltouch_option
                                    toolheadSelection.bltouch_default = model.bltouch_default
                                    printerSelectorLoader.item.updateOptions()
                                }
                            }
                        }
                    }
                }

                GroupBox
                {
                    id: lcdSelection
                    Layout.preferredWidth: parent.width * .25
                    anchors.bottomMargin: UM.Theme.getSize("default_margin").width

                    Layout.fillHeight: true

                    Layout.column: 2
                    Layout.rowSpan: 1

                    title: catalog.i18nc("@action:button", "Graphical LCD")
                    ExclusiveGroup { id: lcdGroup }

                    property int selectedIndex: 0

                    Column
                    {
                        Repeater
                        {
                            model: ["Yes", "No"]
                            delegate: RadioButton
                            {
                                text: modelData
                                exclusiveGroup: lcdGroup
                                checked: model.index == 0
                                enabled: printerSelection.lcd
                                onEnabledChanged:
                                {
                                    if(!enabled && model.index == 0) checked = true
                                }
                                onClicked: { lcdSelection.selectedIndex = model.index }
                            }
                        }
                    }
                }

                GroupBox
                {
                    id: bltouchSelection
                    Layout.preferredWidth: parent.width * .25
                    anchors.bottomMargin: UM.Theme.getSize("default_margin").width

                    Layout.fillHeight: true

                    Layout.column: 2
                    Layout.row: 1
                    Layout.rowSpan: 1

                    title: catalog.i18nc("@action:button", "BLTouch Leveling")
                    ExclusiveGroup { id: bltouchGroup }

                    property int selectedIndex: 1

                    Column
                    {
                        Repeater
                        {
                            id: bltouchSelectionRepeater
                            model: ["Yes", "No"]
                            delegate: RadioButton
                            {
                                text: modelData
                                exclusiveGroup: bltouchGroup
                                checked: {
                                    if(model.index == 0){
                                        toolheadSelection.bltouch_default
                                    } else {
                                        !toolheadSelection.bltouch_default
                                    }
                                }
                                enabled: toolheadSelection.bltouch_option
                                onClicked: { bltouchSelection.selectedIndex = model.index }
                            }
                        }
                    }
                }
            }
        }
    }

    Loader
    {
        id: printerSelectorLoader
        sourceComponent: lulzbotSelector

        anchors
        {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: machineName.top
        }

        onSourceComponentChanged: item.update()
    }

    Label
    {
        id: printerLabel
        text: catalog.i18nc("@label", "Name:")
        anchors.verticalCenter: machineName.verticalCenter
        anchors.left: backButton.right
        anchors.leftMargin: 10
    }

    TextField
    {
        id: machineName
        anchors.top: nextButton.top
        anchors.right: nextButton.left
        anchors.left: printerLabel.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: UM.Theme.getSize("default_margin").width
        anchors.rightMargin: UM.Theme.getSize("default_margin").width
        text: printerSelectorLoader.item.getMachineName()
        maximumLength: 40
        validator: RegExpValidator
        {
            regExp: {
                machineName.machine_name_validator.machineNameRegex
            }
        }
        property var machine_name_validator: Cura.MachineNameValidator { }
    }

    // This "Back" button only shows in the "Add Machine" dialog, which has "previous_page_button_text" set to "Cancel"
    Cura.SecondaryButton
    {
        id: backButton
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        visible: base.currentItem.previous_page_button_text ? true : false
        text: base.currentItem.previous_page_button_text ? base.currentItem.previous_page_button_text : ""
        onClicked:
        {
            base.endWizard()
        }
    }

    Cura.PrimaryButton
    {
        id: nextButton
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        enabled:
        {
            // Printer name cannot be empty
            const localPrinterItem = printerSelectorLoader.item
            return localPrinterItem != null
        }

        text: base.currentItem.next_page_button_text
        onClicked:
        {
            // Create a local printer
            const localPrinterItem = printerSelectorLoader.item.addMachine()
            if(localPrinterItem)
            {
                base.showNextPage()
            }
        }
    }
}
