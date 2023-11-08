// Copyright (c) 2018 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4

import UM 1.2 as UM
import Cura 1.0 as Cura

Item {
    id: recommendedPrintSetup

    property Action configureSettings

    property bool settingsEnabled: Cura.ExtruderManager.activeExtruderStackId || extrudersEnabledCount.properties.value == 1
    property real padding: UM.Theme.getSize("default_margin").width

    Column {

        anchors
        {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: parent.padding
        }

        RecommendedQualityProfileSelector {
            id: profileSelector
            width: parent.width
        }

        Rectangle {
            id: settingsArea

            width: parent.width
            height: recommendedPrintSetup.height - (profileSelector.height + (UM.Theme.getSize("thick_margin").height * 2))
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
    }

    UM.SettingPropertyProvider {
        id: extrudersEnabledCount
        containerStack: Cura.MachineManager.activeMachine
        key: "extruders_enabled_count"
        watchedProperties: [ "value" ]
        storeIndex: 0
    }
}
