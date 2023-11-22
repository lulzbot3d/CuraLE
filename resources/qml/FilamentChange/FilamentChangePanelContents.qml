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
    width: childrenRect.width
    property int columnSpacing: UM.Theme.getSize("default_margin").height
    property int rowSpacing: UM.Theme.getSize("default_margin").width
    UM.I18nCatalog { id: catalog; name: "uranium"}

    ColumnLayout {
        id: mainColumn

        spacing: columnSpacing

        RowLayout {
            id: infoRow

            spacing: rowSpacing

            Label {
                id: infoLabel
                text: "Filament Change Info"
            }
        }

        RowLayout {
            id: controlsRow

            spacing: rowSpacing

            TextField {
                id: layersTextField
                Layout.preferredWidth: UM.Theme.getSize("setting_control").width
                placeholderText: "Filament Change TextField"

                style: UM.Theme.styles.text_field
            }

            Button {
                id: addButton
                Layout.preferredWidth: Math.round(UM.Theme.getSize("setting_control").width / 2)
                text: "Add"

                onClicked: {
                    if (layersTextField.text) {
                        console.log("wow!")
                        layersTextField.text = ""
                    } else {
                        console.log("Dis bitch empty!!")
                    }
                }

                style: UM.Theme.styles.toolbox_action_button
            }

            Button {
                id: removeButton
                Layout.preferredWidth: Math.round(UM.Theme.getSize("setting_control").width / 2)
                text: "Remove"

                style: UM.Theme.styles.toolbox_action_button
            }
        }

        RowLayout {
            id: seperatorRow

            spacing: rowSpacing

            Rectangle {
                Layout.preferredHeight: UM.Theme.getSize("thick_lining").height
                Layout.fillWidth: true

                color: UM.Theme.getColor("lining")
            }
        }

        RowLayout {
            id: currentLayersRow

            spacing: rowSpacing

            Label {
                text: "Filament Change Layers:"
            }

            Label {
                text: {
                    let val = provider.value
                    if (val) {
                        return val
                    } else {
                        return "None"
                    }
                }
            }
        }
    }

    UM.SettingPropertyProvider {
        id: provider
        containerStackId: Cura.FilamentChangeManager.currentStackId
        key: "layer_number"
        watchedProperties: [ "value" ]
        storeIndex: 0
    }
}
