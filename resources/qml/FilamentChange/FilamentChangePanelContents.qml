// Copyright (c) 2023 Fargo Additive Manufacturing Equipment 3D, LLC.
// CuraLE is released under the terms of the LGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.15

import UM 1.2 as UM
import Cura 1.0 as Cura

Item {
    id: base

    height: childrenRect.height
    width: mainColumn.width //childrenRect.width
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

    ColumnLayout {
        id: mainColumn

        width: UM.Theme.getSize("setting_control").width * 3

        spacing: columnSpacing

        RowLayout {
            id: infoRow

            Layout.fillWidth: true
            Layout.maximumWidth: parent.width

            spacing: rowSpacing

            Label {
                id: infoLabel
                text: "Filament Change Info"
            }
        }

        RowLayout {
            id: controlsRow

            Layout.fillWidth: true
            Layout.maximumWidth: parent.width

            spacing: rowSpacing

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
                manager.writeSettingsToStack()
            }

            function removeUserInput() {
                let toRemove = getUserInput();
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
                manager.writeSettingsToStack()
            }

            function clearCurrentLayers() {
                provider.setPropertyValue("value", "")
                manager.writeSettingsToStack()
                return
            }

            TextField {
                id: layersTextField
                //Layout.preferredWidth: UM.Theme.getSize("setting_control").width
                Layout.fillWidth: true

                placeholderText: "Enter layers..."
                validator: RegExpValidator { regExp: /^\d[\d*\,*]*/ }

                onAccepted: controlsRow.addUserInput()

                style: UM.Theme.styles.text_field
            }

            Button {
                id: addButton
                Layout.preferredWidth: Math.round(UM.Theme.getSize("setting_control").width * .7)
                text: "Add"

                enabled: layersTextField.length > 0

                onClicked: controlsRow.addUserInput()

                style: UM.Theme.styles.toolbox_action_button
            }

            Button {
                id: removeButton
                Layout.preferredWidth: Math.round(UM.Theme.getSize("setting_control").width / 2)
                text: "Remove"

                enabled: layersTextField.length > 0

                onClicked: controlsRow.removeUserInput()

                style: UM.Theme.styles.toolbox_action_button
            }

            Button {
                id: clearButton
                Layout.preferredWidth: Math.round(UM.Theme.getSize("setting_control").width / 2)
                text: "Clear"

                enabled: changeLayerCount > 0

                onClicked: controlsRow.clearCurrentLayers()

                style: UM.Theme.styles.toolbox_action_button
            }
        }

        RowLayout {
            id: seperatorRow

            Layout.fillWidth: true
            Layout.maximumWidth: parent.width

            spacing: rowSpacing

            Rectangle {
                Layout.preferredHeight: UM.Theme.getSize("thick_lining").height
                Layout.fillWidth: true

                color: UM.Theme.getColor("lining")
            }
        }

        RowLayout {
            id: currentLayersRow

            Layout.fillWidth: true
            Layout.maximumWidth: parent.width

            spacing: rowSpacing

            Label {
                text: "Filament Change Layers:"
            }

            Label {
                id: currentLayersLabel

                Layout.fillWidth: true

                elide: Text.ElideRight
                wrapMode: Text.Wrap
                maximumLineCount: 3

                property string formatLayers: {
                    let val = provider.properties.value
                    if (val) {
                        return val.replace(/\,/g, ', ')
                    } else {
                        return "None"
                    }
                }

                text: {
                    formatLayers
                }

                MouseArea {
                    id: currentLayersMouseArea
                    anchors.fill: parent
                    hoverEnabled: true

                    Cura.ToolTip {
                        id: tooltip
                        width: UM.Theme.getSize("tooltip").width
                        tooltipText: currentLayersLabel.formatLayers
                        visible: parent.containsMouse && currentLayersLabel.truncated
                    }
                }
            }
        }
    }

    UM.SettingPropertyProvider {
        id: provider
        containerStackId: manager.currentStackId
        key: "layer_number"
        watchedProperties: [ "value" ]
        storeIndex: 0
    }
}
