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
    property string preferredCategory: "LulzBot"
    property string activeCategory: preferredCategory
    property bool currentState: true

    minimumWidth: UM.Theme.getSize("modal_window_minimum").width*0.4
    minimumHeight: UM.Theme.getSize("modal_window_minimum").height*0.4
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
        ExclusiveGroup { id: printerGroup; }

        Component
        {
            id: lulzbotSelector

            Item
            {
                function getMachineName()
                {
                    var name = "LulzBot Printer"
                    return name
                }

                function addMachine()
                {
                    base.visible = false
                }

                function update()
                {
                    machineName.text = getMachineName();
                }
            }
        }

        Component
        {
            id: otherSelector

            Item
            {
                id: root

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
            bottom: machineNameRow.top
        }

        onSourceComponentChanged: item.update()
    }

    Row
    {
        id: machineNameRow
        anchors.bottom:parent.bottom
        spacing: UM.Theme.getSize("default_margin").width

        Label
        {
            text: catalog.i18nc("@label", "Printer Name:")
            anchors.verticalCenter: machineName.verticalCenter
        }

        TextField
        {
            id: machineName
            text: printerSelectorLoader.item.getMachineName()
            implicitWidth: UM.Theme.getSize("standard_list_input").width
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
        text: currentState ? "O" : "L"
        tooltip: currentState ? catalog.i18nc("@action:button", "Select other printer") : catalog.i18nc("@action:button", "Select LulzBot printer")
        anchors.bottom: parent.bottom
        anchors.right: addPrinterButton.left
        width: height
        onClicked:
        {
            currentState = !currentState
            printerSelectorLoader.sourceComponent = currentState ? lulzbotSelector : otherSelector;
        }
    }
}
