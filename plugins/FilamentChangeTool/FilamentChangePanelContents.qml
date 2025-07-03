// Copyright (c) 2023 Fargo Additive Manufacturing Equipment 3D, LLC.
// CuraLE is released under the terms of the LGPLv3 or higher.

import QtQuick 2.15
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.15

import UM 1.2 as UM
import Cura 1.0 as Cura

Item {
    id: base

    height: childrenRect.height
    width: mainColumn.width
    property int columnSpacing: UM.Theme.getSize("default_margin").height
    property int rowSpacing: UM.Theme.getSize("default_margin").width
    UM.I18nCatalog { id: catalog; name: "uranium"}

    property var manager: Cura.FilamentChangeManager
    property int changeLayerCount: {
            let layers = provider.properties.value;
            let layer_count = 0;
            if (layers) {
                layer_count = layers.split(",").length;
            };
            return layer_count;
        }

    function showTooltip(item, position, text) {
        tooltip.text = text;
        position = item.mapToItem(backgroundItem, position.x - UM.Theme.getSize("default_arrow").width, position.y);
        tooltip.show(position);
    }

    function hideTooltip() {
        tooltip.hide();
    }

    function getUserInput() {
        let user_input = layersTextField.text.replace(/ /g, '').split(',');
        let filtered_input = user_input.filter((x) => x != '');
        layersTextField.text = ""
        return filtered_input;
    }

    function addUserInput() {
        let newLayers = getUserInput()
        let currentLayers = provider.properties.value
        if (!currentLayers) {
            currentLayers = []
        } else {
            currentLayers = currentLayers.split(',')
        }
        for (let i = 0; i < newLayers.length; i++) {
            if (currentLayers.includes(newLayers[i])) {
                continue;
            }
            currentLayers.push(newLayers[i])
        }
        currentLayers.sort((a, b) => a - b)
        let out = currentLayers.join();
        provider.setPropertyValue("value", out)
        manager.writeScriptToStack()
    }

    function removeLayer(toRemove) {
        let currentLayers = provider.properties.value
        if (!currentLayers) {
            return;
        } else {
            currentLayers = currentLayers.split(',')
        }
        let reducedList = []
        for (let i = 0; i < currentLayers.length; i++) {
            if (toRemove.includes(currentLayers[i])) {
                continue;
            }
            reducedList.push(currentLayers[i])
        }
        let out = reducedList.join();
        provider.setPropertyValue("value", out)
        manager.writeScriptToStack()
    }

    function clearCurrentLayers() {
        provider.setPropertyValue("value", "")
        manager.writeScriptToStack()
        return
    }

    ColumnLayout {
        id: mainColumn

        width: UM.Theme.getSize("setting_control").width * 1.5

        spacing: columnSpacing

        Column {
            id: currentLayersColumn

            Layout.fillWidth: true
            Layout.maximumWidth: parent.width

            spacing: Math.round(columnSpacing / 2)

            visible: layersRepeater.count > 0

            Binding {
                target: layersRepeater
                property: "model"
                value: {
                    let layers = provider.properties.value
                    if (layers) {
                        return layers.split(',')
                    } else {
                        return []
                    }
                }
            }

            Repeater {
                id: layersRepeater

                model: []

                delegate: ColumnLayout {

                    width: parent.width

                    spacing: Math.round(columnSpacing / 2)

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.maximumWidth: parent.width

                        spacing: rowSpacing

                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.leftMargin: 35
                            text: modelData
                        }
                        Button {
                            Layout.preferredWidth: Math.round(UM.Theme.getSize("setting_control").width * .5)
                            Layout.alignment: Qt.AlignRight
                            text: "Remove"

                            onClicked: base.removeLayer(modelData)
                        }
                    }
                    Rectangle {
                        Layout.preferredHeight: UM.Theme.getSize("default_lining").height
                        Layout.fillWidth: true

                        visible: layersRepeater.count - 1 != index

                        color: UM.Theme.getColor("text_subtext")
                    }
                }
            }
        }

        RowLayout {
            id: seperatorRow

            Layout.fillWidth: true
            Layout.maximumWidth: parent.width

            visible: layersRepeater.visible

            spacing: rowSpacing

            Rectangle {
                Layout.preferredHeight: UM.Theme.getSize("thick_lining").height
                Layout.fillWidth: true

                color: UM.Theme.getColor("lining")
            }
        }

        RowLayout {
            id: inputRow

            Layout.fillWidth: true
            Layout.maximumWidth: parent.width

            spacing: rowSpacing / 2

            TextField {
                id: layersTextField
                Layout.fillWidth: true

                placeholderText: "Enter layers..."
                validator: RegularExpressionValidator { regularExpression: /^\d[\d*\,*]*/ }

                onAccepted: base.addUserInput()
            }

            Button {
                id: addButton
                Layout.preferredWidth: Math.round(UM.Theme.getSize("setting_control").width * .5)
                text: "Add"

                enabled: layersTextField.length > 0

                onClicked: base.addUserInput()
            }

            UM.ColorImage {
                id: toolInfo

                source: UM.Theme.getIcon("Information")
                width: UM.Theme.getSize("section_icon").width
                height: UM.Theme.getSize("section_icon").height

                color: UM.Theme.getColor("icon")

                MouseArea {
                    id: toolInfoMouseArea
                    anchors.fill: parent
                    hoverEnabled: true

                    Cura.ToolTip {
                        id: tooltip
                        width: UM.Theme.getSize("tooltip").width
                        tooltipText: "<h3><b>Before using the Filament Change Tool, slice your print to preview the layers using the layer slider.</b></h3>\
                                    <h3>Input the layer number(s) where you want to start printing with the new filament; you can add multiple layers \
                                    at once by typing a comma-separated list (e.g., 10,20,30). Click \"Add\" or press Enter to confirm your selection.</h3>\
                                    <h3><i>Remember, you must reslice the file after adding any filament changes.</i></h3>"
                        visible: parent.containsMouse
                    }
                }
            }
        }

        RowLayout {
            id: clearRow

            Layout.fillWidth: true
            Layout.maximumWidth: parent.width

            spacing: rowSpacing

            Button {
                id: clearButton
                Layout.fillWidth: true
                text: "Clear All"

                enabled: changeLayerCount > 0

                onClicked: base.clearCurrentLayers()
            }
        }

        RowLayout {
            id: pauseRow

            Layout.fillWidth: true
            Layout.maximumWidth: parent.width

            spacing: rowSpacing

            CheckBox {
                id: pauseCheckbox
                text: catalog.i18nc("@action:button", "Pause Only")
                checked: UM.Preferences.getValue("filament_change/ensure_pause")
                onClicked: UM.Preferences.setValue("filament_change/ensure_pause", checked)

                MouseArea {
                    id: pauseMouseArea
                    anchors.fill: parent
                    hoverEnabled: true

                    Cura.ToolTip {
                        id: pauseTooltip
                        width: UM.Theme.getSize("tooltip").width
                        tooltipText: "<h3>The 3D printer will pause at specified layers without starting a filament change.</h3> \
                        <h3>This is useful for inserting captive hardware into your prints.</h3>"
                        visible: parent.containsMouse
                    }
                }
            }
        }
    }

    UM.SettingPropertyProvider {
        id: provider
        containerStackId: manager.scriptStackId
        key: "layer_number"
        watchedProperties: [ "value" ]
        storeIndex: 0
    }
}
