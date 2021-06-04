// Copyright (c) 2017 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import QtQuick.Window 2.1

import QtQuick.Controls.Styles 1.1

import UM 1.2 as UM
import Cura 1.0 as Cura


UM.Dialog
{
    id: base
    title: catalog.i18nc("@title:window", "Add Printer")
    property bool firstRun: false
    property string preferredCategory: ""
    property string activeCategory: preferredCategory
    property bool currentState: true

    minimumWidth: UM.Theme.getSize("modal_window_minimum").width*0.6
    minimumHeight: UM.Theme.getSize("modal_window_minimum").height*0.5
    width: minimumWidth
    height: minimumHeight

    flags: {
        var window_flags = Qt.Dialog | Qt.CustomizeWindowHint | Qt.WindowTitleHint;
        if (Cura.MachineManager.activeDefinitionId !== "") //Disallow closing the window if we have no active printer yet. You MUST add a printer.
        {
            window_flags |= Qt.WindowCloseButtonHint;
        }
        return window_flags;
    }

    onVisibilityChanged:
    {
        // Reset selection and machine name
        if (visible) {
            currentState = true;
            printerSelectorLoader.sourceComponent = lulzbotSelector;
            printerSelectorLoader.item.update();
            machineName.text = printerSelectorLoader.item.getMachineName();
        }
    }

    signal machineAdded(string id)

    onAccepted: printerSelectorLoader.item.addMachine()

    Item
    {
        UM.I18nCatalog
        {
            id: catalog;
            name: "cura";
        }
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
                    base.visible = false
                    var item = toolheadsModel.getItem(toolheadSelection.selectedIndex).id
                    Cura.MachineManager.addMachine(machineName.text, item, lcdSelection.selectedIndex == 0 ? true: false,true/*revisionSelection.selectedIndex == 0 ? true: false*/)
                    base.machineAdded(item)
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

                Row
                {
                    anchors.fill: parent
                    spacing: 2

                    GroupBox
                    {
                        id: printerSelection
                        width: parent.width/17*4*4
                        anchors.bottom: parent.bottom
                        anchors.top: parent.top
                        anchors.bottomMargin: UM.Theme.getSize("default_margin").width

                        title: catalog.i18nc("@action:button", "Printer")
                        ExclusiveGroup { id: printerGroup }

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
                                delegate: RadioButton
                                {
                                    text: model.name
                                    exclusiveGroup: printerGroup
                                    checked: model.index == 0
                                    onClicked: { printerSelection.selectedIndex = model.index; printerSelection.lcd = model.lcd;printerSelection.revision = model.revision; printerSelection.baseMachine = model.id }
                                }

                                Component.onCompleted: {printerSelection.lcd = model.getItem(0).lcd;printerSelection.revision = model.getItem(0).revision; printerSelection.baseMachine = model.getItem(0).id}
                            }
                        }
                    }
                    GroupBox
                    {
                        id: toolheadSelection
                        width: parent.width/17*4*4
                        anchors.bottom: parent.bottom
                        anchors.top: parent.top
                        anchors.bottomMargin: UM.Theme.getSize("default_margin").width

                        title: catalog.i18nc("@action:button", "Tool Head | Nozzle Diameter")
                        ExclusiveGroup
                        {
                            id: toolheadGroup;
                        }

                        property int selectedIndex: 0

                        Column
                        {
                            Repeater
                            {
                                model: Cura.LulzBotToolheadsModel { id: toolheadsModel; baseMachineProperty: printerSelection.baseMachine }
                                delegate: RadioButton
                                {
                                    text: model.toolhead
                                    exclusiveGroup: toolheadGroup
                                    checked: model.index == 0
                                    onCheckedChanged: { if(checked) {toolheadSelection.selectedIndex = model.index; machineName.text = model.name }}
                                }
                            }
                        }
                    }
                    GroupBox
                    {
                        id: lcdSelection
                        width: parent.width/17*3
                        anchors.bottom: parent.bottom
                        anchors.top: parent.top
                        anchors.bottomMargin: UM.Theme.getSize("default_margin").width

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
                    /*GroupBox
                    {
                        id: revisionSelection
                        width: parent.width/17*4-6
                        anchors.bottom: parent.bottom
                        anchors.top: parent.top
                        anchors.bottomMargin: UM.Theme.getSize("default_margin").width

                        title: catalog.i18nc("@action:button", "Z-Axis Gearbox")
                        ExclusiveGroup { id: revisionGroup }

                        property int selectedIndex: 0

                        Column
                        {
                            Repeater
                            {
                                model: ["Rev B(Black Gearbox)", "Rev A(Silver Gearbox)"]
                                delegate: RadioButton
                                {
                                    text: modelData
                                    exclusiveGroup: revisionGroup
                                    checked: model.index == 0
                                    enabled: printerSelection.revision
                                    onEnabledChanged:
                                    {
                                        if(!enabled && model.index == 0) checked = true
                                    }
                                    onClicked: { revisionSelection.selectedIndex = model.index }
                                }
                            }
                        }
                    }*/
                }
            }
        }

        Component
        {
            id: otherSelector

            Item
            {
                id: root

                ExclusiveGroup { id: printerGroup; }

                function getMachineName()
                {
                    var name = machineList.model.getItem(machineList.currentIndex) != undefined ? machineList.model.getItem(machineList.currentIndex).name : ""
                    return name
                }

                function addMachine()
                {
                    base.visible = false
                    var item = machineList.model.getItem(machineList.currentIndex);
                    Cura.MachineManager.addMachine(machineName.text, item.id)
                    base.machineAdded(item.id) // Emit signal that the user added a machine.
                }

                function update()
                {
                    activeCategory = preferredCategory;
                    machineList.currentIndex = 0;
                    machineName.text = getMachineName();
                }

                ScrollView
                {
                    id: machinesHolder
                    anchors.fill: parent

                    ListView
                    {
                        id: machineList
                        signal reset();

                        model: UM.DefinitionContainersModel
                        {
                            id: machineDefinitionsModel
                            filter: { "visible": true }
                            sectionProperty: "category"
                            preferredSectionValue: preferredCategory
                        }

                        section.property: "section"
                        section.delegate: Button
                        {
                            text: section
                            width: machineList.width
                            style: ButtonStyle
                            {
                                background: Item
                                {
                                    height: UM.Theme.getSize("standard_list_lineheight").height
                                    width: machineList.width
                                }
                                label: Label
                                {
                                    anchors.left: parent.left
                                    anchors.leftMargin: UM.Theme.getSize("standard_arrow").width + UM.Theme.getSize("default_margin").width
                                    text: control.text
                                    color: palette.windowText
                                    font.bold: true
                                    UM.RecolorImage
                                    {
                                        id: downArrow
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.right: parent.left
                                        anchors.rightMargin: UM.Theme.getSize("default_margin").width
                                        width: UM.Theme.getSize("standard_arrow").width
                                        height: UM.Theme.getSize("standard_arrow").height
                                        sourceSize.width: width
                                        sourceSize.height: width
                                        color: palette.windowText
                                        source: base.activeCategory == section ? UM.Theme.getIcon("arrow_bottom") : UM.Theme.getIcon("arrow_right")
                                    }
                                }
                            }

                            onClicked:
                            {
                                base.activeCategory = section;
                                if (machineList.model.getItem(machineList.currentIndex).section != section) {
                                    // Find the first machine from this section
                                    for(var i = 0; i < machineList.model.rowCount(); i++) {
                                        var item = machineList.model.getItem(i);
                                        if (item.section == section) {
                                            machineList.currentIndex = i;
                                            break;
                                        }
                                    }
                                }
                                machineName.text = getMachineName();
                            }
                        }

                        delegate: Column
                        {
                            id: machineColumn
                            spacing: (machineButton.opacity == 1) ? (UM.Theme.getSize("default_margin").height/2) : 0;
                            property bool checked: ListView.isCurrentItem;
                            property int columnIndex: index
                            property ListView listView: ListView.view

                            Rectangle
                            {
                                width: 5
                                height: 0.000001
                            }

                            RadioButton
                            {
                                id: machineButton

                                anchors.left: parent.left
                                anchors.leftMargin: UM.Theme.getSize("standard_list_lineheight").width

                                opacity: 1;
                                height: UM.Theme.getSize("standard_list_lineheight").height;

                                //checked: ListView.isCurrentItem;
                                checked: machineColumn.checked

                                exclusiveGroup: printerGroup;

                                text: model.name

                                onClicked:
                                {
                                    machineColumn.listView.currentIndex = machineColumn.columnIndex;
                                    machineName.text = getMachineName()
                                }

                                states: State
                                {
                                    name: "collapsed";
                                    when: base.activeCategory != model.section;

                                    PropertyChanges { target: machineButton; opacity: 0; height: 0; }
                                }

                                transitions:
                                [
                                    Transition
                                    {
                                        to: "collapsed";
                                        SequentialAnimation
                                        {
                                            NumberAnimation { property: "opacity"; duration: 75; }
                                            NumberAnimation { property: "height"; duration: 75; }
                                        }
                                    },
                                    Transition
                                    {
                                        from: "collapsed";
                                        SequentialAnimation
                                        {
                                            NumberAnimation { property: "height"; duration: 75; }
                                            NumberAnimation { property: "opacity"; duration: 75; }
                                        }
                                    }
                                ]
                            }

                            Rectangle
                            {
                                width: 5
                                height: 0.000001
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
        anchors.left: parent.left
    }

    TextField
    {
        id: machineName
        anchors.right: categoryButton.left
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

    Button
    {
        id: addPrinterButton
        text: catalog.i18nc("@action:button", "Add Printer")
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        onClicked: printerSelectorLoader.item.addMachine()
    }


    Button
    {
        id: categoryButton
        text: currentState ? "Other" : "LulzBot"
        tooltip: currentState ? catalog.i18nc("@action:button", "Select other printer") : catalog.i18nc("@action:button", "Select LulzBot printer")
        anchors.bottom: parent.bottom
        anchors.right: addPrinterButton.left
        onClicked:
        {
            currentState = !currentState
            printerSelectorLoader.sourceComponent = currentState ? lulzbotSelector : otherSelector;
        }
    }
}
