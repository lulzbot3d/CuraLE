// Copyright (c) 2022 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3

import UM 1.5 as UM
import Cura 1.1 as Cura

Control
{
    id: root
    property alias text: link_text.text
    property alias imageSource: image.source
    property bool isCheckbox: false
    property bool checked: false
    property bool isDisplayOnly: false
    property var onClicked

    states:
    [
        State
        {
            name: "hovered";
            when: mouse_area.containsMouse && !isDisplayOnly
            PropertyChanges
            {
                target: background
                color: UM.Theme.getColor("monitor_card_hover")
            }
            PropertyChanges
            {
                target: link_text
                font.underline: true
            }
        },
        State
        {
            name: "disabled";
            when: isDisplayOnly
            PropertyChanges
            {
                target: mouse_area
                onClicked: { return; }
            }
            PropertyChanges
            {
                target: background
                border.color: UM.Theme.getColor("action_button_disabled_text")
                border.width: 3
                radius: 1
            }
            PropertyChanges
            {
                target: link_text
                color: UM.Theme.getColor("text")
            }
        },
        State
        {
            name: "checked"
            when: isCheckbox && checked
            PropertyChanges
            {
                target: background
                color: UM.Theme.getColor("checkbox")
                border.width: 2
            }
        },
        State
        {
            name: "unchecked"
            when: isCheckbox && !checked
        }
    ]

    MouseArea
    {
        id: mouse_area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            if (isCheckbox) {
                checked = !checked
            } else {
                root.onClicked && root.onClicked()
            }
        }
    }

    rightPadding: UM.Theme.getSize("wide_margin").width
    bottomPadding: UM.Theme.getSize("wide_margin").height
    leftPadding: UM.Theme.getSize("wide_margin").width

    background: Rectangle
    {
        id: background
        height: parent.height
        border.color: UM.Theme.getColor("primary_button")
        color: "transparent"
        border.width: 1
        radius: 3
    }

    contentItem: ColumnLayout
    {
        id: column
        Layout.alignment: Qt.AlignVCenter
        spacing: UM.Theme.getSize("default_margin").height
        height: parent.height
        width: parent.width

        UM.Label
        {
            id: link_text
            Layout.fillWidth: true
            font: UM.Theme.getFont("medium")
            color: UM.Theme.getColor("text_link")
            horizontalAlignment: Text.AlignHCenter
        }

        Image
        {
            id: image
            source: imageSource
            Layout.topMargin: UM.Theme.getSize("wide_margin").height
            width: 110 * screenScaleFactor
            sourceSize.width: width
            sourceSize.height: height
        }

        Image
        {
            id: checkbox
            visible: isCheckbox
            source: checked? UM.Theme.getIcon("CheckCircle") : UM.Theme.getIcon("CancelCircle")
            width: 50
            sourceSize.width: width
            sourceSize.height: height
        }
    }
}