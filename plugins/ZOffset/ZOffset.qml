import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1

import UM 1.2 as UM
import Cura 1.0 as Cura

Item
{
    property var connectedPrinter: printerConnected ? Cura.MachineManager.printerOutputDevices[0] : null
    width: 410
    height: 90
    enabled: connectedPrinter


    GridLayout
    {
        id: gridLayout
        columns: 2
        rows: 2
        rowSpacing: 1
        columnSpacing: 1
        anchors.fill: parent
        anchors.centerIn: parent
        anchors.leftMargin: 65
        anchors.rightMargin: 65


        Label
        {
            text: "Z-Offset value"
            color: UM.Theme.getColor("setting_control_text")
            font: UM.Theme.getFont("default")
            //width: parent.width / 2
            Layout.row: 1
            Layout.column: 1
            Layout.preferredWidth: parent.width/3 - gridLayout.rowSpacing*3
            Layout.preferredHeight: UM.Theme.getSize("section").height
        }

        TextField
        {
            text: "1"
            id: zOffsetTextField
            Layout.row: 1
            Layout.column: 2
            Layout.preferredWidth: parent.width/3 - gridLayout.rowSpacing*3
            Layout.preferredHeight: UM.Theme.getSize("section").height

            validator: DoubleValidator
            {
                bottom: 0
                top: 100
            }
        }


        CheckBox
        {
            id: check

            text: "Save to flash memory"
            checked: false
            enabled: UM.Preferences.getValue( "general/zoffsetSaveToFlashEnabled" )

            Layout.row: 2
            Layout.column: 1
            Layout.preferredWidth: parent.width/3 - gridLayout.rowSpacing*3
            Layout.preferredHeight: UM.Theme.getSize("section").height

            onClicked:
            {
                // TODO
            }
        }


        Button
        {
            text: "Save"
            Layout.row: 2
            Layout.column: 2
            Layout.preferredWidth: parent.width/3 - gridLayout.rowSpacing*3
            Layout.preferredHeight: UM.Theme.getSize("section").height

            onClicked:
            {
                // TODO connectedPrinter.preheatHotend(-1)
            }
            style: ButtonStyle
            {
                background: Rectangle
                {
                    radius: 4
                    border.width: UM.Theme.getSize("default_lining").width
                    border.color:
                    {
                        if(!control.enabled)
                            return UM.Theme.getColor("action_button_disabled_border");
                        else if(control.pressed)
                            return UM.Theme.getColor("action_button_active_border");
                        else if(control.hovered)
                            return UM.Theme.getColor("action_button_hovered_border");
                        else
                            return UM.Theme.getColor("action_button_border");
                    }
                    color:
                    {
                        if(!control.enabled)
                            //return UM.Theme.getColor("button_disabled");
                            return UM.Theme.getColor("button_disabled_lighter");
                        else if(control.pressed)
                            return UM.Theme.getColor("button_active");
                        else if(control.hovered)
                            return UM.Theme.getColor("button_hover");
                        else
                            return UM.Theme.getColor("button");
                    }
                    //Behavior on color { ColorAnimation { duration: 50; } }

                    implicitWidth: actualLabel.contentWidth + (UM.Theme.getSize("default_margin").width * 2)
                    implicitHeight: actualLabel.contentHeight + (UM.Theme.getSize("default_margin").height/2)

                    Label
                    {
                        id: actualLabel
                        anchors.centerIn: parent
                        color:
                        {
                            if(!control.enabled)
                                return UM.Theme.getColor("button_disabled_text");
                            else
                                return UM.Theme.getColor("button_text");
                        }
                        font: UM.Theme.getFont("small")
                        text: control.text
                    }
                }
                label: Item { }
            }
        }


    }


    Timer
    {
        interval: 500
        running: true
        repeat: true

        onTriggered: check.enabled = UM.Preferences.getValue( "general/zoffsetSaveToFlashEnabled" )
    }
}
