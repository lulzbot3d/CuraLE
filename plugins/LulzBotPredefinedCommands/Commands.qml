import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1

import UM 1.3 as UM
import Cura 1.0 as Cura

Item {
    property int deviceCount: Cura.MachineManager.printerOutputDevices.length
    property var connectedPrinter: deviceCount >= 1 ? Cura.MachineManager.printerOutputDevices[deviceCount - 1] : null
    property bool canSendCommand: connectedPrinter.acceptsCommands
    width: base.width
    height: 130
    enabled: canSendCommand

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
        columns: 3
        rows: 3
        rowSpacing: UM.Theme.getSize("default_margin").width
        columnSpacing: UM.Theme.getSize("default_margin").width / 2
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: sectionHeader.bottom
        anchors.horizontalCenter: parent
        anchors.topMargin: UM.Theme.getSize("default_margin").width
        anchors.leftMargin: UM.Theme.getSize("default_margin").width
        anchors.rightMargin: UM.Theme.getSize("default_margin").width

        Button {
            text: "Preheat nozzle"
            Layout.row: 0
            Layout.column: 0
            Layout.preferredWidth: width
            Layout.preferredHeight: height
            width: (base.width / 3) - (UM.Theme.getSize("default_margin").width * (4 / 3))
            height: UM.Theme.getSize("setting_control").height * 1.5

            onClicked:
            {
                connectedPrinter.preheatHotend(Cura.MonitorStageStorage.extruderNumber)
            }
            style: UM.Theme.styles.monitor_checkable_button_style
        }

        Button {
            text: "Wipe Nozzle"
            Layout.row: 0
            Layout.column: 1
            Layout.preferredWidth: width
            Layout.preferredHeight: height
            width: (base.width / 3) - (UM.Theme.getSize("default_margin").width * (4 / 3))
            height: UM.Theme.getSize("setting_control").height * 1.5

            enabled: canSendCommand && connectedPrinter.supportWipeNozzle

            onClicked:
            {
                connectedPrinter.wipeNozzle()
            }
            style: UM.Theme.styles.monitor_checkable_button_style

        }

        Button {
            text: "Cool Nozzle"
            Layout.row: 0
            Layout.column: 2
            Layout.preferredWidth: width
            Layout.preferredHeight: height
            width: (base.width / 3) - (UM.Theme.getSize("default_margin").width * (4 / 3))
            height: UM.Theme.getSize("setting_control").height * 1.5

            onClicked:
            {
                connectedPrinter.setTargetHotendTemperature(Cura.MonitorStageStorage.extruderNumber, 0)
            }
            style:  UM.Theme.styles.monitor_checkable_button_style

        }

        Button {
            text: "Preheat Bed"
            Layout.row: 1
            Layout.column: 0
            Layout.preferredWidth: width
            Layout.preferredHeight: height
            width: (base.width / 3) - (UM.Theme.getSize("default_margin").width * (4 / 3))
            height: UM.Theme.getSize("setting_control").height * 1.5

            onClicked:
            {
                connectedPrinter.preheatBed()
            }
            style:  UM.Theme.styles.monitor_checkable_button_style

        }

        Button {
            text: "Cool bed"
            Layout.row: 1
            Layout.column: 1
            Layout.preferredWidth: width
            Layout.preferredHeight: height
            width: (base.width / 3) - (UM.Theme.getSize("default_margin").width * (4 / 3))
            height: UM.Theme.getSize("setting_control").height * 1.5

            onClicked:
            {
                connectedPrinter.setTargetBedTemperature(0)
            }
            style:  UM.Theme.styles.monitor_checkable_button_style
        }

        Button {
            text: "Cold pull"
            Layout.row: 1
            Layout.column: 2
            Layout.preferredWidth: width
            Layout.preferredHeight: height
            width: (base.width / 3) - (UM.Theme.getSize("default_margin").width * (4 / 3))
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
            Layout.row: 2
            Layout.column: 0
            Layout.preferredWidth: width
            Layout.preferredHeight: height
            width: (base.width / 3) - (UM.Theme.getSize("default_margin").width * (4 / 3))
            height: UM.Theme.getSize("setting_control").height * 1.5

            onClicked:
            {
                Cura.USBPrinterManager.sendCommandToCurrentPrinter("M18")
            }
            style:  UM.Theme.styles.monitor_checkable_button_style

        }

        Button {
            text: "Level X Axis"
            Layout.row: 2
            Layout.column: 1
            Layout.preferredWidth: width
            Layout.preferredHeight: height
            width: (base.width / 3) - (UM.Theme.getSize("default_margin").width * (4 / 3))
            height: UM.Theme.getSize("setting_control").height * 1.5
            enabled: canSendCommand && connectedPrinter.supportLevelXAxis

            onClicked:
            {
                connectedPrinter.levelXAxis()
            }
            style:  UM.Theme.styles.monitor_checkable_button_style
        }

    }
}
