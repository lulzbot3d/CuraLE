// Copyright (c) 2020 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.3

import UM 1.2 as UM
import Cura 1.1 as Cura


// This element hold all the elements needed for the user to trigger the slicing process, and later
// to get information about the printing times, material consumption and the output process (such as
// saving to a file, printing over network, ...
Item {
    id: base
    width: actionPanelWidget.width + additionalComponents.width
    height: childrenRect.height
    visible: CuraApplication.platformActivity

    property bool hasPreviewButton: true

    Rectangle {
        id: actionPanelWidget

        width: UM.Theme.getSize("action_panel_widget").width
        height: childrenRect.height + 2 * UM.Theme.getSize("default_margin").height
        anchors.right: parent.right
        color: UM.Theme.getColor("main_background")
        border.width: UM.Theme.getSize("default_lining").width
        border.color: UM.Theme.getColor("lining")
        radius: UM.Theme.getSize("default_radius").width
        z: 10

        property bool outputAvailable: UM.Backend.state == UM.Backend.Done || UM.Backend.state == UM.Backend.Disabled

        Loader {
            id: loader
            anchors {
                top: parent.top
                topMargin: UM.Theme.getSize("default_margin").height
                left: parent.left
                leftMargin: UM.Theme.getSize("default_margin").width
                right: parent.right
                rightMargin: UM.Theme.getSize("default_margin").width
            }
            sourceComponent: actionPanelWidget.outputAvailable ? outputProcessWidget : sliceProcessWidget
            onLoaded: {
                if(actionPanelWidget.outputAvailable) {
                    loader.item.hasPreviewButton = base.hasPreviewButton;
                }
            }
        }

        Component {
            id: sliceProcessWidget
            SliceProcessWidget { }
        }

        Component {
            id: outputProcessWidget
            OutputProcessWidget { }
        }
    }

    Item {
        id: additionalComponents
        width: childrenRect.width
        anchors.right: actionPanelWidget.left
        anchors.rightMargin: UM.Theme.getSize("default_margin").width
        anchors.bottom: actionPanelWidget.bottom
        visible: actionPanelWidget.visible

        Column {
            id: additionalComponentsColumn
            anchors.bottom: parent.bottom
            spacing: UM.Theme.getSize("thin_margin").height

            Row {
                id: additionalComponentsRow
                anchors.right: parent.right
                spacing: UM.Theme.getSize("default_margin").width
            }

            Rectangle {
                id: clearPlateButtonBox
                height: clearPlateButton.height + (UM.Theme.getSize("default_margin").height * 2)
                width: clearPlateButton.width + (UM.Theme.getSize("default_margin").width * 2)
                color: UM.Theme.getColor("main_background")
                border.width: UM.Theme.getSize("default_lining").width
                border.color: UM.Theme.getColor("lining")
                radius: UM.Theme.getSize("default_radius").width
                visible: actionPanelWidget.outputAvailable

                Cura.PrimaryButton {
                    id: clearPlateButton
                    anchors {
                        centerIn: parent
                    }

                    height: UM.Theme.getSize("action_button").height
                    text: catalog.i18nc("@button", "  Next Part  ")
                    tooltip: "Clears build plate and opens folder to slice next part(s) with current settings."
                    toolTipContentAlignment: Cura.ToolTip.ContentAlignment.AlignLeft

                    onClicked: {
                        CuraApplication.deleteAll()
                        Cura.Actions.open.trigger()
                    }
                }
            }
        }
    }

    Component.onCompleted: base.addAdditionalComponents()

    Connections {
        target: CuraApplication
        function onAdditionalComponentsChanged(areaId) { base.addAdditionalComponents() }
    }

    function addAdditionalComponents() {
        for (var component in CuraApplication.additionalComponents["saveButton"]) {
            CuraApplication.additionalComponents["saveButton"][component].parent = additionalComponentsRow
        }
    }
}
