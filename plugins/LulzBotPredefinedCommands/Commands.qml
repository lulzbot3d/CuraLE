import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1

import UM 1.2 as UM
import Cura 1.0 as Cura

Item
{
    property var connectedPrinter: printerConnected ? Cura.MachineManager.printerOutputDevices[0] : null
    width: 410
    height: 130
    enabled: connectedPrinter

        GridLayout
        {
            id: predefinedButtons
            columns: 3
            rows: 3
            rowSpacing: 1
            columnSpacing: 1
            anchors.fill: parent
            anchors.centerIn: parent
            anchors.leftMargin: 5
            anchors.rightMargin: 5

            Button
            {
                text: "Preheat nozzle"
                Layout.row: 1
                Layout.column: 1
                Layout.preferredWidth: parent.width/3 - predefinedButtons.columnSpacing*7
                Layout.preferredHeight: UM.Theme.getSize("section").height

                onClicked:
                {
                    connectedPrinter.preheatHotend(Cura.MonitorStageStorage.extruderNumber)
                }
                style: UM.Theme.styles.print_monitor_control_button

            }

            Button
            {
                text: "Wipe nozzle"
                Layout.row: 1
                Layout.column: 2
                Layout.preferredWidth: parent.width/3 - predefinedButtons.columnSpacing*7
                Layout.preferredHeight: UM.Theme.getSize("section").height

                enabled: connectedPrinter && connectedPrinter.supportWipeNozzle

                onClicked:
                {
                    connectedPrinter.wipeNozzle()
                }
                style: UM.Theme.styles.print_monitor_control_button

            }

            Button
            {
                text: "Cool nozzle"
                Layout.row: 1
                Layout.column: 3
                Layout.preferredWidth: parent.width/3 - predefinedButtons.columnSpacing*7
                Layout.preferredHeight: UM.Theme.getSize("section").height

                onClicked:
                {
                    connectedPrinter.setTargetHotendTemperature(Cura.MonitorStageStorage.extruderNumber, 0)
                }
                style:  UM.Theme.styles.print_monitor_control_button

            }

            Button
            {
                text: "Preheat bed"
                //width: parent.width/3
                Layout.row: 2
                Layout.column: 1
                Layout.preferredWidth: parent.width/3 - predefinedButtons.columnSpacing*7
                Layout.preferredHeight: UM.Theme.getSize("section").height

                onClicked:
                {
                    connectedPrinter.preheatBed()
                }
                style:  UM.Theme.styles.print_monitor_control_button

            }

            Button
            {
                text: "Cool bed"
                Layout.row: 2
                Layout.column: 2
                Layout.preferredWidth: parent.width/3 - predefinedButtons.columnSpacing*7
                Layout.preferredHeight: UM.Theme.getSize("section").height

                onClicked:
                {
                    connectedPrinter.setTargetBedTemperature(0)
                }
                style:  UM.Theme.styles.print_monitor_control_button

            }

            Button
            {
                text: "Cold pull"
                Layout.row: 2
                Layout.column: 3
                Layout.preferredWidth: parent.width/3 - predefinedButtons.columnSpacing*7
                Layout.preferredHeight: UM.Theme.getSize("section").height
                enabled:
                {
                     var name = Cura.MachineManager.activeMachineName
                     if(name.includes("Aerostruder"))
                    {
                         return connectedPrinter && false;
                    }
                    else
                    {
                        return connectedPrinter && true
                    }
                }

                onClicked:
                {
                    connectedPrinter.coldPull(Cura.MonitorStageStorage.extruderNumber)
                }
                style:  UM.Theme.styles.print_monitor_control_button

            }

            Button
            {
                text: "Motors off"
                Layout.row: 3
                Layout.column: 2
                Layout.preferredWidth: parent.width/3 - predefinedButtons.columnSpacing*7
                Layout.preferredHeight: UM.Theme.getSize("section").height

                onClicked:
                {
                    Cura.USBPrinterManager.sendCommandToCurrentPrinter("M18")
                }
                style:  UM.Theme.styles.print_monitor_control_button

            }

            Button
            {
                text: "Level X Axis"
                Layout.row: 3
                Layout.column: 3
                Layout.preferredWidth: parent.width/3 - predefinedButtons.columnSpacing*7
                Layout.preferredHeight: UM.Theme.getSize("section").height

                enabled: connectedPrinter && connectedPrinter.supportLevelXAxis

                onClicked:
                {
                    connectedPrinter.levelXAxis()
                }
                style:  UM.Theme.styles.print_monitor_control_button

            }

        }
}
