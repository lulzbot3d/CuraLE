// Copyright (c) 2019 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.3

import UM 1.3 as UM
import Cura 1.0 as Cura

import "."


Item
{
    property var printerModel: null
    property var activePrintJob: printerModel != null ? printerModel.activePrintJob : null
    property var outputDeviceCount: Cura.MachineManager.printerOutputDevices.length
    property var availablePrinter: outputDeviceCount >= 1 ? Cura.MachineManager.printerOutputDevices[outputDeviceCount - 1] : null
    property var connectedDevice:
    {
        if (availablePrinter != null)
        {
            return availablePrinter.acceptsCommands ? availablePrinter : null
        }
        else
        {
            return null
        }
    }

    implicitWidth: parent.width
    implicitHeight: childrenRect.height

    function checkEnabled()
    {
        if (printerModel == null)
        {
            return false; //Can't control the printer if not connected
        }

        if (connectedDevice == null)
        {
            return false; //Not allowed to do anything.
        }

        if(activePrintJob == null)
        {
            return true;
        }

        if (activePrintJob.state == "printing" || activePrintJob.state == "resuming" || activePrintJob.state == "pausing" || activePrintJob.state == "error" || activePrintJob.state == "offline")
        {
            return false; //Printer is in a state where it can't react to manual control
        }
        return true;
    }

    Column
    {

        MonitorSection
        {
            label: catalog.i18nc("@label", "Manual Printer Control")
            width: base.width
        }

        Label
        {
            text: " " // This actually acts as a spacer
        }

        Row
        {
            id: baseControls

            width: base.width - 2 * UM.Theme.getSize("default_margin").width
            height: childrenRect.height + UM.Theme.getSize("default_margin").width
            anchors.left: parent.left
            anchors.topMargin: UM.Theme.getSize("default_margin").height * 100
            anchors.leftMargin: UM.Theme.getSize("default_margin").width
            spacing: UM.Theme.getSize("default_margin").width

            Button
            {
                height: UM.Theme.getSize("setting_control").height
                width: height*3 + UM.Theme.getSize("default_margin").width
                text: "Connect"
                enabled:
                {
                    if(availablePrinter != null && availablePrinter.address != "None")
                    {
                        if(availablePrinter.connectionState == 0 || availablePrinter.connectionState > 5)
                        {
                            return true
                        }
                    }
                    return false
                }
                onClicked: availablePrinter.connect()
                style: UM.Theme.styles.monitor_checkable_button_style
            }

            Button
            {
                height: UM.Theme.getSize("setting_control").height
                width: height*3 + UM.Theme.getSize("default_margin").width
                text: "Disconnect"
                enabled: checkEnabled()
                onClicked:
                {
                    OutputDeviceHeader.pressedConnect = false
                    availablePrinter.close() // May need to be changed to a different function
                }
                style: UM.Theme.styles.monitor_checkable_button_style
            }

            Button
            {
                height: UM.Theme.getSize("setting_control").height
                width: height*3 + UM.Theme.getSize("default_margin").width
                text: catalog.i18nc("@label", "Console")
                enabled: availablePrinter.acceptsCommands ? availablePrinter.connectionState == 2 : false
                onClicked:
                {
                    availablePrinter.messageFromPrinter.disconnect(printer_control.receive)
                    availablePrinter.messageFromPrinter.connect(printer_control.receive)
                    printer_control.visible = true;
                }
                style: UM.Theme.styles.monitor_checkable_button_style
            }
        }

        Row {

            width: base.width - 2 * UM.Theme.getSize("default_margin").width
            height: childrenRect.height + UM.Theme.getSize("default_margin").width
            anchors.left: parent.left
            anchors.topMargin: UM.Theme.getSize("default_margin").height * 100
            anchors.leftMargin: UM.Theme.getSize("default_margin").width
            spacing: UM.Theme.getSize("default_margin").width

            Button
            {
                property var machineActions: Cura.MachineActionManager.getSupportedActions(Cura.MachineManager.getDefinitionByMachineId(Cura.MachineManager.activeMachine.id))
                property var updateAction
                property bool canUpdate: {
                    for (var i = 0; i < machineActions.length; i++) {
                        if (machineActions[i].label == "Firmware Update") {
                            updateAction = machineActions[i]
                            return true;
                        }
                    }
                    return false;
                }
                height: UM.Theme.getSize("setting_control").height
                width: height*9 + UM.Theme.getSize("default_margin").width * 5
                text: catalog.i18nc("@label", "Firmware Update")
                enabled: canUpdate
                onClicked:
                {
                        var currentItem = updateAction
                        actionDialog.loader.manager = currentItem
                        actionDialog.loader.source = currentItem.qmlPath
                        actionDialog.title = currentItem.label
                        actionDialog.show()
                }
                style: UM.Theme.styles.monitor_checkable_button_style
            }
        }

        Row
        {
            width: base.width - 2 * UM.Theme.getSize("default_margin").width
            height: childrenRect.height + UM.Theme.getSize("default_margin").width
            anchors.left: parent.left
            anchors.leftMargin: UM.Theme.getSize("default_margin").width

            spacing: UM.Theme.getSize("default_margin").width

            enabled: checkEnabled()

            Label
            {
                text: catalog.i18nc("@label", "Jog Position")
                color: UM.Theme.getColor("setting_control_text")
                font: UM.Theme.getFont("default")

                width: Math.floor(parent.width * 0.4) - UM.Theme.getSize("default_margin").width
                height: UM.Theme.getSize("setting_control").height
                verticalAlignment: Text.AlignVCenter
            }

            GridLayout
            {
                columns: 3
                rows: 4
                rowSpacing: UM.Theme.getSize("default_lining").width
                columnSpacing: UM.Theme.getSize("default_lining").height

                Label
                {
                    text: catalog.i18nc("@label", "X/Y")
                    color: UM.Theme.getColor("setting_control_text")
                    font: UM.Theme.getFont("default")
                    width: height
                    height: UM.Theme.getSize("setting_control").height
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter

                    Layout.row: 0
                    Layout.column: 1
                    Layout.preferredWidth: width
                    Layout.preferredHeight: height
                }

                Button
                {
                    Layout.row: 1
                    Layout.column: 1
                    Layout.preferredWidth: width
                    Layout.preferredHeight: height
                    iconSource: UM.Theme.getIcon("ChevronSingleUp");
                    style: UM.Theme.styles.monitor_button_style
                    width: height
                    height: UM.Theme.getSize("setting_control").height

                    onClicked:
                    {
                        printerModel.moveHead(0, distancesRow.currentDistance, 0)
                    }
                }

                Button
                {
                    Layout.row: 2
                    Layout.column: 0
                    Layout.preferredWidth: width
                    Layout.preferredHeight: height
                    iconSource: UM.Theme.getIcon("ChevronSingleLeft");
                    style: UM.Theme.styles.monitor_button_style
                    width: height
                    height: UM.Theme.getSize("setting_control").height

                    onClicked:
                    {
                        printerModel.moveHead(-distancesRow.currentDistance, 0, 0)
                    }
                }

                Button
                {
                    Layout.row: 2
                    Layout.column: 2
                    Layout.preferredWidth: width
                    Layout.preferredHeight: height
                    iconSource: UM.Theme.getIcon("ChevronSingleRight");
                    style: UM.Theme.styles.monitor_button_style
                    width: height
                    height: UM.Theme.getSize("setting_control").height

                    onClicked:
                    {
                        printerModel.moveHead(distancesRow.currentDistance, 0, 0)
                    }
                }

                Button
                {
                    Layout.row: 3
                    Layout.column: 1
                    Layout.preferredWidth: width
                    Layout.preferredHeight: height
                    iconSource: UM.Theme.getIcon("ChevronSingleDown");
                    style: UM.Theme.styles.monitor_button_style
                    width: height
                    height: UM.Theme.getSize("setting_control").height

                    onClicked:
                    {
                        printerModel.moveHead(0, -distancesRow.currentDistance, 0)
                    }
                }

                Button
                {
                    Layout.row: 2
                    Layout.column: 1
                    Layout.preferredWidth: width
                    Layout.preferredHeight: height
                    iconSource: UM.Theme.getIcon("House");
                    style: UM.Theme.styles.monitor_button_style
                    width: height
                    height: UM.Theme.getSize("setting_control").height

                    onClicked:
                    {
                        printerModel.homeHead()
                    }
                }
            }


            Column
            {
                spacing: UM.Theme.getSize("default_lining").height

                Label
                {
                    text: catalog.i18nc("@label", "Z")
                    color: UM.Theme.getColor("setting_control_text")
                    font: UM.Theme.getFont("default")
                    width: UM.Theme.getSize("section").height
                    height: UM.Theme.getSize("setting_control").height
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }

                Button
                {
                    iconSource: UM.Theme.getIcon("ChevronSingleUp");
                    style: UM.Theme.styles.monitor_button_style
                    width: height
                    height: UM.Theme.getSize("setting_control").height

                    onClicked:
                    {
                        printerModel.moveHead(0, 0, distancesRow.currentDistance)
                    }
                }

                Button
                {
                    iconSource: UM.Theme.getIcon("House");
                    style: UM.Theme.styles.monitor_button_style
                    width: height
                    height: UM.Theme.getSize("setting_control").height

                    onClicked:
                    {
                        printerModel.homeBed()
                    }
                }

                Button
                {
                    iconSource: UM.Theme.getIcon("ChevronSingleDown");
                    style: UM.Theme.styles.monitor_button_style
                    width: height
                    height: UM.Theme.getSize("setting_control").height

                    onClicked:
                    {
                        printerModel.moveHead(0, 0, -distancesRow.currentDistance)
                    }
                }
            }
        }

        Row
        {
            id: distancesRow

            width: base.width - 2 * UM.Theme.getSize("default_margin").width
            height: childrenRect.height + UM.Theme.getSize("default_margin").width
            anchors.left: parent.left
            anchors.leftMargin: UM.Theme.getSize("default_margin").width

            spacing: UM.Theme.getSize("default_margin").width

            property real currentDistance: 10

            enabled: checkEnabled()

            Label
            {
                text: catalog.i18nc("@label", "Jog Distance")
                color: UM.Theme.getColor("setting_control_text")
                font: UM.Theme.getFont("default")

                width: Math.floor(parent.width * 0.4) - UM.Theme.getSize("default_margin").width
                height: UM.Theme.getSize("setting_control").height
                verticalAlignment: Text.AlignVCenter
            }

            Row
            {
                Repeater
                {
                    model: distancesModel
                    delegate: Button
                    {
                        height: UM.Theme.getSize("setting_control").height
                        width: height + UM.Theme.getSize("default_margin").width

                        text: model.label
                        exclusiveGroup: distanceGroup
                        checkable: true
                        checked: distancesRow.currentDistance == model.value
                        onClicked: distancesRow.currentDistance = model.value

                        style: UM.Theme.styles.monitor_checkable_button_style
                    }
                }
            }
        }

        PrinterControlWindow
	    {
	        id: printer_control
            activePrinter: printerModel
	        onCommand:
	        {
	            if (!Cura.USBPrinterManager.sendCommandToCurrentPrinter(command))
	            {
	                receive("i", "Error: Printer not connected")
	            }
	        }
	    }

        UM.Dialog
        {
            id: actionDialog
            minimumWidth: UM.Theme.getSize("modal_window_minimum").width
            minimumHeight: UM.Theme.getSize("modal_window_minimum").height
            maximumWidth: minimumWidth * 3
            maximumHeight: minimumHeight * 3
            rightButtons: Button
            {
                text: catalog.i18nc("@action:button", "Close")
                iconName: "dialog-close"
                onClicked: actionDialog.reject()
            }
        }

        ListModel
        {
            id: distancesModel
            ListElement { label: "0.1"; value: 0.1 }
            ListElement { label: "1";   value: 1   }
            ListElement { label: "10";  value: 10  }
            ListElement { label: "100"; value: 100 }
        }
        ExclusiveGroup { id: distanceGroup }
    }
}
