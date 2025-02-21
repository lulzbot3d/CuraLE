// Copyright (c) 2022 Ultimaker B.V.
// Copyright (c) 2024 FAME3D LLC.
// Uranium is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Layouts 1.3
import QtQuick.Dialogs

import UM 1.2 as UM
import Cura 1.0 as Cura

Item
{
    id: materialList
    height: childrenRect.height

    // Children
    Cura.MaterialTypesModel
    {
        id: materialsModel
        extruderPosition: Cura.ExtruderManager.activeExtruderIndex
    }

    Cura.FavoriteMaterialsModel
    {
        id: favoriteMaterialsModel
        extruderPosition: Cura.ExtruderManager.activeExtruderIndex
    }

    property var currentType: null
    property var currentBrand: null
    property var expandedTypes: UM.Preferences.getValue("cura/expanded_types").split(";")
    property var expandedBrands: UM.Preferences.getValue("cura/expanded_brands").split(";")

    // Store information about which parts of the tree are expanded
    function persistExpandedCategories()
    {
        UM.Preferences.setValue("cura/expanded_types", materialList.expandedTypes.join(";"))
        UM.Preferences.setValue("cura/expanded_brands", materialList.expandedBrands.join(";"))
    }

    // Expand the list of materials in order to select the current material
    function expandActiveMaterial(search_root_id)
    {
        if (search_root_id == "")
        {
            // When this happens it means that the information of one of the materials has changed, so the model
            // was updated and the list has to highlight the current item.
            var currentItemId = base.currentItem == null ? "" : base.currentItem.root_material_id
            search_root_id = currentItemId
        }
        for (var type_idx = 0; type_idx < materialsModel.count; type_idx++)
        {
            var type = materialsModel.getItem(type_idx)
            var brands_model = type.brands
            for (var brand_idx = 0; brand_idx < brands_model.count; brand_idx++)
            {
                var brand = brands_model.getItem(brand_idx)
                var colors_model = brand.colors
                for (var material_idx = 0; material_idx < colors_model.count; material_idx++)
                {
                    var material = colors_model.getItem(material_idx)
                    if (material.root_material_id == search_root_id) {
                        if (materialList.expandedTypes.indexOf(type.name) == -1)
                        {
                            materialList.expandedTypes.push(type.name)
                        }
                        materialList.currentType = type.name
                        if (materialList.expandedBrands.indexOf(brand.name + "_" + type.name) == -1)
                        {
                            materialList.expandedBrands.push(brand.name + "_" + type.name)
                        }
                        materialList.currentType = brand.name + "_" + type.name
                        base.currentItem = material
                        persistExpandedCategories()
                        return true
                    }
                }
            }
        }
        base.currentItem = null
        return false
    }

    function updateAfterModelChanges()
    {
        var correctlyExpanded = materialList.expandActiveMaterial(base.newRootMaterialIdToSwitchTo)
        if (correctlyExpanded) {
            if (base.toActivateNewMaterial)
            {
                var position = Cura.ExtruderManager.activeExtruderIndex
                Cura.MachineManager.setMaterialById(position, base.newRootMaterialIdToSwitchTo)
            }
            base.newRootMaterialIdToSwitchTo = ""
            base.toActivateNewMaterial = false
        }
    }

    Connections
    {
        target: materialsModel
        function onItemsChanged() { updateAfterModelChanges() }
    }

    Column
    {
        width: materialList.width
        height: childrenRect.height

        LulzMaterialsTypeSection
        {
            id: favoriteSection
            sectionName: "Favorites"
            elementsModel: favoriteMaterialsModel
            hasMaterialBrands: false
        }

        Repeater
        {
            model: materialsModel
            delegate: LulzMaterialsTypeSection
            {
                id: typeSection
                sectionName: model.name
                elementsModel: model.brands
                hasMaterialBrands: true
            }
        }
    }
}