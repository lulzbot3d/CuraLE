// Copyright (c) 2023 Aldo Hoeben / fieldOfView
// SidebarGUIPlugin is released under the terms of the AGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 2.3

import UM 1.3 as UM
import Cura 1.1 as Cura

Item
{
    id: stageMenu

    signal showTooltip(Item item, point location, string text)
    signal hideTooltip()

    Component.onCompleted:
    {
        // adjust message stack position for sidebar
        var messageStack
        messageStack = base.contentItem.children[4].children[3].children[8]
        messageStack.anchors.horizontalCenter = undefined
        messageStack.anchors.left = messageStack.parent.left
        messageStack.anchors.leftMargin = Qt.binding(function()
        {
            return Math.floor((base.width - printSetupSelector.width) / 2)
        })

        // adjust stages menu position for sidebar
        var stagesListContainer = mainWindowHeader.children[1]
        stagesListContainer.anchors.horizontalCenter = undefined
        stagesListContainer.anchors.left = stagesListContainer.parent.left
        stagesListContainer.anchors.leftMargin = Qt.binding(function()
        {
            return Math.floor((base.width - printSetupSelector.width - stagesListContainer.width) / 2)
        })

        // hide application logo if there is no room for it
        var applicationLogo = mainWindowHeader.children[0]
        applicationLogo.visible = Qt.binding(function()
        {
            return stagesListContainer.anchors.leftMargin > applicationLogo.width + 2 * UM.Theme.getSize("default_margin").width
        })
    }

    Loader
    {
        anchors.right: parent.right
        anchors.rightMargin: UM.Theme.getSize("print_setup_widget").width - width
        width: UM.Theme.getSize("machine_selector_widget").width
        height: Math.round(0.5 * UM.Theme.getSize("main_window_header").height)
        y: - Math.floor((UM.Theme.getSize("main_window_header").height + height) / 2)

        source: "MachineSelector53.qml";
    }
}