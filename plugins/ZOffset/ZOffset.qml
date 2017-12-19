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
        rows: 3
        rowSpacing: 1
        columnSpacing: 10
        anchors.fill: parent
        anchors.centerIn: parent
        anchors.leftMargin: 65
        anchors.rightMargin: 65


        Label
        {
            text: "Current Z-Offset value:"
            color: UM.Theme.getColor("setting_control_text")
            font: UM.Theme.getFont("default")
            Layout.row: 1
            Layout.column: 1
            Layout.preferredWidth: parent.width/3 - gridLayout.rowSpacing*3
            Layout.preferredHeight: UM.Theme.getSize("section").height
        }

        Label
        {
            text: ""
            id: zOffsetLabel
            color: UM.Theme.getColor("setting_control_text")
            font: UM.Theme.getFont("default")
            Layout.row: 1
            Layout.column: 2
            Layout.preferredWidth: parent.width/3 - gridLayout.columnSpacing*3
            Layout.preferredHeight: UM.Theme.getSize("section").height
        }

        Label
        {
            text: "Set new Z-Offset value:"
            color: UM.Theme.getColor("setting_control_text")
            font: UM.Theme.getFont("default")
            Layout.row: 2
            Layout.column: 1
            Layout.preferredWidth: parent.width/3 - gridLayout.columnSpacing*3
            Layout.preferredHeight: UM.Theme.getSize("section").height
        }

        TextField
        {
            text: ""
            id: zOffsetTextField
            Layout.row: 2
            Layout.column: 2
            Layout.preferredWidth: parent.width/3 - gridLayout.columnSpacing*3
            Layout.preferredHeight: UM.Theme.getSize("section").height
            readOnly: !( UM.Preferences.getValue( "general/zoffsetSaveToFlashEnabled" ))

            validator: DoubleValidator
            {
                bottom: -100
                top: 100
            }
        }


        Button
        {
            text: "Save"
            id: saveButton
            Layout.row: 3
            Layout.column: 2
            Layout.preferredWidth: parent.width/3 - gridLayout.columnSpacing*3
            Layout.preferredHeight: UM.Theme.getSize("section").height
            enabled: UM.Preferences.getValue( "general/zoffsetSaveToFlashEnabled" )

            onClicked: connectedPrinter.setZOffset( parseFloat( zOffsetTextField.text ) )

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
        id: timerValuesUpdates
        interval: 500
        running: true
        repeat: true

        onTriggered:
        {
            zOffsetTextField.readOnly =  (!( UM.Preferences.getValue( "general/zoffsetSaveToFlashEnabled" )))
            saveButton.enabled = UM.Preferences.getValue( "general/zoffsetSaveToFlashEnabled" )

            if( (connectedPrinter != null) && (connectedPrinter.getZOffset() != undefined) )
                zOffsetLabel.text = connectedPrinter.getZOffset()
        }
    }
}
