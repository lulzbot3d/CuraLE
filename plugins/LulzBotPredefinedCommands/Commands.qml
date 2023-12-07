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

        if (canSendCommand == false)
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
            id: coolNozzleButton
            text: "Cool Nozzles"
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
                for (var i = 0; i < printerModel.extruders.length; i++) {
                    var extruder = printerModel.extruders[i];
                    if (extruder.isPreheating) {
                        extruder.cancelPreheatHotend()
                    }
                    extruder.setTargetHotendTemperature(0.0)
                }
            }

            onHoveredChanged:
            {
                if (hovered)
                {
                    base.showTooltip(
                        base,
                        {x: -200, y: coolNozzleButton.mapToItem(base, 0, -10).y},
                        catalog.i18nc("@tooltip of cool nozzles", "Sets nozzle temperatures to 0 for all nozzles, can be used in case of UI error as a safety measure.")
                    );
                }
                else
                {
                    base.hideTooltip();
                }
            }
            style:  UM.Theme.styles.monitor_checkable_button_style
        }

        Button {
            id: coolBedButton
            text: "Cool Bed"
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
                if (printerModel.isPreheating){
                    printerModel.cancelPreheatBed()
                }
                printerModel.setTargetBedTemperature(0.0)
            }

            onHoveredChanged:
            {
                if (hovered)
                {
                    base.showTooltip(
                        base,
                        {x: -200, y: coolBedButton.mapToItem(base, 0, -10).y},
                        catalog.i18nc("@tooltip of cool bed", "Sets bed temperature to 0, can be used in case of UI error as a safety measure.")
                    );
                }
                else
                {
                    base.hideTooltip();
                }
            }
            style:  UM.Theme.styles.monitor_checkable_button_style
        }

        Button {
            id: coldPullButton
            text: "Cold Pull"
            Layout.row: 1
            Layout.column: 0
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: width
            Layout.preferredHeight: height
            width: (base.width / 2) - (UM.Theme.getSize("default_margin").width * (3 / 2))
            height: UM.Theme.getSize("setting_control").height * 1.5
            enabled: checkEnabled()

            onClicked: {
                for (var i = 0; i < printerModel.extruders.length; i++) {
                    var extruder = printerModel.extruders[i];
                    if (extruder.isPreheating) {
                        extruder.cancelPreheatHotend()
                    }
                    extruder.setTargetHotendTemperature(145.0)
                }
            }

            onHoveredChanged: {
                if (hovered) {
                    base.showTooltip(
                        base,
                        {x: -200, y: coldPullButton.mapToItem(base, 0, -10).y},
                        catalog.i18nc("@tooltip of cold pull", "Heats your hot end temperature(s) to 145. Once at temperature, \
                        manually remove filament from Tool Head to help remove residue inside the nozzle.")
                    );
                } else {
                    base.hideTooltip();
                }
            }
            style:  UM.Theme.styles.monitor_checkable_button_style
        }

        Button {
            id: disableSteppersButton
            text: "Disable Steppers"
            Layout.row: 1
            Layout.column: 1
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: width
            Layout.preferredHeight: height
            width: (base.width / 2) - (UM.Theme.getSize("default_margin").width * (3 / 2))
            height: UM.Theme.getSize("setting_control").height * 1.5
            enabled: checkEnabled()

            onClicked: {
                printerModel.sendRawCommand("M18")
            }

            onHoveredChanged: {
                if (hovered) {
                    base.showTooltip(
                        base,
                        {x: -200, y: disableSteppersButton.mapToItem(base, 0, -10).y},
                        catalog.i18nc("@tooltip of disable steppers", "Disables the stepper motors on your printer until another command is sent " +
                                        "requiring the motors. This is useful if you need to move the bed or Tool Head assembly manually. Take care " +
                                        "if the printer is still hot.")
                    );
                } else {
                    base.hideTooltip();
                }
            }
            style:  UM.Theme.styles.monitor_checkable_button_style
        }

        Button {
            id: levelXButton
            text: "Level X Axis"
            Layout.row: 2
            Layout.column: 0
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: width
            Layout.preferredHeight: height
            width: (base.width / 2) - (UM.Theme.getSize("default_margin").width * (3 / 2))
            height: UM.Theme.getSize("setting_control").height * 1.5
            enabled: checkEnabled() && connectedPrinter.supportLevelXAxis

            onClicked: {
                connectedPrinter.levelXAxis()
            }

            onHoveredChanged: {
                if (hovered) {
                    base.showTooltip(
                        base,
                        {x: -200, y: levelXButton.mapToItem(base, 0, -10).y},
                        catalog.i18nc("@tooltip of level x axis", "Levels the X Axis of the printer on certain printers with belt-driven " +
                                        "Z-axes. Runs a provided leveling G-Code file specific to each supported printer.")
                    );
                } else {
                    base.hideTooltip();
                }
            }
            style:  UM.Theme.styles.monitor_checkable_button_style
        }

        Button {
            id: wipeNozzleButton
            text: "Wipe Nozzle"
            Layout.row: 2
            Layout.column: 1
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: width
            Layout.preferredHeight: height
            width: (base.width / 2) - (UM.Theme.getSize("default_margin").width * (3 / 2))
            height: UM.Theme.getSize("setting_control").height * 1.5

            enabled: checkEnabled() && connectedPrinter.supportWipeNozzle

            onClicked: {
                connectedPrinter.wipeNozzle()
            }

            onHoveredChanged: {
                if (hovered) {
                    base.showTooltip(
                        base,
                        {x: -200, y: wipeNozzleButton.mapToItem(base, 0, -10).y},
                        catalog.i18nc("@tooltip of wipe nozzle", "Cleans Tool Head nozzles by wiping heated nozzles on the wiper pads of supported printers. " +
                                        "Runs a wipe G-Code file provided for each supported printer.")
                    );
                } else {
                    base.hideTooltip();
                }
            }
            style: UM.Theme.styles.monitor_checkable_button_style
        }

        Button {
            id: toolHeadSwapButton
            text: "Tool Head and Filament Changing Position"
            Layout.row: 3
            Layout.column: 0
            Layout.columnSpan: 2
            Layout.preferredWidth: width
            Layout.preferredHeight: height
            width: base.width - (UM.Theme.getSize("default_margin").width * 2)
            height: UM.Theme.getSize("setting_control").height * 1.5
            enabled: checkEnabled()

            onClicked: {
                printerModel.sendRawCommand("G28 O\nG27")
            }

            onHoveredChanged: {
                if (hovered) {
                    base.showTooltip(
                        base,
                        {x: -200, y: toolHeadSwapButton.mapToItem(base, 0, -10).y},
                        catalog.i18nc("@tooltip of tool head swap", "Moves the Tool Head to the park position, which works best for changing out filament " +
                                        "or the Tool Head itself.")
                    );
                }
                else {
                    base.hideTooltip();
                }
            }
            style: UM.Theme.styles.monitor_checkable_button_style
        }

    }
}
