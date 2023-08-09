// Copyright (c) 2019 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.2

import UM 1.2 as UM
import Cura 1.0 as Cura

// An expandable list of materials. Includes both the header (this file) and the items (typeMaterialList)

Item {
    id: type_section

    property var sectionName: ""
    property var materialIndex
    property var elementsModel   // This can be a MaterialTypesModel or GenericMaterialsModel or FavoriteMaterialsModel
    property var hasMaterialBrands: true  // It indicates whether it has brands or not
    property var expanded: materialList.expandedTypes.indexOf(sectionName) > -1

    height: childrenRect.height
    width: parent.width

    Rectangle {
        id: type_header_background
        color: {
            if(!expanded && sectionName == materialList.currentType) {
                return palette.highlight
            }
            else if (materialIndex % 2) {
                return palette.light
        }
        anchors.fill: type_header
    }

    Row {
        id: type_header
        width: parent.width
        Label {
            id: type_name
            text: sectionName
            height: UM.Theme.getSize("favorites_row").height
            width: parent.width - UM.Theme.getSize("favorites_button").width
            verticalAlignment: Text.AlignVCenter
            leftPadding: (UM.Theme.getSize("default_margin").width / 2) | 0
        }
        Item {
            implicitWidth: UM.Theme.getSize("favorites_button").width
            implicitHeight: UM.Theme.getSize("favorites_button").height
            UM.RecolorImage {
                anchors {
                    verticalCenter: parent.verticalCenter
                    horizontalCenter: parent.horizontalCenter
                }
                width: UM.Theme.getSize("standard_arrow").width
                height: UM.Theme.getSize("standard_arrow").height
                color: "black"
                source: type_section.expanded ? UM.Theme.getIcon("ChevronSingleDown") : UM.Theme.getIcon("ChevronSingleLeft")
            }
        }
    }

    MouseArea {
        anchors.fill: type_header
        onPressed: {
            const i = materialList.expandedTypes.indexOf(sectionName)
            if (i > -1) {
                // Remove it
                materialList.expandedTypes.splice(i, 1)
                type_section.expanded = false
            }
            else {
                // Add it
                materialList.expandedTypes.push(sectionName)
                type_section.expanded = true
            }
            UM.Preferences.setValue("cura/expanded_types", materialList.expandedTypes.join(";"));
        }
    }

    Column {
        id: brandMaterialList
        anchors.top: type_header.bottom
        width: parent.width
        anchors.left: parent ? parent.left : undefined
        height: type_section.expanded ? childrenRect.height : 0
        visible: type_section.expanded

        Repeater {
            model: elementsModel
            delegate: Loader {
                id: loader
                width: parent ? parent.width : 0
                property var element: model
                sourceComponent: hasMaterialBrands ? materialsBrandSection : materialSlot
            }
        }
    }

    Component {
        id: materialsBrandSection
        MaterialsBrandSection {
            materialBrand: element
        }
    }

    Component {
        id: materialSlot
        MaterialsSlot {
            material: element
        }
    }

    Connections {
        target: UM.Preferences
        function onPreferenceChanged(preference) {
            if (preference !== "cura/expanded_types" && preference !== "cura/expanded_brands") {
                return;
            }
            expanded = materialList.expandedTypes.indexOf(sectionName) > -1
        }
    }
}
