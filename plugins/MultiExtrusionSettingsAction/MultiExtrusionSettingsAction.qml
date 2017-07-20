// Copyright (c) 2017 Alephobjects

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import QtQuick.Window 2.1

import UM 1.2 as UM
import Cura 1.0 as Cura


Cura.MachineAction
{
    property var extrudersCount: machineExtruderCountProvider.properties.value

    anchors.fill: parent;
    Item
    {
        id: multiExtrusionMachineAction
        anchors.fill: parent;

        UM.I18nCatalog { id: catalog; name: "cura"; }

        Label
        {
            id: pageTitle
            width: parent.width
            text: catalog.i18nc("@title", "Extruders Settings")
            wrapMode: Text.WordWrap
            font.pointSize: 18;
        }
        Label
        {
            id: pageDescription
            anchors.top: pageTitle.bottom
            anchors.topMargin: UM.Theme.getSize("default_margin").height
            width: parent.width
            wrapMode: Text.WordWrap
            text: catalog.i18nc("@label", "Please enter the correct settings for your printer below:")
        }

        Column
        {
            height: parent.height - y
            width: parent.width - UM.Theme.getSize("default_margin").width
            spacing: UM.Theme.getSize("default_margin").height

            anchors.left: parent.left
            anchors.top: pageDescription.bottom
            anchors.topMargin: UM.Theme.getSize("default_margin").height

            RowLayout
            {
                width: parent.width
                spacing: UM.Theme.getSize("default_margin").height

                Repeater
                {
                    model: extrudersCount
                    delegate: Loader
                    {
                        sourceComponent: extruderComponent
                        property var extruderId: model.index
                    }
                }
            }
        }
    }

    Component
    {
        id: extruderComponent

        Column
        {
            width: parent.width
            spacing: UM.Theme.getSize("default_margin").height

            Label
            {
                text: catalog.i18nc("@label", "Extruder" + extruderNrProvider.properties.value)
                font.bold: true
            }

            Grid
            {
                columns: 3
                columnSpacing: UM.Theme.getSize("default_margin").width
                rowSpacing: UM.Theme.getSize("default_margin").height

                Label
                {
                    text: catalog.i18nc("@label", "Nozzle size")
                }
                TextField
                {
                    id: nozzleSizeField
                    text: extruderNozzleSizeProvider.properties.value
                    validator: RegExpValidator { regExp: /[0-9\.]{0,6}/ }
                    onEditingFinished: { extruderNozzleSizeProvider.setPropertyValue("value", text) }
                }
                Label
                {
                    text: catalog.i18nc("@label", "mm")
                }

                Label
                {
                    text: catalog.i18nc("@label", "X offset")
                }
                TextField
                {
                    id: xOffsetField
                    text: extruderXOffsetProvider.properties.value
                    validator: RegExpValidator { regExp: /-?[0-9\.]{0,6}/ }
                    onEditingFinished: { extruderXOffsetProvider.setPropertyValue("value", text); manager.forceUpdate() }
                }
                Label
                {
                    text: catalog.i18nc("@label", "mm")
                }

                Label
                {
                    text: catalog.i18nc("@label", "Y offset")
                }
                TextField
                {
                    id: yOffsetField
                    text: extruderYOffsetProvider.properties.value
                    validator: RegExpValidator { regExp: /-?[0-9\.]{0,6}/ }
                    onEditingFinished: { extruderYOffsetProvider.setPropertyValue("value", text); manager.forceUpdate() }
                }
                Label
                {
                    text: catalog.i18nc("@label", "mm")
                }
            }

            UM.SettingPropertyProvider
            {
                id: extruderNozzleSizeProvider

                containerStackId: Cura.ExtruderManager.extruderIds[extruderId]
                key: "machine_nozzle_size"
                watchedProperties: [ "value" ]
            }

            UM.SettingPropertyProvider
            {
                id: extruderXOffsetProvider

                containerStackId: Cura.ExtruderManager.extruderIds[extruderId]
                key: "machine_nozzle_offset_x"
                watchedProperties: [ "value" ]
            }

            UM.SettingPropertyProvider
            {
                id: extruderYOffsetProvider

                containerStackId: Cura.ExtruderManager.extruderIds[extruderId]
                key: "machine_nozzle_offset_y"
                watchedProperties: [ "value" ]
            }

            UM.SettingPropertyProvider
            {
                id: extruderNrProvider

                containerStackId: Cura.ExtruderManager.extruderIds[extruderId]
                key: "extruder_nr"
                watchedProperties: [ "value" ]
            }
        }
    }

    UM.SettingPropertyProvider
    {
        id: machineExtruderCountProvider

        containerStackId: Cura.MachineManager.activeMachineId
        key: "machine_extruder_count"
        watchedProperties: [ "value" ]
    }
}
