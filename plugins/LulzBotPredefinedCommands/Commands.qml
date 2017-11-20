import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1

import UM 1.2 as UM
import Cura 1.0 as Cura

Item
{
    property var connectedPrinter: printerConnected ? Cura.MachineManager.printerOutputDevices[0] : null
    //height: childrenRect.height + 10
    //width: childrenRect.width + 10
    width: 410
    height: 130
    enabled: connectedPrinter

    //Column
    //{
    //    width: 400
    //    height: 120
    //    anchors.left: parent.left
    //    anchors.top: parent.top
    //    anchors.topMargin: 1
    //    spacing: 1

        GridLayout
        {
            id: predefinedButtons
            columns: 3
            rows: 3
            rowSpacing: 1
            columnSpacing: 1
            anchors.fill: parent
            anchors.centerIn: parent
            anchors.leftMargin: 5
            anchors.rightMargin: 5

            Button
            {
                text: "Preheat nozzle"
                //width: parent.width/3
                Layout.row: 1
                Layout.column: 1
                Layout.preferredWidth: parent.width/3 - predefinedButtons.columnSpacing*7
                Layout.preferredHeight: UM.Theme.getSize("section").height

                onClicked:
                {
                    connectedPrinter.preheatHotend(-1)
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

            Button
            {
                text: "Wipe nozzle"
                //width: parent.width/3
                Layout.row: 1
                Layout.column: 2
                Layout.preferredWidth: parent.width/3 - predefinedButtons.columnSpacing*7
                Layout.preferredHeight: UM.Theme.getSize("section").height
                onClicked:
                {
                    connectedPrinter.wipeNozzle()
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

            Button
            {
                text: "Cool nozzle"
                //width: parent.width/3
                Layout.row: 1
                Layout.column: 3
                Layout.preferredWidth: parent.width/3 - predefinedButtons.columnSpacing*7
                Layout.preferredHeight: UM.Theme.getSize("section").height

                onClicked:
                {
                    connectedPrinter.setTargetHotendTemperature(-1, 0)
                }
                style:  ButtonStyle
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

            Button
            {
                text: "Preheat bed"
                //width: parent.width/3
                Layout.row: 2
                Layout.column: 1
                Layout.preferredWidth: parent.width/3 - predefinedButtons.columnSpacing*7
                Layout.preferredHeight: UM.Theme.getSize("section").height

                onClicked:
                {
                    connectedPrinter.preheatBed()
                }
                style:  ButtonStyle
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

            Button
            {
                text: "Cool bed"
                //width: parent.width/3
                Layout.row: 2
                Layout.column: 2
                Layout.preferredWidth: parent.width/3 - predefinedButtons.columnSpacing*7
                Layout.preferredHeight: UM.Theme.getSize("section").height

                onClicked:
                {
                    connectedPrinter.setTargetBedTemperature(0)
                }
                style:  ButtonStyle
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

            Button
            {
                text: "Cold pull"
                //width: parent.width/3
                Layout.row: 2
                Layout.column: 3
                Layout.preferredWidth: parent.width/3 - predefinedButtons.columnSpacing*7
                Layout.preferredHeight: UM.Theme.getSize("section").height
                enabled:
                {
                     var name = Cura.MachineManager.activeMachineName
                     if(name.includes("Aerostruder"))
                    {
                         return connectedPrinter && false;
                    }
                    else
                    {
                        return connectedPrinter && true
                    }
                }

                onClicked:
                {
                    connectedPrinter.coldPull(-1)
                }
                style:  ButtonStyle
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

            Button
            {
                text: "Motors off"
                //width: parent.width/3
                Layout.row: 3
                Layout.column: 2
                Layout.preferredWidth: parent.width/3 - predefinedButtons.columnSpacing*7
                Layout.preferredHeight: UM.Theme.getSize("section").height

                onClicked:
                {
                    Cura.USBPrinterManager.sendCommandToCurrentPrinter("M18")
                }
                style:  ButtonStyle
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


        /*
        Button
        {
            text: "Wipe nozzle"
            width: parent.width

            onClicked:
            {
                connectedPrinter.wipeNozzle()
            }
            style: UM.Theme.styles.print_monitor_control_button
        }

        Button
        {
            text: "Preheat nozzle"
            width: parent.width

            onClicked:
            {
                connectedPrinter.preheatHotend(-1)
            }
            style: UM.Theme.styles.print_monitor_control_button
        }

        Button
        {
            text: "Preheat bed"
            width: parent.width

            onClicked:
            {
                connectedPrinter.preheatBed()
            }
            style: UM.Theme.styles.print_monitor_control_button
        }

        Button
        {
            text: "Motors off"
            width: parent.width

            onClicked:
            {
                Cura.USBPrinterManager.sendCommandToCurrentPrinter("M18")
            }
            style: UM.Theme.styles.print_monitor_control_button
        }

        Button
        {
            text: "Cool nozzle"
            width: parent.width

            onClicked:
            {
                connectedPrinter.setTargetHotendTemperature(-1, 0)
            }
            style: UM.Theme.styles.print_monitor_control_button
        }

        Button
        {
            text: "Cool bed"
            width: parent.width

            onClicked:
            {
                connectedPrinter.setTargetBedTemperature(0)
            }
            style: UM.Theme.styles.print_monitor_control_button
        }

        Button
        {
            text: "Cold pull"
            width: parent.width

            onClicked:
            {
                connectedPrinter.coldPull(-1)
            }
            style: UM.Theme.styles.print_monitor_control_button
        }
        */
    //}
}
