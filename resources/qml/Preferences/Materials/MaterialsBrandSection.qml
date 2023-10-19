// Copyright (c) 2018 Ultimaker B.V.
// Uranium is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.2

import UM 1.2 as UM
import Cura 1.0 as Cura

Item {
    id: material_brand_section
    property var materialBrand

    property string materialType: materialBrand != null ? materialBrand.type: ""
    property string brandName: materialBrand != null ? materialBrand.name : ""
    property var expanded: materialList.expandedBrands.indexOf(brandName + "_" + materialType) > -1
    property var colorsModel: materialBrand != null ? materialBrand.colors: null
    height: childrenRect.height
    width: parent ? parent.width :undefined
    anchors.left: parent ? parent.left : undefined

    Rectangle {
        id: material_brand_header_background
        color: {
            if(!expanded && brandName + "_" + materialType == materialList.currentType) {
                return palette.highlight
            }
            else {
                return palette.mid
            }
        }
        width: parent.width
        height: material_brand_header.height
    }
    Rectangle {
        id: material_brand_header_border
        color: UM.Theme.getColor("favorites_header_bar")
        anchors.bottom: material_brand_header.bottom
        anchors.left: material_brand_header.left
        height: UM.Theme.getSize("default_lining").height
        width: material_brand_header.width
    }

    Row {
        id: material_brand_header
        width: parent.width
        leftPadding: UM.Theme.getSize("default_margin").width
        anchors
        {
            left: parent ? parent.left : undefined
        }
        Label {
            text: brandName
            height: UM.Theme.getSize("favorites_row").height
            width: parent.width - parent.leftPadding - UM.Theme.getSize("favorites_button").width
            id: material_brand_name
            verticalAlignment: Text.AlignVCenter
        }
        Item { // this one causes lots of warnings
            implicitWidth: UM.Theme.getSize("favorites_button").width
            implicitHeight: UM.Theme.getSize("favorites_button").height
            UM.RecolorImage {
                anchors
                {
                    verticalCenter: parent ? parent.verticalCenter : undefined
                    horizontalCenter: parent ? parent.horizontalCenter : undefined
                }
                width: UM.Theme.getSize("standard_arrow").width
                height: UM.Theme.getSize("standard_arrow").height
                color: "black"
                source: material_brand_section.expanded ? UM.Theme.getIcon("ChevronSingleDown") : UM.Theme.getIcon("ChevronSingleLeft")
            }

        }
    }
    MouseArea { // causes lots of warnings
        anchors.fill: material_brand_header
        onPressed: {
            const identifier = brandName + "_" + materialType;
            const i = materialList.expandedBrands.indexOf(identifier)
            if (i > -1) {
                // Remove it
                materialList.expandedBrands.splice(i, 1)
                material_brand_section.expanded = false
            }
            else {
                // Add it
                materialList.expandedBrands.push(identifier)
                material_brand_section.expanded = true
            }
            UM.Preferences.setValue("cura/expanded_brands", materialList.expandedBrands.join(";"));
        }
    }

    Column {
        height: {
            if (!visible) {
                return 0
            }
        }
        visible: material_brand_section.expanded
        width: parent.width
        anchors.top: material_brand_header.bottom

        Repeater {
            model: colorsModel
            delegate: MaterialsSlot {
                material: model
            }
        }
    }

    Connections {
        target: UM.Preferences
        function onPreferenceChanged(preference) {
            if (preference !== "cura/expanded_types" && preference !== "cura/expanded_brands") {
                return;
            }

            expanded = materialList.expandedBrands.indexOf(brandName + "_" + materialType) > -1
        }
    }
}