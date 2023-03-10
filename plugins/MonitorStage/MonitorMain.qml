// Copyright (c) 2018 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 2.0
import UM 1.3 as UM
import Cura 1.0 as Cura

// We show a nice overlay on the 3D viewer when the current output device has no monitor view
Rectangle
{
    id: viewportOverlay

    property bool isConnected: Cura.MachineManager.activeMachineHasNetworkConnection
    property bool isNetworkConfigurable:
    {
        if(Cura.MachineManager.activeMachine === null)
        {
            return false
        }
        return Cura.MachineManager.activeMachine.supportsNetworkConnection
    }

    property bool isNetworkConfigured: false

    color: UM.Theme.getColor("viewport_overlay")
    anchors.fill: parent

    UM.I18nCatalog
    {
        id: catalog
        name: "cura"
    }

    // This mouse area is to prevent mouse clicks to be passed onto the scene.
    MouseArea
    {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onWheel: wheel.accepted = true
    }

    // Disable dropping files into Cura when the monitor page is active
    DropArea
    {
        anchors.fill: parent
    }

    // Loader originally went here

    // // CASE 2: Empty states
    // Column
    // {
    //     anchors
    //     {
    //         top: parent.top
    //         topMargin: UM.Theme.getSize("monitor_empty_state_offset").height
    //         horizontalCenter: parent.horizontalCenter
    //     }
    //     width: UM.Theme.getSize("monitor_empty_state_size").width
    //     spacing: UM.Theme.getSize("default_margin").height
    //     visible: monitorViewComponent.sourceComponent == null

    //     // CASE 2: CAN MONITOR & NOT CONNECTED
    //     Label
    //     {
    //         id: noConnectionLabel
    //         anchors.horizontalCenter: parent.horizontalCenter
    //         visible: !isNetworkConfigurable
    //         text: catalog.i18nc("@info", "In order to monitor your print from Cura LE, please connect the printer.")
    //         font: UM.Theme.getFont("medium")
    //         color: UM.Theme.getColor("text")
    //         wrapMode: Text.WordWrap
    //         width: contentWidth
    //     }

    //     Button
    //     {
    //         id: connectButton
    //         anchors.horizontalCenter: parent.horizontalCenter
    //         visible: true
    //         text: catalog.i18nc("@info", "Connect!")
    //         enabled:
    //         {
    //             true
    //         }
    //         onClicked:
    //         {
    //             Cura.USBPrinterOutputDeviceManager.pushedConnectButton()
    //         }
    //     }
    // }

    // CASE 1: CAN MONITOR & CONNECTED
    Loader
    {
        id: monitorViewComponent

        anchors.fill: parent

        height: parent.height

        property real maximumWidth: parent.width
        property real maximumHeight: parent.height

        sourceComponent: Cura.MachineManager.printerOutputDevices.length > 0 ? Cura.MachineManager.printerOutputDevices[0].monitorItem : true
    }
}
