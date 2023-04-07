import QtQuick 2.2

import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1

import UM 1.2 as UM
import Cura 1.0 as Cura


Item
{
    implicitWidth: parent.width
    implicitHeight: Math.floor(childrenRect.height + UM.Theme.getSize("default_margin").height * 2)
    property var outputDevice: null
    property var outputDeviceCount: Cura.MachineManager.printerOutputDevices.length

    Connections
    {
        target: Cura.MachineManager
        function onGlobalContainerChanged()
        {
            outputDevice = outputDeviceCount >= 1 ? Cura.MachineManager.printerOutputDevices[outputDeviceCount - 1] : null;
        }
    }

    Rectangle
    {
        height: childrenRect.height
        color: UM.Theme.getColor("setting_category")

        Label
        {
            id: outputDeviceNameLabel
            font: UM.Theme.getFont("large_bold")
            color: UM.Theme.getColor("text")
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: UM.Theme.getSize("default_margin").width
            text: outputDevice != null && outputDevice.address != "None" ? outputDevice.activePrinter.name : ""
        }

        Label
        {
            id: outputDeviceAddressLabel
            text:
            {
                if(outputDevice != null && outputDevice.address != null)
                {
                    if(outputDevice.address == "None")
                    {
                        "No USB Devices Available" // Change this to check if there are any valid serial ports
                    }
                    else { outputDevice.address }
                }
                else { "No Output Device Address" }
            }
            font: UM.Theme.getFont("default_bold")
            color: UM.Theme.getColor("text_inactive")
            anchors.top: outputDeviceNameLabel.bottom
            anchors.left: parent.left
            anchors.margins: UM.Theme.getSize("default_margin").width
        }

        Label
        {
            id: printerNotConnectedLabel
            text: outputDevice != null && outputDevice.address != "None" ? "" : catalog.i18nc("@info:status", "No printers are connected.")
            color: outputDevice != null && outputDevice.acceptsCommands ? UM.Theme.getColor("setting_control_text") : UM.Theme.getColor("setting_control_disabled_text")
            font: UM.Theme.getFont("large_bold")
            wrapMode: Text.WordWrap
            anchors.left: parent.left
            anchors.leftMargin: UM.Theme.getSize("default_margin").width
            anchors.right: parent.right
            anchors.rightMargin: UM.Theme.getSize("default_margin").width
            anchors.top: parent.top
            anchors.topMargin: UM.Theme.getSize("default_margin").height
        }
    }
}