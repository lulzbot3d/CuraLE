// Copyright (c) 2018 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 2.3

import UM 1.4 as UM
import Cura 1.1 as Cura

Item
{
    height: signInButton.visible ? signInButton.height : accountWidget.height
    width: signInButton.visible ? signInButton.width : accountWidget.width

    Button
    {
        id: signInButton

        anchors.verticalCenter: parent.verticalCenter

        text: catalog.i18nc("@action:button", ":O")

        height: Math.round(0.5 * UM.Theme.getSize("main_window_header").height)
        visible: true

        hoverEnabled: true

        background: Rectangle
        {
            radius: UM.Theme.getSize("action_button_radius").width
            color: UM.Theme.getColor("main_window_header_background")
            border.width: UM.Theme.getSize("default_lining").width
            border.color: UM.Theme.getColor("primary_text")

            Rectangle
            {
                anchors.fill: parent
                radius: parent.radius
                color: UM.Theme.getColor("primary_text")
                opacity: signInButton.hovered ? 0.2 : 0
                Behavior on opacity { NumberAnimation { duration: 100 } }
            }
        }

        contentItem: Label
        {
            id: label
            text: signInButton.text
            font: UM.Theme.getFont("default")
            color: UM.Theme.getColor("primary_text")
            width: contentWidth
            verticalAlignment: Text.AlignVCenter
            renderType: Text.NativeRendering
        }
    }
}
