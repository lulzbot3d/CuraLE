// Copyright (c) 2018 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

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

    Rectangle
    {

        id: noPrinterConnected

        color: UM.Theme.getColor("main_background")

        anchors.right: parent.right
        width: parent.width * 0.3
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        visible: !monitorViewComponent.active

        Cura.PrintMonitor
        {
            id: noConnectionPrintMonitor
            anchors.fill: parent
        }

        Rectangle
        {
            id: noConnectionFooterSeparator
            width: parent.width
            height: UM.Theme.getSize("wide_lining").height
            color: UM.Theme.getColor("wide_lining")
            anchors.bottom: noConnectionMonitorButton.top
            anchors.bottomMargin: UM.Theme.getSize("thick_margin").height
        }

        // MonitorButton is actually the bottom footer panel.
        Cura.MonitorButton
        {
            id: noConnectionMonitorButton
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
        }
    }

    Loader
    {
        id: monitorViewComponent

        anchors.fill: parent

        height: parent.height

        property real maximumWidth: parent.width
        property real maximumHeight: parent.height

        active: Cura.MachineManager.printerOutputDevices.length > 0

        sourceComponent: Cura.MachineManager.printerOutputDevices.length > 0 ? Cura.MachineManager.printerOutputDevices[0].monitorItem : null
    }
}
