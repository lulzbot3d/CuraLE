// Copyright (c) 2018 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 2.3

import UM 1.2 as UM
import Cura 1.1 as Cura

Cura.ExpandablePopup {
    id: machineSelector

    property bool isGroup: Cura.MachineManager.activeMachineIsGroup

    contentPadding: UM.Theme.getSize("default_lining").width
    contentAlignment: Cura.ExpandablePopup.ContentAlignment.AlignLeft

    UM.I18nCatalog {
        id: catalog
        name: "cura"
    }

    headerItem: Cura.IconWithText {
        text: Cura.MachineManager.activeMachine != null ? Cura.MachineManager.activeMachine.name : ""
        source: {
            if (isGroup) {
                return UM.Theme.getIcon("PrinterTriple", "medium")
            } else {
                // return UM.Theme.getIcon("TAZPrinter")
                return ""
            }
        }
        font: UM.Theme.getFont("medium")
        iconColor: UM.Theme.getColor("machine_selector_printer_icon")
        iconSize: source != "" ? UM.Theme.getSize("machine_selector_icon").width: 0
    }

    contentItem: Item {
        id: popup
        width: UM.Theme.getSize("machine_selector_widget_content").width

        ScrollView {
            id: scroll
            width: parent.width
            clip: true
            leftPadding: UM.Theme.getSize("default_lining").width
            rightPadding: UM.Theme.getSize("default_lining").width

            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            MachineSelectorList {
                id: machineSelectorList
                // Can't use parent.width since the parent is the flickable component and not the ScrollView
                width: scroll.width - scroll.leftPadding - scroll.rightPadding
                property real maximumHeight: UM.Theme.getSize("machine_selector_widget_content").height - buttonRow.height

                // We use an extra property here, since we only want to to be informed about the content size changes.
                onContentHeightChanged: {
                    scroll.height = Math.min(contentHeight, maximumHeight)
                    popup.height = scroll.height + buttonRow.height
                }

                Component.onCompleted: {
                    scroll.height = Math.min(contentHeight, maximumHeight)
                    popup.height = scroll.height + buttonRow.height
                }
            }
        }

        Rectangle {
            id: separator

            anchors.top: scroll.bottom
            width: parent.width
            height: UM.Theme.getSize("default_lining").height
            color: UM.Theme.getColor("lining")
        }

        Row {
            id: buttonRow

            // The separator is inside the buttonRow. This is to avoid some weird behaviours with the scroll bar.
            anchors.top: separator.top
            anchors.horizontalCenter: parent.horizontalCenter
            padding: UM.Theme.getSize("default_margin").width
            spacing: UM.Theme.getSize("default_margin").width

            Cura.SecondaryButton {
                id: addPrinterButton
                leftPadding: UM.Theme.getSize("default_margin").width
                rightPadding: UM.Theme.getSize("default_margin").width
                text: catalog.i18nc("@button", "Add Printer")
                // The maximum width of the button is half of the total space, minus the padding of the parent, the left
                // padding of the component and half the spacing because of the space between buttons.
                fixedWidthMode: true
                width: UM.Theme.getSize("machine_selector_widget_content").width / 2 - leftPadding
                onClicked: {
                    toggleContent()
                    Cura.Actions.addMachine.trigger()
                }
            }

            Cura.SecondaryButton {
                id: managePrinterButton
                leftPadding: UM.Theme.getSize("default_margin").width
                rightPadding: UM.Theme.getSize("default_margin").width
                text: catalog.i18nc("@button", "Manage Printers")
                fixedWidthMode: true
                // The maximum width of the button is half of the total space, minus the padding of the parent, the right
                // padding of the component and half the spacing because of the space between buttons.
                width: UM.Theme.getSize("machine_selector_widget_content").width / 2 - leftPadding
                onClicked: {
                    toggleContent()
                    Cura.Actions.configureMachines.trigger()
                }
            }
        }
    }
}
