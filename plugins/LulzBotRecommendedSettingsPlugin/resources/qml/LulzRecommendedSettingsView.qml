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

    Flickable
    {
        id: recommendedPrintSetup
        clip: true

        contentHeight: settingsColumn.height
        implicitHeight: settingsColumn.height

        property bool settingsEnabled: Cura.ExtruderManager.activeExtruderStackId || extrudersEnabledCount.properties.value == 1

        function onModeChanged() {}

        ScrollBar.vertical: UM.ScrollBar {
            id: scroll
            anchors
            {
                top: parent.top
                right: parent.right
                bottom: parent.bottom
            }
        }

        boundsBehavior: Flickable.StopAtBounds

        Column
        {

            id: settingsColumn
            spacing: UM.Theme.getSize("thick_margin").height

            width: settingsArea.width - 35
            height: childrenRect.height + 10

            // Makes it easier to adjust the overall size of the columns.
            // We want the labels to take up just under half of the available space.
            property real firstColumnWidth: Math.round(width * (11/24))

            RecommendedStrengthSection
            {
                width: parent.width
                labelColumnWidth: settingsColumn.firstColumnWidth
            }

            // RecommendedSupportSection
            // {
            //     width: parent.width
            //     // TODO Create a reusable component with these properties to not define them separately for each component
            //     labelColumnWidth: settingsColumn.firstColumnWidth
            // }

            // RecommendedAdhesionSelector
            // {
            //     width: parent.width
            //     // TODO Create a reusable component with these properties to not define them separately for each component
            //     labelColumnWidth: settingsColumn.firstColumnWidth
            // }

            // RecommendedZSeamSelector
            // {
            //     width: parent.width
            //     labelColumnWidth: settingsColumn.firstColumnWidth
            // }

            RecommendedPrintSequenceSelector
            {
                width: parent.width
                labelColumnWidth: settingsColumn.firstColumnWidth
            }

            RecommendedVaseModeSelector
            {
                width: parent.width
                labelColumnWidth: settingsColumn.firstColumnWidth
            }
        }


        UM.SettingPropertyProvider
        {
            id: extrudersEnabledCount
            containerStack: Cura.MachineManager.activeMachine
            key: "extruders_enabled_count"
            watchedProperties: [ "value" ]
            storeIndex: 0
        }
    }
}
