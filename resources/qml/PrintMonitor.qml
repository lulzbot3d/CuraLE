// Copyright (c) 2019 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15

import UM 1.5 as UM
import Cura 1.0 as Cura

import "PrinterOutput"

ScrollView
{
    id: base
    width: parent.width
    height: parent.height

    contentHeight: printMonitor.height

    ScrollBar.vertical: UM.ScrollBar
    {
        id: scrollbar
        parent: base.parent
        anchors
        {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }
    }
    clip: true

    contentHeight: printMonitor.height

    ScrollBar.vertical: UM.ScrollBar
    {
        id: scrollbar
        parent: base.parent
        anchors
        {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }
    }
    clip: true

    function showTooltip(item, position, text) {
        tooltip.text = text;
        position = item.mapToItem(base, position.x - UM.Theme.getSize("default_arrow").width, position.y);
        tooltip.show(position);
    }

    function hideTooltip() {
        tooltip.hide();
    }

    function strPadLeft(string, pad, length) {
        return (new Array(length + 1).join(pad) + string).slice(-length);
    }

    function getPrettyTime(time) {
        var hours = Math.floor(time / 3600)
        time -= hours * 3600
        var minutes = Math.floor(time / 60);
        time -= minutes * 60
        var seconds = Math.floor(time);

        var finalTime = strPadLeft(hours, "0", 2) + ":" + strPadLeft(minutes, "0", 2) + ":" + strPadLeft(seconds, "0", 2);
        return finalTime;
    }

    property var outputDeviceCount: Cura.MachineManager.printerOutputDevices.length
    property var connectedDevice: outputDeviceCount >= 1 ? Cura.MachineManager.printerOutputDevices[outputDeviceCount - 1] : null
    property var activePrinter: connectedDevice != null && connectedDevice.address != "None" ? connectedDevice.activePrinter : null
    property var activePrintJob: activePrinter != null ? activePrinter.activePrintJob: null

    ScrollView {

        UM.I18nCatalog { id: catalog; name: "cura" }

        width: parent.width - scrollbar.width

        Column {
            id: printMonitor
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            OutputDeviceHeader {
                outputDevice: connectedDevice
                activeDevice: activePrinter
            }

            Rectangle {
                color: UM.Theme.getColor("wide_lining")
                width: base.width
                height: childrenRect.height

                Flow {
                    id: extrudersGrid
                    spacing: UM.Theme.getSize("thick_lining").width
                    width: parent.width

                    Repeater {
                        id: extrudersRepeater
                        model: connectedDevice != null ? connectedDevice.activePrinter.extruders : null

                        ExtruderBox {
                            color: UM.Theme.getColor("main_background")
                            width: index == machineExtruderCount.properties.value - 1 && index % 2 == 0 ? extrudersGrid.width : Math.round(extrudersGrid.width / 2 - UM.Theme.getSize("thick_lining").width / 2)
                            extruderModel: modelData
                        }
                    }
                }
            }

            Rectangle {
                color: UM.Theme.getColor("wide_lining")
                width: base.width
                height: UM.Theme.getSize("thick_lining").width
            }

        UM.SettingPropertyProvider
        {
            id: bedTemperature
            containerStack: Cura.MachineManager.activeMachine
            key: "material_bed_temperature_layer_0"
            watchedProperties: ["value", "minimum_value", "maximum_value", "resolve"]
            storeIndex: 0
        }

        UM.SettingPropertyProvider
        {
            id: machineExtruderCount
            containerStack: Cura.MachineManager.activeMachine
            key: "machine_extruder_count"
            watchedProperties: ["value"]
        }

        ManualPrinterControl
        {
            printerModel: activePrinter
            visible: activePrinter != null ? activePrinter.canControlManually : false
        }


        MonitorSection
        {
            label: catalog.i18nc("@label", "Active print")
            width: base.width
            visible: activePrinter != null
        }


        MonitorItem
        {
            label: catalog.i18nc("@label", "Job Name")
            value: activePrintJob != null ? activePrintJob.name : ""
            width: base.width
            visible: activePrinter != null
        }

        MonitorItem
        {
            label: catalog.i18nc("@label", "Printing Time")
            value: activePrintJob != null ? getPrettyTime(activePrintJob.timeTotal) : ""
            width: base.width
            visible: activePrinter != null
        }

        MonitorItem
        {
            label: catalog.i18nc("@label", "Estimated time left")
            value: activePrintJob != null ? getPrettyTime(activePrintJob.timeTotal - activePrintJob.timeElapsed) : ""
            visible:
            {
                if(activePrintJob == null)
                {
                    return false
                }

                return (activePrintJob.state == "printing" ||
                        activePrintJob.state == "resuming" ||
                        activePrintJob.state == "pausing" ||
                        activePrintJob.state == "paused")
            }
        }
    }

    PrintSetupTooltip {
        id: tooltip
    }
}
