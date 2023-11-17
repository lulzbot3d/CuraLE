import QtQuick 2.2

import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1

import UM 1.2 as UM
import Cura 1.0 as Cura


Item {
    implicitWidth: parent.width
    implicitHeight: Math.floor(childrenRect.height + UM.Theme.getSize("default_margin").height * 2)
    property var outputDeviceCount: Cura.MachineManager.printerOutputDevices.length
    property var outputDevice: null
    property var activeDevice: null
    property var connectionState: outputDevice == null ? null : outputDevice.connectionState

    Connections
    {
        target: Cura.MachineManager
        function onGlobalContainerChanged()
        {
            outputDevice = outputDeviceCount >= 1 ? Cura.MachineManager.printerOutputDevices[outputDeviceCount - 1] : null;
        }
    }

    Rectangle {
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
            text:
            {
                if(outputDevice != null && outputDevice.address != "None")
                {
                    if(activeDevice != null)
                    {
                        switch(connectionState)
                        {
                            case 2:
                                outputDevice.activePrinter.name
                                break;
                            default:
                                "No USB Printer Connected"
                                break;
                        }
                    }
                    else{ "Unexpected Device State" }
                }
                else { "No USB Printers Connected" }
            }
        }

        Label {
            id: outputDeviceAddressLabel
            text:
            {
                if(outputDevice != null && outputDevice.address != null)
                {
                    if(outputDevice.address == "None")
                    {
                        "No USB Devices Available"
                    }
                    else
                    {
                        switch(connectionState)
                        {
                            case 0:
                                "USB Devices Available!"
                                break;
                            case 1:
                                "Connecting..."
                                break;
                            case 2:
                                "Connected On Port: " + outputDevice.address
                                break;
                            case 3:
                                "Device At " + outputDevice.address + " Busy"
                                break;
                            case 4:
                                "Error From Device At " + outputDevice.address
                                break;
                            case 6:
                                "Connection Timeout!"
                                break;
                            default:
                                "Unknown Connection State"
                                break;
                        }
                    }
                }
                else { "No Output Device Address" }
            }
            font: UM.Theme.getFont("default_bold")
            color: UM.Theme.getColor("text_medium")
            anchors.top: outputDeviceNameLabel.bottom
            anchors.left: parent.left
            anchors.margins: UM.Theme.getSize("default_margin").width
        }

    }
}