// Copyright (c) 2022 Ultimaker B.V.
// Copyright (c) 2024 FAME3D LLC.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.3

import UM 1.5 as UM
import Cura 1.0 as Cura

// An expandable list of materials. Includes both the header (this file) and the items (typeMaterialList)

Column
{
    id: type_section

    property var sectionName: ""
    property var elementsModel   // This can be a MaterialTypesModel or GenericMaterialsModel or FavoriteMaterialsModel
    property var hasMaterialBrands: true  // It indicates whether it has brands or not
    property bool expanded: materialList.expandedTypes.indexOf(sectionName) !== -1
    width: parent.width

    Cura.CategoryButton
    {
        width: parent.width
        labelText: sectionName
        height: UM.Theme.getSize("preferences_page_list_item").height
        labelFont: UM.Theme.getFont("default_bold")
        expanded: type_section.expanded
        onClicked:
        {
            const i = materialList.expandedTypes.indexOf(sectionName);
            if (i !== -1)
            {
                materialList.expandedTypes.splice(i, 1); // remove
            }
            else
            {
                materialList.expandedTypes.push(sectionName); // add
            }
            UM.Preferences.setValue("cura/expanded_types", materialList.expandedTypes.join(";"));
        }
    }

    Column
    {
        id: typeMaterialList
        width: parent.width
        visible: type_section.expanded

        Repeater
        {
            model: elementsModel

            delegate: Loader
            {
                width: parent ? parent.width : 0
                property var element: model
                sourceComponent: hasMaterialBrands ? materialsBrandSection : materialSlot
            }
        }
    }

    Component
    {
        id: materialsBrandSection
        LulzMaterialsBrandSection
        {
            materialBrand: element
            indented: true
        }
    }

    Component
    {
        id: materialSlot
        LulzMaterialsSlot
        {
            material: element
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

            type_section.expanded = materialList.expandedTypes.indexOf(sectionName) > -1
        }
    }
}
