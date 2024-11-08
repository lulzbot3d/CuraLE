// Copyright (c) 2022 Ultimaker B.V.
// Copyright (c) 2024 FAME3D LLC.
// Uranium is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3

import UM 1.5 as UM
import Cura 1.0 as Cura

Column
{
    id: material_brand_section
    property var materialBrand: null
    property string materialType: materialBrand !== null ? materialBrand.type: ""
    property string brandName: materialBrand !== null ? materialBrand.name : ""
    property bool expanded: materialList.expandedBrands.indexOf(`${brandName}_${materialType}`) !== -1
    property var colorsModel: materialBrand != null ? materialBrand.colors: null
    property alias indented: categoryButton.indented
    width: parent ? parent.width : 0

    Cura.CategoryButton
    {
        id: categoryButton
        width: parent.width
        height: UM.Theme.getSize("preferences_page_list_item").height
        labelText: brandName
        labelFont: UM.Theme.getFont("default")
        expanded: material_brand_section.expanded
        onClicked:
        {
            const identifier = `${brandName}_${materialType}`;
            const i = materialList.expandedBrands.indexOf(identifier);
            if (i !== -1)
            {
                materialList.expandedBrands.splice(i, 1); // remove
            }
            else
            {
                materialList.expandedBrands.push(identifier); // add
            }
            UM.Preferences.setValue("cura/expanded_brands", materialList.expandedBrands.join(";"));
        }
    }

    Column
    {
        visible: material_brand_section.expanded
        width: parent.width

        Repeater
        {
            model: colorsModel
            delegate: LulzMaterialsSlot
            {
                material: model
            }
        }
    }

    Connections
    {
        target: UM.Preferences
        function onPreferenceChanged(preference)
        {
            if (preference !== "cura/expanded_types" && preference !== "cura/expanded_brands")
            {
                return;
            }

            material_brand_section.expanded = materialList.expandedBrands.indexOf(`${brandName}_${materialType}`) !== -1;
        }
    }
}