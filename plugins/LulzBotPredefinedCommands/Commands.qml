import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1

import UM 1.3 as UM
import Cura 1.0 as Cura

Item {
    property int deviceCount: Cura.MachineManager.printerOutputDevices.length
    property var connectedPrinter: deviceCount >= 1 ? Cura.MachineManager.printerOutputDevices[deviceCount - 1] : null
    property var printerModel: connectedPrinter != null && connectedPrinter.address != "None" ? connectedPrinter.activePrinter : null
    property bool canSendCommand: connectedPrinter.acceptsCommands
    width: base.width
    height: 130

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

    Rectangle {
        id: sectionHeader
        color: UM.Theme.getColor("setting_category")
        width: base.width
        height: UM.Theme.getSize("section").height

        Label
        {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: UM.Theme.getSize("default_margin").width
            text: "LulzBot Predefined Commands"
            font: UM.Theme.getFont("default")
            color: UM.Theme.getColor("setting_category_text")
        }
    }

    GridLayout {
        id: predefinedButtons
        columns: 2
        rows: 3
        rowSpacing: UM.Theme.getSize("default_margin").width
        columnSpacing: UM.Theme.getSize("default_margin").width / 2
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: sectionHeader.bottom
        anchors.topMargin: UM.Theme.getSize("default_margin").width
        anchors.leftMargin: UM.Theme.getSize("default_margin").width
        anchors.rightMargin: UM.Theme.getSize("default_margin").width

        Button {
            text: "Cool Nozzle"
            Layout.row: 0
            Layout.column: 0
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: width
            Layout.preferredHeight: height
            width: (base.width / 2) - (UM.Theme.getSize("default_margin").width * (3 / 2))
            height: UM.Theme.getSize("setting_control").height * 1.5
            enabled: checkEnabled()

            onClicked:
            {
                connectedPrinter.setTargetHotendTemperature(Cura.MonitorStageStorage.extruderNumber, 0)
            }
            style:  UM.Theme.styles.monitor_checkable_button_style
        }

        Button {
            text: "Cool bed"
            Layout.row: 0
            Layout.column: 1
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: width
            Layout.preferredHeight: height
            width: (base.width / 2) - (UM.Theme.getSize("default_margin").width * (3 / 2))
            height: UM.Theme.getSize("setting_control").height * 1.5
            enabled: checkEnabled()

            onClicked:
            {
                connectedPrinter.setTargetBedTemperature(0)
            }
            style:  UM.Theme.styles.monitor_checkable_button_style
        }

        Button {
            text: "Cold Pull"
            Layout.row: 1
            Layout.column: 0
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: width
            Layout.preferredHeight: height
            width: (base.width / 2) - (UM.Theme.getSize("default_margin").width * (3 / 2))
            height: UM.Theme.getSize("setting_control").height * 1.5
            enabled:
            {
                var name = Cura.MachineManager.activeMachine.name
                if(name.includes("Aerostruder"))
                {
                    return false;
                }
                else
                {
                    return canSendCommand && true
                }
            }

            onClicked:
            {
                connectedPrinter.coldPull(Cura.MonitorStageStorage.extruderNumber)
            }
            style:  UM.Theme.styles.monitor_checkable_button_style
        }

        Button {
            text: "Motors off"
            Layout.row: 1
            Layout.column: 1
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: width
            Layout.preferredHeight: height
            width: (base.width / 2) - (UM.Theme.getSize("default_margin").width * (3 / 2))
            height: UM.Theme.getSize("setting_control").height * 1.5
            enabled: checkEnabled()

            onClicked:
            {
                Cura.USBPrinterManager.sendCommandToCurrentPrinter("M18")
            }
            style:  UM.Theme.styles.monitor_checkable_button_style
        }

        Button {
            text: "Level X Axis"
            Layout.row: 2
            Layout.column: 0
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: width
            Layout.preferredHeight: height
            width: (base.width / 2) - (UM.Theme.getSize("default_margin").width * (3 / 2))
            height: UM.Theme.getSize("setting_control").height * 1.5
            enabled: canSendCommand && connectedPrinter.supportLevelXAxis

            onClicked:
            {
                connectedPrinter.levelXAxis()
            }
            style:  UM.Theme.styles.monitor_checkable_button_style
        }

        Button {
            text: "Wipe Nozzle"
            Layout.row: 2
            Layout.column: 1
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: width
            Layout.preferredHeight: height
            width: (base.width / 2) - (UM.Theme.getSize("default_margin").width * (3 / 2))
            height: UM.Theme.getSize("setting_control").height * 1.5

            enabled: canSendCommand && connectedPrinter.supportWipeNozzle

            onClicked:
            {
                connectedPrinter.wipeNozzle()
            }
            style: UM.Theme.styles.monitor_checkable_button_style
        }

        Button {
            id: toolHeadSwapButton
            text: "Tool Head Swapping and Filament Changing Position"
            Layout.row: 3
            Layout.column: 0
            Layout.columnSpan: 2
            Layout.preferredWidth: width
            Layout.preferredHeight: height
            width: base.width - (UM.Theme.getSize("default_margin").width * 2)
            height: UM.Theme.getSize("setting_control").height * 1.5
            enabled: checkEnabled()

            onClicked:
            {
                Cura.USBPrinterManager.sendCommandToCurrentPrinter("G28 O\nG27")
            }

            onHoveredChanged:
            {
                if (hovered)
                {
                    base.showTooltip(
                        base,
                        {x: 0, y: toolHeadSwapButton.mapToItem(base, 0, -parent.height).y},
                        catalog.i18nc("@tooltip of tool head swap", "This is a test to see if tool tips work in this module")
                    );
                }
                else
                {
                    base.hideTooltip();
                }
            }
            style: UM.Theme.styles.monitor_checkable_button_style
        }

    }
}
