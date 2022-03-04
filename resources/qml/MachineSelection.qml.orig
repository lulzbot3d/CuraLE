// Copyright (c) 2017 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1

import UM 1.2 as UM
import Cura 1.0 as Cura
import "Menus"

ToolButton
{
    text: Cura.MachineManager.activeMachineName

    tooltip: Cura.MachineManager.activeMachineName

    style: ButtonStyle
    {
        background: Rectangle
        {
            color:
            {
                if(control.pressed)
                {
                    return UM.Theme.getColor("sidebar_header_active");
                }
                else if(control.hovered)
                {
                    return UM.Theme.getColor("sidebar_header_hover");
                }
                else
                {
                    return UM.Theme.getColor("sidebar_header_bar");
                }
            }
            Behavior on color { ColorAnimation { duration: 50; } }

            UM.RecolorImage
            {
                id: downArrow
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: UM.Theme.getSize("default_margin").width
                width: UM.Theme.getSize("standard_arrow").width
                height: UM.Theme.getSize("standard_arrow").height
                sourceSize.width: width
                sourceSize.height: width
                color: UM.Theme.getColor("text_emphasis")
                source: UM.Theme.getIcon("arrow_bottom")
            }
            Label
            {
                id: sidebarComboBoxLabel
                color: UM.Theme.getColor("sidebar_header_text_active")
                text: control.text;
                elide: Text.ElideRight;
                anchors.left: parent.left;
                anchors.leftMargin: UM.Theme.getSize("default_margin").width * 2
                anchors.right: downArrow.left;
                anchors.rightMargin: control.rightMargin;
                anchors.verticalCenter: parent.verticalCenter;
                font: UM.Theme.getFont("large")
            }
        }
        label: Label {}
    }

    menu: PrinterMenu { }

    Row
    {
        anchors.fill: parent
        layoutDirection: Qt.RightToLeft
        anchors.rightMargin: UM.Theme.getSize("default_margin").width * 3
        spacing: 2

        UM.SimpleButton
        {
            id: printerInfoButton

            color: hovered ? UM.Theme.getColor("text") : UM.Theme.getColor("info_button");
            iconSource: UM.Theme.getIcon("notice");

            width: UM.Theme.getSize("setting_control").height
            height: UM.Theme.getSize("setting_control").height
            anchors.verticalCenter: parent.verticalCenter

            visible: Cura.MachineManager.currentPrinterHasInfo

            onClicked:
            {
                Cura.MachineManager.openCurrentPrinterInfo()
            }
            onEntered:
            {
                var content = catalog.i18nc("@tooltip", "Printer Info")
                base.showTooltip(parent, Qt.point(0, parent.height / 2),  content)
            }
            onExited: base.hideTooltip()
        }

        UM.SimpleButton
        {
            id: toolheadInfoButton

            color: hovered ? UM.Theme.getColor("text") : UM.Theme.getColor("info_button");
            iconSource: UM.Theme.getIcon("notice");

            width: UM.Theme.getSize("setting_control").height
            height: UM.Theme.getSize("setting_control").height
            anchors.verticalCenter: parent.verticalCenter

            visible: Cura.MachineManager.currentToolheadHasInfo

            onClicked:
            {
                Cura.MachineManager.openCurrentToolheadInfo()
            }
            onEntered:
            {
                var content = catalog.i18nc("@tooltip", "Toolhead Info")
                base.showTooltip(parent, Qt.point(0, parent.height / 2),  content)
            }
            onExited: base.hideTooltip()
        }
    }
}
