// Copyright (c) 2022 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.3

import UM 1.5 as UM
import Cura 1.0 as Cura

import "."


Item {
    property var printerModel: null
    property var activePrintJob: printerModel != null ? printerModel.activePrintJob : null
    property var outputDeviceCount: Cura.MachineManager.printerOutputDevices.length
    property var availablePrinter: outputDeviceCount >= 1 ? Cura.MachineManager.printerOutputDevices[outputDeviceCount - 1] : null
    property var connectedDevice: {
        if (availablePrinter != null) {
            return availablePrinter.acceptsCommands ? availablePrinter : null
        }
        else {
            return null
        }
    }
    property var _buttonSize: UM.Theme.getSize("setting_control").height + UM.Theme.getSize("thin_margin").height

    implicitWidth: parent.width
    implicitHeight: childrenRect.height

    function checkEnabled() {
        if (printerModel == null) {
            return false; //Can't control the printer if not connected
        }

        if (connectedDevice == null) {
            return false; //Not allowed to do anything.
        }

        if(activePrintJob == null) {
            return true;
        }

        if (activePrintJob.state == "printing" || activePrintJob.state == "resuming" || activePrintJob.state == "pausing" || activePrintJob.state == "error" || activePrintJob.state == "offline") {
            return false; //Printer is in a state where it can't react to manual control
        }
        return true;
    }

    Column {

        MonitorSection {
            label: catalog.i18nc("@label", "Manual Printer Control")
            width: base.width
        }

        Label {
            text: " " // This actually acts as a spacer
        }

        Row {
            id: baseControls

            width: base.width - 2 * UM.Theme.getSize("default_margin").width
            height: childrenRect.height + UM.Theme.getSize("default_margin").width
            anchors.left: parent.left
            anchors.topMargin: UM.Theme.getSize("default_margin").height * 100
            anchors.leftMargin: UM.Theme.getSize("default_margin").width
            spacing: UM.Theme.getSize("default_margin").width

            Button {
                height: UM.Theme.getSize("setting_control").height
                width: base.width / 3 - (UM.Theme.getSize("default_margin").width * 1.3)
                text: "Connect"
                enabled: {
                    if(availablePrinter != null && availablePrinter.address != "None") {
                        if(availablePrinter.connectionState == 0 || availablePrinter.connectionState > 5) {
                            return true
                        }
                    }
                    return false
                }
                onClicked: availablePrinter.connect()
                style: UM.Theme.styles.monitor_checkable_button_style
            }

            Button {
                height: UM.Theme.getSize("setting_control").height
                width: base.width / 3 - (UM.Theme.getSize("default_margin").width * 1.4)
                text: "Disconnect"
                enabled: checkEnabled()
                onClicked: {
                    OutputDeviceHeader.pressedConnect = false
                    availablePrinter.close() // May need to be changed to a different function
                }
                style: UM.Theme.styles.monitor_checkable_button_style
            }

            Button {
                height: UM.Theme.getSize("setting_control").height
                width: base.width / 3 - (UM.Theme.getSize("default_margin").width * 1.3)
                text: catalog.i18nc("@label", "Console")
                enabled: availablePrinter.acceptsCommands ? availablePrinter.connectionState == 2 : false
                onClicked: {
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

            Button {
                property var activeMachineId: Cura.MachineManager.activeMachine ? Cura.MachineManager.activeMachine.id : null
                property var machineActions: Cura.MachineActionManager.getSupportedActions(Cura.MachineManager.getDefinitionByMachineId(activeMachineId))
                property var updateAction
                property bool canUpdate: {
                    for (var i = 0; i < machineActions.length; i++) {
                        if (machineActions[i].label.toLowerCase() == "firmware update") {
                            updateAction = machineActions[i]
                            return true;
                        }
                    }
                    return false;
                }
                height: UM.Theme.getSize("setting_control").height
                width: base.width - UM.Theme.getSize("default_margin").width - UM.Theme.getSize("default_margin").width
                text: catalog.i18nc("@label", "Firmware Update")
                enabled: canUpdate
                onClicked: {
                        var currentItem = updateAction
                        actionDialog.loader.manager = currentItem
                        actionDialog.loader.source = currentItem.qmlPath
                        actionDialog.title = currentItem.label
                        actionDialog.show()
                }
                style: UM.Theme.styles.monitor_checkable_button_style
            }
        }

        Row {
            width: base.width - 2 * UM.Theme.getSize("default_margin").width
            height: childrenRect.height + UM.Theme.getSize("default_margin").width
            anchors.left: parent.left
            anchors.leftMargin: UM.Theme.getSize("default_margin").width

            spacing: UM.Theme.getSize("default_margin").width

            enabled: checkEnabled()

            UM.Label
            {
                text: catalog.i18nc("@label", "Jog Position")
                color: UM.Theme.getColor("setting_control_text")

                width: Math.floor(parent.width * 0.4) - UM.Theme.getSize("default_margin").width
                height: UM.Theme.getSize("setting_control").height
            }

            GridLayout {
                columns: 3
                rows: 4
                rowSpacing: UM.Theme.getSize("default_lining").width
                columnSpacing: UM.Theme.getSize("default_lining").height

                UM.Label
                {
                    text: catalog.i18nc("@label", "X/Y")
                    color: UM.Theme.getColor("setting_control_text")
                    width: height
                    height: UM.Theme.getSize("setting_control").height
                    horizontalAlignment: Text.AlignHCenter

                    Layout.row: 0
                    Layout.column: 1
                    Layout.preferredWidth: width
                    Layout.preferredHeight: height
                }

                Cura.SecondaryButton
                {
                    Layout.row: 1
                    Layout.column: 1
                    Layout.preferredWidth: _buttonSize
                    Layout.preferredHeight: _buttonSize
                    iconSource: UM.Theme.getIcon("ChevronSingleUp")
                    leftPadding: (Layout.preferredWidth - iconSize) / 2

                    onClicked: printerModel.moveHead(0, distancesRow.currentDistance, 0)
                }

                Cura.SecondaryButton
                {
                    Layout.row: 2
                    Layout.column: 0
                    Layout.preferredWidth: _buttonSize
                    Layout.preferredHeight: _buttonSize
                    iconSource: UM.Theme.getIcon("ChevronSingleLeft")
                    leftPadding: (Layout.preferredWidth - iconSize) / 2

                    onClicked: printerModel.moveHead(-distancesRow.currentDistance, 0, 0)
                }

                Cura.SecondaryButton
                {
                    Layout.row: 2
                    Layout.column: 2
                    Layout.preferredWidth: _buttonSize
                    Layout.preferredHeight: _buttonSize
                    iconSource: UM.Theme.getIcon("ChevronSingleRight")
                    leftPadding: (Layout.preferredWidth - iconSize) / 2

                    onClicked:  printerModel.moveHead(distancesRow.currentDistance, 0, 0)
                }

                Cura.SecondaryButton
                {
                    Layout.row: 3
                    Layout.column: 1
                    Layout.preferredWidth: _buttonSize
                    Layout.preferredHeight: _buttonSize
                    iconSource: UM.Theme.getIcon("ChevronSingleDown")
                    leftPadding: (Layout.preferredWidth - iconSize) / 2

                    onClicked: printerModel.moveHead(0, -distancesRow.currentDistance, 0)
                }

                Cura.SecondaryButton
                {
                    Layout.row: 2
                    Layout.column: 1
                    Layout.preferredWidth: _buttonSize
                    Layout.preferredHeight: _buttonSize
                    iconSource: UM.Theme.getIcon("House")
                    leftPadding: (Layout.preferredWidth - iconSize) / 2

                    onClicked:  printerModel.homeHead()
                }
            }


            Column {
                spacing: UM.Theme.getSize("default_lining").height

                UM.Label
                {
                    text: catalog.i18nc("@label", "Z")
                    color: UM.Theme.getColor("setting_control_text")
                    width: UM.Theme.getSize("section").height
                    height: UM.Theme.getSize("setting_control").height
                    horizontalAlignment: Text.AlignHCenter
                }

                Cura.SecondaryButton
                {
                    iconSource: UM.Theme.getIcon("ChevronSingleUp")
                    width: height
                    height: _buttonSize
                    leftPadding: (width - iconSize) / 2

                    onClicked: printerModel.moveHead(0, 0, distancesRow.currentDistance)

                }

                Cura.SecondaryButton
                {
                    iconSource: UM.Theme.getIcon("House")
                    width: height
                    height: _buttonSize
                    leftPadding: (width - iconSize) / 2

                    onClicked: printerModel.homeBed()
                }

                Cura.SecondaryButton
                {
                    iconSource: UM.Theme.getIcon("ChevronSingleDown")
                    width: height
                    height: _buttonSize
                    leftPadding: (width - iconSize) / 2

                    onClicked: printerModel.moveHead(0, 0, -distancesRow.currentDistance)
                }
            }
        }

        Row {
            id: distancesRow

            width: base.width - 2 * UM.Theme.getSize("default_margin").width
            height: childrenRect.height + UM.Theme.getSize("default_margin").width
            anchors.left: parent.left
            anchors.leftMargin: UM.Theme.getSize("default_margin").width

            spacing: UM.Theme.getSize("default_margin").width

            property real currentDistance: 10

            enabled: checkEnabled()

            UM.Label
            {
                text: catalog.i18nc("@label", "Jog Distance")
                color: UM.Theme.getColor("setting_control_text")

                width: Math.floor(parent.width * 0.4) - UM.Theme.getSize("default_margin").width
                height: UM.Theme.getSize("setting_control").height
            }

            Row {
                Repeater {
                    model: distancesModel
                    delegate: Cura.SecondaryButton
                    {
                        height: UM.Theme.getSize("setting_control").height

                        text: model.label
                        ButtonGroup.group: distanceGroup
                        color: distancesRow.currentDistance == model.value ? UM.Theme.getColor("primary_button") : UM.Theme.getColor("secondary_button")
                        textColor: distancesRow.currentDistance == model.value ? UM.Theme.getColor("primary_button_text"): UM.Theme.getColor("secondary_button_text")
                        hoverColor: distancesRow.currentDistance == model.value ? UM.Theme.getColor("primary_button_hover"): UM.Theme.getColor("secondary_button_hover")
                        onClicked: distancesRow.currentDistance = model.value
                    }
                }
            }
        }

        PrinterControlWindow {
	        id: printer_control
            activePrinter: printerModel
	        onCommand: {
	            if (!Cura.USBPrinterManager.sendCommandToCurrentPrinter(command)) {
	                receive("i", "Error: Printer not connected")
	            }
	        }

            width: base.width - 2 * UM.Theme.getSize("default_margin").width
            height: childrenRect.height + UM.Theme.getSize("default_margin").width
            anchors.left: parent.left
            anchors.leftMargin: UM.Theme.getSize("default_margin").width

            spacing: UM.Theme.getSize("default_margin").width

            UM.Label
            {
                text: catalog.i18nc("@label", "Send G-code")
                color: UM.Theme.getColor("setting_control_text")

                width: Math.floor(parent.width * 0.4) - UM.Theme.getSize("default_margin").width
                height: UM.Theme.getSize("setting_control").height
            }

            Row
            {
                // Input field for custom G-code commands.
                Rectangle
                {
                    id: customCommandControl

                    // state
                    visible: printerModel != null ? printerModel.canSendRawGcode: true
                    enabled: {
                        if (printerModel == null) {
                            return false // Can't send custom commands if not connected.
                        }
                        if (connectedPrinter == null || !connectedPrinter.acceptsCommands) {
                            return false // Not allowed to do anything
                        }
                        if (connectedPrinter.jobState == "printing" || connectedPrinter.jobState == "pre_print" || connectedPrinter.jobState == "resuming" || connectedPrinter.jobState == "pausing" || connectedPrinter.jobState == "paused" || connectedPrinter.jobState == "error" || connectedPrinter.jobState == "offline") {
                            return false // Printer is in a state where it can't react to custom commands.
                        }
                        return true
                    }

                    // style
                    color: !enabled ? UM.Theme.getColor("setting_control_disabled") : UM.Theme.getColor("setting_validation_ok")
                    border.width: UM.Theme.getSize("default_lining").width
                    border.color: !enabled ? UM.Theme.getColor("setting_control_disabled_border") : customCommandControlMouseArea.containsMouse ? UM.Theme.getColor("setting_control_border_highlight") : UM.Theme.getColor("setting_control_border")

                    // size
                    width: UM.Theme.getSize("setting_control").width
                    height: UM.Theme.getSize("setting_control").height

                    // highlight
                    Rectangle
                    {
                        anchors.fill: parent
                        anchors.margins: UM.Theme.getSize("default_lining").width
                        color: UM.Theme.getColor("setting_control_highlight")
                        opacity: customCommandControl.hovered ? 1.0 : 0
                    }

                    // cursor hover popup
                    MouseArea
                    {
                        id: customCommandControlMouseArea
                        hoverEnabled: true
                        anchors.fill: parent
                        cursorShape: Qt.IBeamCursor

                        onHoveredChanged:
                        {
                            if (containsMouse)
                            {
                                base.showTooltip(
                                    base,
                                    { x: -tooltip.width, y: customCommandControlMouseArea.mapToItem(base, 0, 0).y },
                                    catalog.i18nc("@tooltip of G-code command input", "Send a custom G-code command to the connected printer. Press 'enter' to send the command.")
                                )
                            }
                            else
                            {
                                base.hideTooltip()
                            }
                        }
                    }

                    TextInput
                    {
                        id: customCommandControlInput

                        // style
                        font: UM.Theme.getFont("default")
                        color: !enabled ? UM.Theme.getColor("setting_control_disabled_text") : UM.Theme.getColor("setting_control_text")
                        selectByMouse: true
                        clip: true
                        enabled: parent.enabled
                        renderType: Text.NativeRendering

                        // anchors
                        anchors.left: parent.left
                        anchors.leftMargin: UM.Theme.getSize("setting_unit_margin").width
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        // send the command when pressing enter
                        // we also clear the text field
                        Keys.onReturnPressed:
                        {
                            printerModel.sendRawCommand(customCommandControlInput.text)
                            customCommandControlInput.text = ""
                        }
                    }
                }
            }
        }

        ListModel {
            id: distancesModel
            ListElement { label: "0.1"; value: 0.1 }
            ListElement { label: "1";   value: 1   }
            ListElement { label: "10";  value: 10  }
            ListElement { label: "100"; value: 100 }
        }
        ButtonGroup { id: distanceGroup }
    }
}
