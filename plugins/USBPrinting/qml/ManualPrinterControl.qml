// Copyright (c) 2022 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.15
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.3

import UM 1.5 as UM
import Cura 1.0 as Cura

import "."


Item
{
    property var printerModel: null
    property var activePrintJob: printerModel != null ? printerModel.activePrintJob : null
    property var connectedPrinter: Cura.MachineManager.printerOutputDevices.length >= 1 ? Cura.MachineManager.printerOutputDevices[0] : null
    property var _buttonSize: UM.Theme.getSize("setting_control").height + UM.Theme.getSize("thin_margin").height
    implicitWidth: parent.width
    implicitHeight: childrenRect.height

    function checkEnabled() 
    {
        if (printerModel == null)
        {
            return false; //Can't control the printer if not connected
        }

        if (connectedPrinter == null)
        {
            return false; //Not allowed to do anything.
        }

        if (!connectedPrinter.acceptsCommands)
        {
            return false;
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

        spacing: UM.Theme.getSize("default_margin").height

        MonitorSection
        {
            label: catalog.i18nc("@label", "Manual Printer Control")
            width: base.width
        }

        Row
        {
            id: baseControls

            width: base.width - 2 * UM.Theme.getSize("default_margin").width
            height: childrenRect.height
            anchors.left: parent.left
            anchors.topMargin: UM.Theme.getSize("default_margin").height * 100
            anchors.leftMargin: UM.Theme.getSize("default_margin").width
            spacing: UM.Theme.getSize("default_margin").width

            Cura.SecondaryButton
            {
                height: UM.Theme.getSize("setting_control").height
                width: base.width / 2 - (UM.Theme.getSize("default_margin").width * 1.5)
                text: "Connect"
                enabled: false
                onClicked: connectedPrinter.connect()
            }

            Cura.SecondaryButton
            {
                height: UM.Theme.getSize("setting_control").height
                width: base.width / 2 - (UM.Theme.getSize("default_margin").width * 1.5)
                text: "Disconnect"
                enabled: false
                onClicked:
                {
                    OutputDeviceHeader.pressedConnect = false
                    connectedPrinter.close() // May need to be changed to a different function
                }
            }
        }

        Row
        {

            width: base.width - 2 * UM.Theme.getSize("default_margin").width
            height: childrenRect.height
            anchors.left: parent.left
            anchors.topMargin: UM.Theme.getSize("default_margin").height * 100
            anchors.leftMargin: UM.Theme.getSize("default_margin").width
            spacing: UM.Theme.getSize("default_margin").width

            Cura.SecondaryButton
            {
                height: UM.Theme.getSize("setting_control").height
                width: base.width - UM.Theme.getSize("default_margin").width - UM.Theme.getSize("default_margin").width
                text: catalog.i18nc("@label", "Console")
                enabled: connectedPrinter.acceptsCommands ? connectedPrinter.connectionState == 2 : false
                onClicked:
                {
                    connectedPrinter.messageFromPrinter.disconnect(printer_control.receive)
                    connectedPrinter.messageFromPrinter.connect(printer_control.receive)
                    printer_control.visible = true;
                }
            }
        }

        Row
        {

            width: base.width - 2 * UM.Theme.getSize("default_margin").width
            height: childrenRect.height
            anchors.left: parent.left
            anchors.topMargin: UM.Theme.getSize("default_margin").height * 100
            anchors.leftMargin: UM.Theme.getSize("default_margin").width
            spacing: UM.Theme.getSize("default_margin").width

            Cura.SecondaryButton
            {
                property var activeMachineId: Cura.MachineManager.activeMachine ? Cura.MachineManager.activeMachine.id : null
                property var machineActions: Cura.MachineActionManager.getSupportedActions(Cura.MachineManager.getDefinitionByMachineId(activeMachineId))
                property var updateAction
                property bool canUpdate: {
                    for (var i = 0; i < machineActions.length; i++)
                    {
                        if (machineActions[i].label.toLowerCase() == "firmware update")
                        {
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
                onClicked:
                {
                        var currentItem = updateAction
                        actionDialog.loader.manager = currentItem
                        actionDialog.loader.source = currentItem.qmlPath
                        actionDialog.title = currentItem.label
                        actionDialog.show()
                }
            }
        }

        Row
        {
            width: base.width - 2 * UM.Theme.getSize("default_margin").width
            height: childrenRect.height
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

            GridLayout
            {
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


            Column
            {
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

        Row
        {
            id: distancesRow

            width: base.width - 2 * UM.Theme.getSize("default_margin").width
            height: childrenRect.height
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

            Row
            {
                Repeater
                {
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

        Rectangle
        {
            color: UM.Theme.getColor("wide_lining")
            width: parent.width
            height: UM.Theme.getSize("thick_lining").width
        }

        Row
        {
            id: extruderChoiceRow

            width: base.width - 2 * UM.Theme.getSize("default_margin").width
            height: childrenRect.height
            anchors.left: parent.left
            anchors.leftMargin: UM.Theme.getSize("default_margin").width

            spacing: UM.Theme.getSize("default_margin").width

            visible: extruderRepeater.count > 1

            enabled: checkEnabled()

            property int selectedExtruder: 0

            UM.Label
            {
                text: catalog.i18nc("@label", "Extruder Selected")
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
                    id: extruderRepeater
                    model: machineExtruderCount.properties.value
                    delegate: Cura.SecondaryButton
                    {
                        height: UM.Theme.getSize("setting_control").height
                        width: extrudeButton.width + Math.round(UM.Theme.getSize("default_margin").width * 0.5)

                        text: index + 1
                        ButtonGroup.group: extruderGroup
                        checkable: true
                        checked: index == extruderChoiceRow.selectedExtruder
                        onClicked:
                        {
                            printerModel.sendRawCommand("T" + index.toString())
                            extruderChoiceRow.selectedExtruder = index
                        }

                    }
                }
            }
        }

        Row
        {
            id: extrudeRow

            width: base.width - 2 * UM.Theme.getSize("default_margin").width
            height: childrenRect.height
            anchors.left: parent.left
            anchors.leftMargin: UM.Theme.getSize("default_margin").width

            spacing: UM.Theme.getSize("default_margin").width

            enabled: checkEnabled() && printerModel.extruders[extruderChoiceRow.selectedExtruder].hotendTemperature > 160

            UM.Label
            {
                text: catalog.i18nc("@label", "Extrude")
                color: UM.Theme.getColor("setting_control_text")
                font: UM.Theme.getFont("default")

                width: Math.floor(parent.width * 0.4) - UM.Theme.getSize("default_margin").width
                height: UM.Theme.getSize("setting_control").height
                verticalAlignment: Text.AlignVCenter
            }

            Cura.SecondaryButton
            {
                id: extrudeButton
                text: "Extrude"
                width: (2 * height) + Math.round(1.5 * UM.Theme.getSize("default_margin").width)
                height: UM.Theme.getSize("setting_control").height

                onClicked:
                {
                    printerModel.sendRawCommand("M83")
                    printerModel.sendRawCommand("G1 E" + extrudeAmountRow.extrudeAmount.toString() + " F120")
                    printerModel.sendRawCommand("M82")
                }
            }

            Cura.SecondaryButton
            {
                id: retractButton
                text: "Retract"
                width: (2 * height) + Math.round(1.5* UM.Theme.getSize("default_margin").width)
                height: UM.Theme.getSize("setting_control").height

                onClicked:
                {
                    printerModel.sendRawCommand("M83")
                    printerModel.sendRawCommand("G1 E-" + extrudeAmountRow.extrudeAmount.toString() + " F120")
                    printerModel.sendRawCommand("M82")
                }
            }
        }

        Row
        {
            id: extrudeAmountRow

            width: base.width - 2 * UM.Theme.getSize("default_margin").width
            height: childrenRect.height
            anchors.left: parent.left
            anchors.leftMargin: UM.Theme.getSize("default_margin").width

            spacing: UM.Theme.getSize("default_margin").width

            enabled: checkEnabled()

            property int extrudeAmount: 10

            UM.Label
            {
                text: catalog.i18nc("@label", "Extrude Amount")
                color: UM.Theme.getColor("setting_control_text")
                font: UM.Theme.getFont("default")

                width: Math.floor(parent.width * 0.4) - UM.Theme.getSize("default_margin").width
                height: UM.Theme.getSize("setting_control").height
                verticalAlignment: Text.AlignVCenter
            }

            Rectangle //Input field for extrude amount.
            {
                id: extrudeAmountControl
                color: !enabled ? UM.Theme.getColor("setting_control_disabled") : showError ? UM.Theme.getColor("setting_validation_error_background") : UM.Theme.getColor("setting_validation_ok")
                property var showError:
                {
                    if (false)
                    {
                        return true
                    } else
                    {
                        return false
                    }
                }
                enabled: checkEnabled()
                border.width: UM.Theme.getSize("default_lining").width
                border.color: !enabled ? UM.Theme.getColor("setting_control_disabled_border") : extruderAmountInputMouseArea.containsMouse ? UM.Theme.getColor("setting_control_border_highlight") : UM.Theme.getColor("setting_control_border")
                width: (extrudeButton.width * 2) + UM.Theme.getSize("default_margin").width
                height: UM.Theme.getSize("monitor_preheat_temperature_control").height
                visible: true
                Rectangle //Highlight of input field.
                {
                    anchors.fill: parent
                    anchors.margins: UM.Theme.getSize("default_lining").width
                    color: UM.Theme.getColor("setting_control_highlight")
                    opacity: extrudeAmountControl.hovered ? 1.0 : 0
                }
                MouseArea //Change cursor on hovering.
                {
                    id: extruderAmountInputMouseArea
                    hoverEnabled: true
                    anchors.fill: parent
                    cursorShape: Qt.IBeamCursor
                }
                UM.Label
                {
                    id: unit
                    anchors.right: parent.right
                    anchors.rightMargin: UM.Theme.getSize("setting_unit_margin").width
                    anchors.verticalCenter: parent.verticalCenter

                    text: "mm";
                    color: UM.Theme.getColor("setting_unit")
                    font: UM.Theme.getFont("default")
                }
                TextInput
                {
                    id: extruderAmountInput
                    font: UM.Theme.getFont("default")
                    color: !enabled ? UM.Theme.getColor("setting_control_disabled_text") : UM.Theme.getColor("setting_control_text")
                    selectByMouse: true
                    maximumLength: 4
                    enabled: parent.enabled
                    validator: RegularExpressionValidator
                    {
                        regularExpression: /^[0-9]{0,4}$/
                    }
                    anchors.left: parent.left
                    anchors.leftMargin: UM.Theme.getSize("setting_unit_margin").width
                    anchors.right: unit.left
                    anchors.verticalCenter: parent.verticalCenter
                    renderType: Text.NativeRendering

                    text: extrudeAmountRow.extrudeAmount

                    onTextEdited:
                    {
                        if (extruderAmountInput.text == "")
                        {
                            extrudeAmountRow.extrudeAmount = 0
                        } else
                        {
                            extrudeAmountRow.extrudeAmount = parseInt(extruderAmountInput.text)
                        }
                    }

                    onEditingFinished:
                    {
                        if (extruderAmountInput.text == "")
                        {
                            extruderAmountInput.text = 0
                        }
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

            width: base.width - 2 * UM.Theme.getSize("default_margin").width
            height: childrenRect.height + UM.Theme.getSize("default_margin").width
        }

        UM.SettingPropertyProvider
        {
            id: machineExtruderCount
            containerStack: Cura.MachineManager.activeMachine
            key: "machine_extruder_count"
            watchedProperties: ["value"]
        }

        ListModel
        {
            id: distancesModel
            ListElement { label: "0.1"; value: 0.1 }
            ListElement { label: "1";   value: 1   }
            ListElement { label: "10";  value: 10  }
            ListElement { label: "100"; value: 100 }
        }
        ButtonGroup { id: distanceGroup }
        ButtonGroup { id: extruderGroup }
    }
}
