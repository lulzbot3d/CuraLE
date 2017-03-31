import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1

import UM 1.2 as UM
import Cura 1.0 as Cura

Item
{
    property var connectedPrinter: printerConnected ? Cura.MachineManager.printerOutputDevices[0] : null
    height: childrenRect.height + UM.Theme.getSize("default_margin").width * 2
    enabled: connectedPrinter

    Column
    {
        width: 100
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: UM.Theme.getSize("default_margin").width
        spacing: UM.Theme.getSize("button_spacing").height

        Button
        {
            text: "Wipe nozzle"
            width: parent.width

            onClicked:
            {
                connectedPrinter.wipeNozzle()
            }
            style: UM.Theme.styles.print_monitor_control_button
        }

        Button
        {
            text: "Preheat nozzle"
            width: parent.width

            onClicked:
            {
                connectedPrinter.preheatHotend(-1)
            }
            style: UM.Theme.styles.print_monitor_control_button
        }

        Button
        {
            text: "Preheat bed"
            width: parent.width

            onClicked:
            {
                connectedPrinter.preheatBed()
            }
            style: UM.Theme.styles.print_monitor_control_button
        }

        Button
        {
            text: "Motors off"
            width: parent.width

            onClicked:
            {
                Cura.USBPrinterManager.sendCommandToCurrentPrinter("M18")
            }
            style: UM.Theme.styles.print_monitor_control_button
        }

        Button
        {
            text: "Cool nozzle"
            width: parent.width

            onClicked:
            {
                connectedPrinter.setTargetHotendTemperature(-1, 0)
            }
            style: UM.Theme.styles.print_monitor_control_button
        }

        Button
        {
            text: "Cool bed"
            width: parent.width

            onClicked:
            {
                connectedPrinter.setTargetBedTemperature(0)
            }
            style: UM.Theme.styles.print_monitor_control_button
        }

        Button
        {
            text: "Cold pull"
            width: parent.width

            onClicked:
            {
                connectedPrinter.coldPull(-1)
            }
            style: UM.Theme.styles.print_monitor_control_button
        }
    }
}
