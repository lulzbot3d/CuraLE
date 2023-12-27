// Copyright (c) 2023 UltiMaker
//Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.1

import UM 1.6 as UM
import Cura 1.6 as Cura
import ".."

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
        padding: UM.Theme.getSize("default_margin").width
        spacing: UM.Theme.getSize("default_margin").height

        width: recommendedPrintSetup.width - 2 * padding - UM.Theme.getSize("thin_margin").width

        // TODO
        property real firstColumnWidth: Math.round(width / 3)

        UM.Label
        {
            text: catalog.i18nc("@label", "Profiles")
            font: UM.Theme.getFont("medium")
        }

        RecommendedQualityProfileSelector
        {
            width: parent.width
            hasQualityOptions: recommendedResolutionSelector.visible
        }

        RecommendedResolutionSelector
        {
            id: recommendedResolutionSelector
            width: parent.width
        }

        UnsupportedProfileIndication
        {
            width: parent.width
            visible: !recommendedResolutionSelector.visible
        }

        Item { height: UM.Theme.getSize("default_margin").height } // Spacer

        ProfileWarningReset
        {
            width: parent.width
        }

        Item { height: UM.Theme.getSize("thin_margin").height  + UM.Theme.getSize("narrow_margin").height} // Spacer

        //Line between the sections.
        Rectangle
        {
            width: parent.width
            height: UM.Theme.getSize("default_lining").height
            color: UM.Theme.getColor("lining")
        }

        Item { height: UM.Theme.getSize("narrow_margin").height } //Spacer

        Column
        {
            id: settingColumn
            width: parent.width
            spacing: UM.Theme.getSize("thin_margin").height

            Item
            {
                id: recommendedPrintSettingsHeader
                height: childrenRect.height
                width: parent.width
                UM.Label
                {
                    anchors.left: parent.left
                    text: catalog.i18nc("@label", "Recommended print settings")
                    font: UM.Theme.getFont("medium")
                }

                Cura.SecondaryButton
                {
                    id: customSettingsButton
                    anchors.right: parent.right
                    text: catalog.i18nc("@button", "Show Custom")
                    textFont: UM.Theme.getFont("medium_bold")
                    onClicked: onModeChanged()
                }
            }

            RecommendedStrengthSelector
            {
                width: parent.width
            }

            RecommendedSupportSelector
            {
                width: parent.width
            }

            RecommendedAdhesionSelector
            {
                width: parent.width
            }
        }
    }

    Rectangle {
        id: settingsArea

        anchors {
            top: profileSelector.bottom
            topMargin: UM.Theme.getSize("default_margin").height
            left: parent.left
            leftMargin: parent.padding
            right: parent.right
            rightMargin: parent.padding
            bottom: parent.bottom
        }

        //width: parent.width
        //height: recommendedPrintSetup.height - (profileSelector.height + (UM.Theme.getSize("thick_margin").height))
        color: UM.Theme.getColor("action_button")

        // Mouse area that gathers the scroll events to not propagate it to the main view.
        MouseArea {
            anchors.fill: scrollView
            acceptedButtons: Qt.AllButtons
            onWheel: wheel.accepted = true
        }

        ScrollView {
            id: scrollView
            anchors {
                fill: parent
                topMargin: UM.Theme.getSize("default_margin").height
                leftMargin: UM.Theme.getSize("default_margin").width
                // Small space for the scrollbar
                rightMargin: UM.Theme.getSize("narrow_margin").width
                // Compensate for the negative margin in the parent
                bottomMargin: UM.Theme.getSize("default_lining").width
            }

            style: UM.Theme.styles.scrollview
            flickableItem.flickableDirection: Flickable.VerticalFlick

            Column {

                id: settingsColumn
                spacing: UM.Theme.getSize("thick_margin").height

                width: settingsArea.width - 35

                height: childrenRect.height + 10

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
                    labelColumnWidth: settingsColumn.firstColumnWidth
                }

                RecommendedPrintSequenceSelector {
                    width: parent.width
                    labelColumnWidth: settingsColumn.firstColumnWidth
                }
            }
        }
    }

    UM.SettingPropertyProvider {
        id: extrudersEnabledCount
        containerStack: Cura.MachineManager.activeMachine
        key: "extruders_enabled_count"
        watchedProperties: [ "value" ]
        storeIndex: 0
    }
}
