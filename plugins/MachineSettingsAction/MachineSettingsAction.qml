// Copyright (c) 2019 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3

import UM 1.3 as UM
import Cura 1.1 as Cura


//
// This component contains the content for the "Welcome" page of the welcome on-boarding process.
//
Cura.MachineAction
{
    UM.I18nCatalog { id: catalog; name: "cura" }

    anchors.fill: parent

    property var extrudersModel: Cura.ExtrudersModel {}

    // If we create a TabButton for "Printer" and use Repeater for extruders, for some reason, once the component
    // finishes it will automatically change "currentIndex = 1", and it is VERY difficult to change "currentIndex = 0"
    // after that. Using a model and a Repeater to create both "Printer" and extruder TabButtons seem to solve this
    // problem.
    Connections
    {
        target: extrudersModel
        function onItemsChanged() { tabNameModel.update() }
    }

    ListModel
    {
        id: tabNameModel

        Component.onCompleted: update()

        function update()
        {
            clear()
            append({ name: catalog.i18nc("@title:tab", "Printer") })
            for (var i = 0; i < extrudersModel.count; i++)
            {
                const m = extrudersModel.getItem(i)
                append({ name: m.name })
            }
        }
    }

    Cura.RoundedRectangle
    {
        anchors
        {
            top: tabBar.bottom
            topMargin: -UM.Theme.getSize("default_lining").height
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        cornerSide: Cura.RoundedRectangle.Direction.Down
        border.color: UM.Theme.getColor("lining")
        border.width: UM.Theme.getSize("default_lining").width
        radius: UM.Theme.getSize("default_radius").width
        color: UM.Theme.getColor("main_background")
        StackLayout
        {
            id: tabStack
            anchors.fill: parent

            currentIndex: tabBar.currentIndex

            MachineSettingsPrinterTab
            {
                id: printerTab
            }

            Repeater
            {
                model: extrudersModel
                delegate: MachineSettingsExtruderTab
                {
                    id: discoverTab
                    extruderPosition: model.index
                    extruderStackId: model.id
                }
            }
        }
    }

    Label
    {
        id: machineNameLabel
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.leftMargin: UM.Theme.getSize("default_margin").width
        text: Cura.MachineManager.activeMachine.name
        horizontalAlignment: Text.AlignHCenter
        font: UM.Theme.getFont("large_bold")
        renderType: Text.NativeRendering
    }

    UM.TabRow
    {
        id: tabBar
        anchors.top: machineNameLabel.bottom
        anchors.topMargin: UM.Theme.getSize("default_margin").height
        width: parent.width
        Repeater
        {
            model: tabNameModel
            delegate: UM.TabRowButton
            {
                text: model.name
            }
        }
    }

    Component
    {
        id: headPolygonTextField
        UM.TooltipArea
        {
            height: textField.height
            width: textField.width
            text: tooltip

            property string _label: (typeof(label) === 'undefined') ? "" : label

            Row
            {
                spacing: UM.Theme.getSize("default_margin").width

                Label
                {
                    text: _label
                    visible: _label != ""
                    elide: Text.ElideRight
                    width: Math.max(0, settingsTabs.labelColumnWidth)
                    anchors.verticalCenter: textFieldWithUnit.verticalCenter
                }

                Item
                {
                    id: textFieldWithUnit
                    width: textField.width
                    height: textField.height

                    TextField
                    {
                        id: textField
                        text:
                        {
                            var polygon = JSON.parse(machineHeadPolygonProvider.properties.value);
                            var item = (axis == "x") ? 0 : 1
                            var result = polygon[0][item];
                            for(var i = 1; i < polygon.length; i++) {
                                if (side == "min") {
                                    result = Math.min(result, polygon[i][item]);
                                } else {
                                    result = Math.max(result, polygon[i][item]);
                                }
                            }
                            result = Math.abs(result);
                            printHeadPolygon[axis][side] = result;
                            return result;
                        }
                        validator: RegExpValidator { regExp: /[0-9\.]{0,6}/ }
                        onEditingFinished:
                        {
                            printHeadPolygon[axis][side] = parseFloat(textField.text);
                            var polygon = [];
                            polygon.push([-printHeadPolygon["x"]["min"], printHeadPolygon["y"]["max"]]);
                            polygon.push([-printHeadPolygon["x"]["min"],-printHeadPolygon["y"]["min"]]);
                            polygon.push([ printHeadPolygon["x"]["max"], printHeadPolygon["y"]["max"]]);
                            polygon.push([ printHeadPolygon["x"]["max"],-printHeadPolygon["y"]["min"]]);
                            var polygon_string = JSON.stringify(polygon);
                            if(polygon_string != machineHeadPolygonProvider.properties.value)
                            {
                                machineHeadPolygonProvider.setPropertyValue("value", polygon_string);
                                manager.forceUpdate();
                            }
                        }
                    }

                    Label
                    {
                        text: catalog.i18nc("@label", "mm")
                        anchors.right: textField.right
                        anchors.rightMargin: y - textField.y
                        anchors.verticalCenter: textField.verticalCenter
                    }
                }
            }
        }
    }

    property var printHeadPolygon:
    {
        "x": {
            "min": 0,
            "max": 0,
        },
        "y": {
            "min": 0,
            "max": 0,
        },
    }


    UM.SettingPropertyProvider
    {
        id: machineExtruderCountProvider

        containerStackId: Cura.MachineManager.activeMachineId
        key: "machine_extruder_count"
        watchedProperties: [ "value", "description" ]
        storeIndex: manager.containerIndex
    }

    UM.SettingPropertyProvider
    {
        id: machineHeadPolygonProvider

        containerStackId: Cura.MachineManager.activeMachineId
        key: "machine_head_with_fans_polygon"
        watchedProperties: [ "value" ]
        storeIndex: manager.containerIndex
    }
}
