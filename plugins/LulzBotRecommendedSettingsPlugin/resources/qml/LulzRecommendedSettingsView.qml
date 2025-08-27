// Copyright (c) 2023 Aldo Hoeben / fieldOfView
// TabbedSettingsPlugin is released under the terms of the AGPLv3 or higher.

import QtQuick 2.15
import QtQuick.Controls 2.4

import UM 1.5 as UM
import Cura 1.0 as Cura

Item
{
    id: settingsView

    property var tooltipItem
    property var backgroundItem

    anchors.fill: parent
    anchors.margins: UM.Theme.getSize("default_lining").width

    UM.I18nCatalog { id: catalog; name: "cura"; }

    Item
    {
        id: profileSelectorRow
        height: childrenRect.height
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: UM.Theme.getSize("default_margin").width
        anchors.rightMargin: UM.Theme.getSize("default_margin").width
    }

}
