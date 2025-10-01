// Copyright (c) 2023 Aldo Hoeben / fieldOfView
// TabbedSettingsPlugin is released under the terms of the AGPLv3 or higher.

import QtQuick 2.15
import QtQuick.Controls 2.4

import UM 1.5 as UM
import Cura 1.0 as Cura


Flickable {
    id: recommendedPrintSetup
    clip: true

    anchors.fill: parent
    anchors.margins: UM.Theme.getSize("default_lining").width

    contentHeight: settingsColumn.height
    implicitHeight: settingsColumn.height

    property var tooltipItem
    property var backgroundItem
    property bool settingsEnabled: Cura.ExtruderManager.activeExtruderStackId || extrudersEnabledCount.properties.value == 1

    UM.I18nCatalog { id: catalog; name: "cura"; }

    function onModeChanged() {}

    Item {
        id: profileSelectorRow
        height: childrenRect.height
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: UM.Theme.getSize("default_margin").width
        anchors.rightMargin: UM.Theme.getSize("default_margin").width
    }

    ScrollBar.vertical: UM.ScrollBar {
        id: scroll
        anchors {
            top: parent.top
            right: parent.right
            bottom: parent.bottom
        }
    }

    boundsBehavior: Flickable.StopAtBounds

    Column {

        id: settingsColumn
        padding: UM.Theme.getSize("default_margin").width
        spacing: UM.Theme.getSize("default_margin").height

        width: recommendedPrintSetup.width - 2 * padding - UM.Theme.getSize("thin_margin").width

        // Makes it easier to adjust the overall size of the columns.
        // We want the labels to take up just under half of the available space.
        property real firstColumnWidth: Math.round(width * (11/24))

        RecommendedStrengthSection {

            width: parent.width
            labelColumnWidth: settingsColumn.firstColumnWidth
        }

        RecommendedSupportSection {

            width: parent.width
            // TODO Create a reusable component with these properties to not define them separately for each component
            labelColumnWidth: settingsColumn.firstColumnWidth
        }

        RecommendedAdhesionSelector {

            width: parent.width
            // TODO Create a reusable component with these properties to not define them separately for each component
            labelColumnWidth: settingsColumn.firstColumnWidth
        }

        RecommendedZSeamSelector {

            width: parent.width
            //labelColumnWidth: settingsColumn.firstColumnWidth
        }

    }


    UM.SettingPropertyProvider {
        id: extrudersEnabledCount
        containerStack: Cura.MachineManager.activeMachine
        key: "extruders_enabled_count"
        watchedProperties: [ "value" ]
        storeIndex: 0
    }

    function showTooltip(item, position, text) {
        tooltipItem.text = text
        var position = item.mapToItem(backgroundItem, position.x - UM.Theme.getSize("default_arrow").width, position.y)
        tooltipItem.show(position)

        // hide the main tooltip if the sidebar gui is enabled and the sidebar is undocked
        var sidebargui_docked = false
        if(withSidebarGUI) {
            sidebargui_docked = UM.Preferences.getValue("sidebargui/docked_sidebar")
        }
        if(sidebargui_docked === false) {
            tooltipItem.visible = false
        }
        else if(sidebargui_docked === true) {
            tooltipItem.visible = true
        }
    }

    function hideTooltip() {
        tooltipItem.hide();
    }

    Connections {
        target: tooltipItem != undefined ? tooltipItem : null
        function onOpacityChanged() {
            // ensure invisible tooltips don't cover the tabs
            if(tooltipItem.opacity == 0) {
                tooltipItem.text = ""
            }
        }
    }
}

