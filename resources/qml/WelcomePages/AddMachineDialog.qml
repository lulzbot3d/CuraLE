// Copyright (c) 2019 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 2.3

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
                base.visible = true //false
                var item = toolheadsModel.getItem(toolheadSelection.selectedIndex).id
                var success = Cura.MachineManager.addMachine(item, machineName.text, lcdSelection.selectedIndex == 0 ? true: false,true/*revisionSelection.selectedIndex == 0 ? true: false*/)
                return success
            }

            function update()
            {
                machineName.text = getMachineName()
                printerSelection.lcd = printerSelectionRepeater.model.getItem(0).lcd
                printerSelection.revision = printerSelectionRepeater.model.getItem(0).revision
                printerSelection.baseMachine = printerSelectionRepeater.model.getItem(0).id
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
                    }
                    else
                    {
                        item.checked = false
                    }
                    item.checkedChanged()
                }
            }

            Row
            {
                anchors.fill: parent
                spacing: 2

                GroupBox
                {
                    id: printerSelection
                    width: parent.width * .25 //the parent width of the window is multiplied by 1/ # of boxes to get evenly spaced boxes that take up the whole window
                    anchors.bottom: parent.bottom
                    anchors.top: parent.top
                    anchors.bottomMargin: UM.Theme.getSize("default_margin").width

                    title: catalog.i18nc("@action:button", "LulzBot 3D Printers")
                    ButtonGroup { id: printerGroup }

                    property int selectedIndex: 0
                    property bool lcd: false
                    property bool revision: false
                    property string baseMachine: ""

                    Column
                    {
                        Repeater
                        {
                            id: printerSelectionRepeater
                            model: Cura.LulzBotPrintersModel {}
                            delegate: Cura.RadioButton
                            {
                                text: model.name
                                ButtonGroup.group: printerGroup
                                checked: model.index == 0
                                onClicked: { printerSelection.selectedIndex = model.index; printerSelection.lcd = model.lcd; printerSelection.revision = model.revision; printerSelection.baseMachine = model.id; printerSelectorLoader.item.updateToolheads(); }
                            }

                            Component.onCompleted: {printerSelection.lcd = model.getItem(0).lcd;printerSelection.revision = model.getItem(0).revision; printerSelection.baseMachine = model.getItem(0).id}
                        }
                    }
                }

                GroupBox
                {
                    id: toolheadSelection
                    width: parent.width * .50
                    anchors.bottom: parent.bottom
                    anchors.top: parent.top
                    anchors.bottomMargin: UM.Theme.getSize("default_margin").width

                    title: catalog.i18nc("@action:button", "Tool Head | Nozzle Ø | Nozzle Material")
                    ButtonGroup { id: toolheadGroup }

                    property int selectedIndex: 0

                    Column
                    {

                        Repeater
                        {
                            id: toolheadSelectionRepeater
                            model: Cura.LulzBotToolheadsModel { id: toolheadsModel; baseMachineProperty: printerSelection.baseMachine }
                            delegate: Cura.RadioButton
                            {
                                text: model.toolhead
                                ButtonGroup.group: toolheadGroup
                                checked: model.index == 0
                                onCheckedChanged: { if(checked) {toolheadSelection.selectedIndex = model.index; machineName.text = model.name }}
                            }
                        }
                    }
                }

                GroupBox
                {
                    id: lcdSelection
                    width: parent.width * .25
                    anchors.bottom: parent.bottom
                    anchors.top: parent.top
                    anchors.bottomMargin: UM.Theme.getSize("default_margin").width

                    title: catalog.i18nc("@action:button", "Graphical LCD")
                    ButtonGroup { id: lcdGroup }

                    property int selectedIndex: 0

                    Column
                    {
                        Repeater
                        {
                            model: ["Yes", "No"]
                            delegate: Cura.RadioButton
                            {
                                text: modelData
                                ButtonGroup.group: lcdGroup
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
        text: catalog.i18nc("@label", "Printer Name:")
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
        //implicitWidth: UM.Theme.getSize("standard_list_input").width
        maximumLength: 40
        //validator: Cura.MachineNameValidator { } //TODO: Gives a segfault in PyQt5.6. For now, we must use a signal on text changed.
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
