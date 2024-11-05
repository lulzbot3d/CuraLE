// Copyright (c) 2023 Fargo Additive Manufacturing Equipment 3D, LLC.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.15
import QtQuick.Controls 2.3
import QtQuick.Layouts 2.3

import UM 1.5 as UM
import Cura 1.1 as Cura


//
// This component contains the content for the "Add a printer" (network) page of the welcome on-boarding process.
//
Item
{
    UM.I18nCatalog { id: catalog; name: "cura" }

    Component
    {
        id: lulzbotSelector

        Item
        {
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

                    label: UM.Label
                    {
                        x: printerSelection.leftPadding
                        width: printerSelection.availableWidth
                        text: printerSelection.title
                    }

                    ButtonGroup { id: printerGroup }

                    property int selectedIndex: 0
                    property string selectedCategory: "current"
                    property bool lcd: false
                    property bool lcd_default: true
                    property string baseMachine: ""

                    Column
                    {

                        id: printerColumn
                        spacing: 10

                        Column
                        {

                            UM.Label
                            {
                                id: currentPrinterLabel
                                text: "3D Printers"
                                font.bold: true
                                font.pixelSize: 14
                                visible: currentPrinterSelectionRepeater.model.count > 0
                            }

                            Rectangle
                            {
                                visible: currentPrinterLabel.visible
                                height: 2
                                width: printerColumn.width
                                color: "black"
                            }

                            Repeater
                            {
                                id: currentPrinterSelectionRepeater
                                model: Cura.LulzBotPrintersModel
                                {
                                    id: currentPrintersModel
                                    machineCategoryProperty: "Current"
                                }

                                delegate: Cura.RadioButton
                                {
                                    text: model.name

                                    ButtonGroup.group: printerGroup
                                    checked: model.index == 0
                                    onClicked:
                                    {
                                        printerSelection.selectedIndex = model.index;
                                        printerSelection.selectedCategory = "current";
                                        printerSelection.lcd = model.lcd;
                                        printerSelection.lcd_default = model.lcd_default;
                                        printerSelection.baseMachine = model.id;
                                        printerSelectorLoader.item.updateToolheads();
                                    }
                                }

                                Component.onCompleted:
                                {
                                    printerSelection.lcd = model.getItem(0).lcd;
                                    printerSelection.baseMachine = model.getItem(0).id;
                                }
                            }
                        }

                        Column
                        {
                            UM.Label
                            {
                                id: bioPrinterLabel
                                text: "Bio Printers"
                                font.bold: true
                                font.pixelSize: 14
                                visible: bioPrinterSelectionRepeater.model.count > 0
                            }

                            Rectangle
                            {
                                visible: bioPrinterLabel.visible
                                height: 2
                                width: printerColumn.width
                                color: "black"
                            }

                            Repeater
                            {
                                id: bioPrinterSelectionRepeater
                                model: Cura.LulzBotPrintersModel
                                {
                                    id: bioPrintersModel
                                    machineCategoryProperty: "Bio"
                                }

                                delegate: Cura.RadioButton
                                {
                                    text: model.name

                                    ButtonGroup.group: printerGroup
                                    checked: model.index == 0
                                    onClicked:
                                    {
                                        printerSelection.selectedIndex = model.index;
                                        printerSelection.selectedCategory = "current";
                                        printerSelection.lcd = model.lcd;
                                        printerSelection.lcd_default = model.lcd_default;
                                        printerSelection.baseMachine = model.id;
                                        printerSelectorLoader.item.updateToolheads();
                                    }
                                }

                                Component.onCompleted:
                                {
                                    printerSelection.lcd = model.getItem(0).lcd;
                                    printerSelection.baseMachine = model.getItem(0).id
                                }
                            }
                        }

                        Column
                        {
                            UM.Label
                            {
                                id: legacyPrinterLabel
                                text: "Legacy 3D Printers"
                                font.bold: true
                                font.pixelSize: 14
                                visible: legacyPrinterSelectionRepeater.model.count > 0
                            }

                            Rectangle
                            {
                                visible: legacyPrinterLabel.visible
                                height: 2
                                width: printerColumn.width
                                color: "black"
                            }

                            Repeater
                            {
                                id: legacyPrinterSelectionRepeater
                                model: Cura.LulzBotPrintersModel {
                                    id: legacyPrintersModel
                                    machineCategoryProperty: "Legacy"
                                }

                                delegate: Cura.RadioButton
                                {
                                    text: model.name

                                    ButtonGroup.group: printerGroup
                                    checked: model.index == 0
                                    onClicked:
                                    {
                                        printerSelection.selectedIndex = model.index;
                                        printerSelection.selectedCategory = "legacy";
                                        printerSelection.lcd = model.lcd;
                                        printerSelection.lcd_default = model.lcd_default;
                                        printerSelection.baseMachine = model.id;
                                        printerSelectorLoader.item.updateToolheads();
                                    }
                                }

                                Component.onCompleted:
                                {
                                    printerSelection.lcd = model.getItem(0).lcd;
                                    printerSelection.baseMachine = model.getItem(0).id;
                                }
                            }
                        }

                        Column
                        {
                            UM.Label
                            {
                                id: devPrinterLabel
                                text: "Developmental"
                                font.bold: true
                                font.pixelSize: 14
                                visible: devPrinterSelectionRepeater.model.count > 0
                            }

                            Rectangle
                            {
                                visible: devPrinterLabel.visible
                                height: 2
                                width: printerColumn.width
                                color: "black"
                            }

                            Repeater
                            {
                                id: devPrinterSelectionRepeater
                                model: Cura.LulzBotPrintersModel
                                {
                                    id: devPrintersModel
                                    machineCategoryProperty: "Dev"
                                }

                                delegate: Cura.RadioButton
                                {
                                    text: model.name

                                    ButtonGroup.group: printerGroup
                                    checked: model.index == 0
                                    onClicked:
                                    {
                                        printerSelection.selectedIndex = model.index;
                                        printerSelection.selectedCategory = "current";
                                        printerSelection.lcd = model.lcd;
                                        printerSelection.lcd_default = model.lcd_default;
                                        printerSelection.baseMachine = model.id;
                                        printerSelectorLoader.item.updateToolheads();
                                    }
                                }

                                Component.onCompleted:
                                {
                                    printerSelection.lcd = model.getItem(0).lcd;
                                    printerSelection.baseMachine = model.getItem(0).id
                                }
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

                    label: UM.Label
                    {
                        x: toolheadSelection.leftPadding
                        width: toolheadSelection.availableWidth
                        text: toolheadSelection.title
                    }

                    title: catalog.i18nc("@action:button", "Tool Head | Nozzle Ø | Nozzle Material")
                    ButtonGroup { id: toolheadGroup }

                    property int selectedIndex: 0
                    property string selectedCategory: "galaxy"
                    property bool bltouch_option: false
                    property bool bltouch_default: false

                    Column
                    {
                        id: toolheadColumn
                        spacing: 10

                        Column
                        {
                            UM.Label
                            {
                                id: galaxyToolheadLabel
                                text: "Galaxy Series Tool Heads"
                                font.bold: true
                                font.pixelSize: 14
                                visible: galaxyToolheadSelectionRepeater.model.count > 0
                            }

                            Rectangle
                            {
                                visible: galaxyToolheadLabel.visible
                                height: 2
                                width: toolheadColumn.width
                                color: "black"
                            }

                            Repeater
                            {
                                id: galaxyToolheadSelectionRepeater
                                model: Cura.LulzBotToolheadsModel
                                {
                                    id: galaxyToolheadsModel;
                                    baseMachineProperty: printerSelection.baseMachine;
                                    toolheadCategoryProperty: "Galaxy"
                                }

                                delegate: Cura.RadioButton
                                {
                                    text: model.toolhead
                                    ButtonGroup.group: toolheadGroup
                                    checked: model.index == 0
                                    onClicked:
                                    {
                                        toolheadSelection.selectedIndex = model.index;
                                        toolheadSelection.selectedCategory = "galaxy";
                                        machineName.text = model.name;
                                        toolheadSelection.bltouch_option = model.bltouch_option;
                                        toolheadSelection.bltouch_default = model.bltouch_default;
                                        printerSelectorLoader.item.updateOptions();
                                    }
                                }
                            }
                        }

                        Column
                        {

                            UM.Label
                            {
                                id: legacyToolheadLabel
                                text: "Legacy Tool Heads"
                                font.bold: true
                                font.pixelSize: 14
                                visible: legacyToolheadSelectionRepeater.model.count > 0
                            }

                            Rectangle
                            {
                                visible: legacyToolheadLabel.visible
                                height: 2
                                width: toolheadColumn.width
                                color: "black"
                            }

                            Repeater
                            {
                                id: legacyToolheadSelectionRepeater
                                model: Cura.LulzBotToolheadsModel
                                {
                                    id: legacyToolheadsModel;
                                    baseMachineProperty: printerSelection.baseMachine;
                                    toolheadCategoryProperty: "Universal"
                                }

                                delegate: Cura.RadioButton
                                {
                                    text: model.toolhead
                                    ButtonGroup.group: toolheadGroup
                                    checked: model.index == 0
                                    onClicked:
                                    {
                                        toolheadSelection.selectedIndex = model.index;
                                        toolheadSelection.selectedCategory = "legacy";
                                        machineName.text = model.name;
                                        toolheadSelection.bltouch_option = model.bltouch_option;
                                        toolheadSelection.bltouch_default = model.bltouch_default;
                                        printerSelectorLoader.item.updateOptions();
                                    }
                                }
                            }
                        }

                        Column
                        {
                            Repeater
                            {
                                id: noCategoryToolheadSelectionRepeater
                                model: Cura.LulzBotToolheadsModel
                                {
                                    id: noCategoryToolheadsModel;
                                    baseMachineProperty: printerSelection.baseMachine;
                                    toolheadCategoryProperty: ""
                                }

                                delegate: Cura.RadioButton
                                {
                                    text: model.toolhead
                                    ButtonGroup.group: toolheadGroup
                                    checked: model.index == 0
                                    onClicked:
                                    {
                                        toolheadSelection.selectedIndex = model.index;
                                        toolheadSelection.selectedCategory = "none";
                                        machineName.text = model.name;
                                        toolheadSelection.bltouch_option = model.bltouch_option;
                                        toolheadSelection.bltouch_default = model.bltouch_default;
                                        printerSelectorLoader.item.updateOptions();
                                    }
                                }
                            }
                        }
                    }
                }

                GroupBox
                {
                    id: lcdSelection

                    anchors.bottomMargin: UM.Theme.getSize("default_margin").width

                    Layout.preferredWidth: parent.width * .25
                    Layout.fillHeight: true
                    Layout.column: 2
                    Layout.rowSpan: 1

                    label: UM.Label
                    {
                        x: lcdSelection.leftPadding
                        width: lcdSelection.availableWidth
                        text: lcdSelection.title
                    }

                    title: catalog.i18nc("@action:button", "Graphical LCD")
                    ButtonGroup { id: lcdGroup }

                    property int selectedIndex: 0

                    Column
                    {
                        Repeater
                        {
                            id: lcdSelectionRepeater
                            model: ["Yes", "No"]
                            delegate: Cura.RadioButton
                            {
                                text: modelData
                                ButtonGroup.group: lcdGroup
                                checked: model.index == 0
                                enabled: printerSelection.lcd
                                onEnabledChanged:
                                {
                                    if (!enabled && model.index == 0)
                                    {
                                        checked = true;
                                    }
                                }
                                onClicked: { lcdSelection.selectedIndex = model.index; }
                            }
                        }
                    }
                }

                GroupBox
                {
                    id: bltouchSelection
                    anchors.bottomMargin: UM.Theme.getSize("default_margin").width

                    Layout.preferredWidth: parent.width * .25
                    Layout.fillHeight: true
                    Layout.column: 2
                    Layout.row: 1
                    Layout.rowSpan: 1

                    label: UM.Label
                    {
                        x: bltouchSelection.leftPadding
                        width: bltouchSelection.availableWidth
                        text: bltouchSelection.title
                    }

                    title: catalog.i18nc("@action:button", "BLTouch Leveling")
                    ButtonGroup { id: bltouchGroup }

                    property int selectedIndex: 1

                    Column
                    {
                        Repeater
                        {
                            id: bltouchSelectionRepeater
                            model: ["Yes", "No"]
                            delegate: Cura.RadioButton
                            {
                                text: modelData
                                ButtonGroup.group: bltouchGroup
                                checked:
                                {
                                    if (model.index == 0)
                                    {
                                        toolheadSelection.bltouch_default;
                                    }
                                    else
                                    {
                                        !toolheadSelection.bltouch_default;
                                    }
                                }
                                enabled: toolheadSelection.bltouch_option
                                onClicked: { bltouchSelection.selectedIndex = model.index; }
                            }
                        }
                    }
                }
            }

            function getMachineName()
            {
                let name = "";
                if (toolheadSelection.selectedCategory == "galaxy")
                {
                    name = galaxyToolheadsModel.getItem(toolheadSelection.selectedIndex).name;
                }
                else if (toolheadSelection.selectedCategory == "legacy")
                {
                    name = legacyToolheadsModel.getItem(toolheadSelection.selectedIndex).name;
                }
                else
                {
                    name = noCategoryToolheadsModel.getItem(toolheadSelection.selectedIndex).name;
                }
                //return name;
                return "Bagingo";
            }

            function addMachine()
            {
                base.visible = true;
                let item = null;
                if (toolheadSelection.selectedCategory == "galaxy")
                {
                    item = galaxyToolheadsModel.getItem(toolheadSelection.selectedIndex).id;
                }
                else if (toolheadSelection.selectedCategory == "legacy")
                {
                    item = legacyToolheadsModel.getItem(toolheadSelection.selectedIndex).id;
                }
                else
                {
                    item = noCategoryToolheadsModel.getItem(toolheadSelection.selectedIndex).id;
                }
                var success = Cura.MachineManager.addMachine(item, machineName.text, lcdSelection.selectedIndex == 0, bltouchSelection.selectedIndex == 0);
                return success;
            }

            function update()
            {
                machineName.text = getMachineName();
                printerSelection.lcd = currentPrinterSelectionRepeater.model.getItem(0).lcd;
                printerSelection.baseMachine = currentPrinterSelectionRepeater.model.getItem(0).id;
                let firstToolhead = null;
                if (galaxyToolheadsModel.count > 0)
                {
                    firstToolhead = galaxyToolheadsModel.getItem(0);
                }
                else if (legacyToolheadsModel.count > 0)
                {
                    firstToolhead = legacyToolheadsModel.getItem(0);
                }
                else
                {
                    firstToolhead = noCategoryToolheadsModel.getItem(0);
                }
                toolheadSelection.bltouch_default = firstToolhead.bltouch_default;
                toolheadSelection.bltouch_option = firstToolhead.bltouch_option;
                printerSelection.selectedIndex = 0;
                for (let i = 0; i < currentPrinterSelectionRepeater.count; i++)
                {
                    let item = currentPrinterSelectionRepeater.itemAt(i);
                    if (i==0)
                    {
                        item.checked = true;
                    }
                    else
                    {
                        item.checked = false;
                    }
                }
                for (let i = 0; i < bioPrinterSelectionRepeater.count; i++)
                {
                    bioPrinterSelectionRepeater.itemAt(i).checked = false;
                }
                for (let i = 0; i < legacyPrinterSelectionRepeater.count; i++)
                {
                    legacyPrinterSelectionRepeater.itemAt(i).checked = false;
                }
                for (let i = 0; i < devPrinterSelectionRepeater.count; i++)
                {
                    devPrinterSelectionRepeater.itemAt(i).checked = false;
                }
            }

            function updateToolheads()
            {
                let atLeastOne = false;
                let defaultFound = false;
                function resetCategory(iteration, toolhead, isDefault)
                {
                    if (isDefault == 0)
                    {
                        toolhead.checked = true;
                        toolhead.clicked();
                        defaultFound = true;
                        return;
                    }
                    if (iteration == 0 && atLeastOne != true)
                    {
                        toolhead.checked = true;
                        toolhead.clicked();
                        atLeastOne = true;
                    } else
                    {
                        toolhead.checked = false;
                    }
                }
                for (let i = 0; i < galaxyToolheadSelectionRepeater.count; i++)
                {
                    resetCategory(i, galaxyToolheadSelectionRepeater.itemAt(i), galaxyToolheadsModel.getItem(i).priority);
                    if (defaultFound)
                    {
                        return;
                    }
                }
                for (let i = 0; i < legacyToolheadSelectionRepeater.count; i++)
                {
                    resetCategory(i, legacyToolheadSelectionRepeater.itemAt(i), legacyToolheadsModel.getItem(i).priority);
                    if (defaultFound)
                    {
                        return;
                    }
                }
                for (let i = 0; i < noCategoryToolheadSelectionRepeater.count; i++)
                {
                    resetCategory(i, noCategoryToolheadSelectionRepeater.itemAt(i), noCategoryToolheadsModel.getItem(i).priority);
                    if (defaultFound)
                    {
                        return;
                    }
                }
            }

            function updateOptions()
            {
                for (let i = 0; i < bltouchSelectionRepeater.count; i++)
                {
                    let item = bltouchSelectionRepeater.itemAt(i);
                    if (toolheadSelection.bltouch_default)
                    {
                        if (i == 0)
                        {
                            item.checked = true;
                        }
                        else
                        {
                            item.checked = false;
                        }
                        bltouchSelection.selectedIndex = 0;
                    }
                    else
                    {
                        if (i == 0)
                        {
                            item.checked = false ;
                        }
                        else
                        {
                            item.checked = true;
                        }
                        bltouchSelection.selectedIndex = 1;
                    }
                }
                for (let i = 0; i < lcdSelectionRepeater.count; i++) {
                    let item = lcdSelectionRepeater.itemAt(i);
                    if (printerSelection.lcd_default)
                    {
                        if (i == 0)
                        {
                            item.checked = true;
                        }
                        else
                        {
                            item.checked = false;
                        }
                        lcdSelection.selectedIndex = 0;
                    }
                    else
                    {
                        if (i == 0)
                        {
                            item.checked = false;
                        }
                        else
                        {
                            item.checked = true;
                        }
                        lcdSelection.selectedIndex = 1;
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

        onLoaded: item.updateToolheads()
        onSourceComponentChanged: item.update()
    }

    UM.Label
    {
        id: printerLabel
        text: catalog.i18nc("@label", "Name:")
        anchors
        {
            verticalCenter: machineName.verticalCenter
            left: backButton.right
            leftMargin: 10
        }
    }

    Cura.TextField
    {
        id: machineName
        anchors
        {
            top: nextButton.top
            right: nextButton.left
            left: printerLabel.right
            bottom: parent.bottom
            leftMargin: UM.Theme.getSize("default_margin").width
            rightMargin: UM.Theme.getSize("default_margin").width
        }

        text: printerSelectorLoader.item.getMachineName()
        maximumLength: 40
        validator: RegularExpressionValidator
        {
            regularExpression:
            {
                machineName.machine_name_validator.machineNameRegex
            }
        }
        property var machine_name_validator: Cura.MachineNameValidator { }
    }

    // This "Back" button only shows in the "Add Machine" dialog, which has "previous_page_button_text" set to "Cancel"
    Cura.SecondaryButton
    {
        id: backButton
        anchors
        {
            left: parent.left
            bottom: parent.bottom
        }
        visible: base.currentItem.previous_page_button_text ? true : false
        text: base.currentItem.previous_page_button_text ? base.currentItem.previous_page_button_text : ""
        onClicked:
        {
            base.endWizard();
        }
    }

    Cura.PrimaryButton
    {
        id: nextButton
        anchors
        {
            right: parent.right
            bottom: parent.bottom
        }
        enabled:
        {
            // Printer name cannot be empty
            const localPrinterItem = printerSelectorLoader.item;
            return localPrinterItem != null;
        }

        text: base.currentItem.next_page_button_text
        onClicked:
        {
            // Create a local printer
            const localPrinterItem = printerSelectorLoader.item.addMachine();
            if(localPrinterItem)
            {
                base.showNextPage();
            }
        }
    }
}
