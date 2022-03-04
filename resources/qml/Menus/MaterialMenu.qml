//Copyright (c) 2020 Ultimaker B.V.
//Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 1.4

import UM 1.2 as UM
import Cura 1.0 as Cura

Menu
{
    id: menu
    title: catalog.i18nc("@label:category menu label", "Material")

    property int extruderIndex: 0
    property bool printerConnected: Cura.MachineManager.printerOutputDevices.length != 0
    property bool isClusterPrinter:
    {
        var value = Cura.MachineManager.currentRootMaterialId[extruderIndex]
        return (value === undefined) ? "" : value
    }
    property var activeExtruder:
    {
        var activeMachine = Cura.MachineManager.activeMachine
        return (activeMachine === null) ? null : activeMachine.extruderList[extruderIndex]
    }
    property bool isActiveExtruderEnabled: (activeExtruder === null || activeExtruder === undefined) ? false : activeExtruder.isEnabled

    property string activeMaterialId: (activeExtruder === null || activeExtruder === undefined) ? false : activeExtruder.material.id

    property bool updateModels: true
    Cura.FavoriteMaterialsModel
    {
        id: favoriteMaterialsModel
        extruderPosition: menu.extruderIndex
        enabled: updateModels
    }

    Cura.GenericMaterialsModel
    {
        id: genericMaterialsModel
        extruderPosition: menu.extruderIndex
        enabled: updateModels
    }

    Cura.MaterialBrandsModel
    {
        id: brandModel
        extruderPosition: menu.extruderIndex
        enabled: updateModels
    }

    MenuItem
    {
        text: catalog.i18nc("@label:category menu label", "Favorites")
        enabled: false
        visible: favoriteMaterialsModel.items.length > 0
    }
    Instantiator
    {
        model: favoriteMaterialsModel
        delegate: MenuItem
        {
            text: model.brand + " " + model.name
            checkable: true
            enabled: isActiveExtruderEnabled
            checked: model.root_material_id === menu.currentRootMaterialId
            onTriggered: Cura.MachineManager.setMaterial(extruderIndex, model.container_node)
            exclusiveGroup: favoriteGroup  // One favorite and one item from the others can be active at the same time.
        }
        onObjectAdded: menu.insertItem(index, object)
        onObjectRemoved: menu.removeItem(index)
    }

    MenuSeparator {}

    Menu
    {
        id: genericMenu
        title: catalog.i18nc("@label:category menu label", "Generic")

        Instantiator
        {
            model: genericMaterialsModel
            delegate: MenuItem
            {
                text: model.name
                checkable: true
                enabled: isActiveExtruderEnabled
                checked: model.root_material_id === menu.currentRootMaterialId
                exclusiveGroup: group
                onTriggered: Cura.MachineManager.setMaterial(extruderIndex, model.container_node)
            }
            onObjectAdded: genericMenu.insertItem(index, object)
            onObjectRemoved: genericMenu.removeItem(index)
        }
        onObjectAdded: menu.insertItem(index, object)
        onObjectRemoved: menu.removeItem(object)
    }

    MenuSeparator {}

    Instantiator
    {
        model: brandModel
        Menu
        {
            id: brandMenu
            title: brandName
            property string brandName: model.name
            property var brandMaterials: model.material_types

            Instantiator
            {
                model: brandMaterials
                delegate: Menu
                {
                    id: brandMaterialsMenu
                    title: materialName
                    property string materialName: model.name
                    property var brandMaterialColors: model.colors

                    Instantiator
                    {
                        model: brandMaterialColors
                        delegate: MenuItem
                        {
                            text: model.name
                            checkable: true
                            enabled: isActiveExtruderEnabled
                            checked: model.id === menu.activeMaterialId
                            exclusiveGroup: group
                            onTriggered: Cura.MachineManager.setMaterial(extruderIndex, model.container_node)
                        }
                        onObjectAdded: brandMaterialsMenu.insertItem(index, object)
                        onObjectRemoved: brandMaterialsMenu.removeItem(object)
                    }
                }
                onObjectAdded: brandMenu.insertItem(index, object)
                onObjectRemoved: brandMenu.removeItem(object)
            }
        }
        onObjectAdded: menu.insertItem(index, object)
        onObjectRemoved: menu.removeItem(object)
    }

    ListModel
    {
        id: genericMaterialsModel
        Component.onCompleted: populateMenuModels()
    }

    ListModel
    {
        id: brandModel
    }

    //: Model used to populate the brandModel
    Cura.MaterialsModel
    {
        id: materialsModel
        filter: materialFilter()
        onModelReset: populateMenuModels()
        onDataChanged: populateMenuModels()
    }

    ExclusiveGroup { id: group }

    MenuSeparator { }

    MenuItem { action: Cura.Actions.manageMaterials }

    function materialFilter()
    {
        var result = { "type": "material", "approximate_diameter": Math.round(materialDiameterProvider.properties.value).toString() };
        if(Cura.MachineManager.filterMaterialsByMachine)
        {
            result.definition = Cura.MachineManager.activeQualityDefinitionId;
            if(Cura.MachineManager.hasVariants)
            {
                result.variant = Cura.MachineManager.activeQualityVariantId;
            }
        }
        else
        {
            result.definition = "fdmprinter";
            result.compatible = true; //NB: Only checks for compatibility in global version of material, but we don't have machine-specific materials anyway.
        }
        return result;
    }

    function populateMenuModels()
    {
        // Create a structure of unique brands and their material-types
        genericMaterialsModel.clear()
        brandModel.clear();

        var items = materialsModel.items;
        var materialsByBrand = {};
        for (var i in items) {
            var brandName = items[i]["metadata"]["brand"];
            var materialName = items[i]["metadata"]["material"];

            if (brandName == "Generic")
            {
                // Add to top section
                var materialId = items[i].id;
                genericMaterialsModel.append({
                    id: materialId,
                    name: items[i].name
                });
            }
            else
            {
                // Add to per-brand, per-material menu
                if (!materialsByBrand.hasOwnProperty(brandName))
                {
                    materialsByBrand[brandName] = {};
                }
                if (!materialsByBrand[brandName].hasOwnProperty(materialName))
                {
                    materialsByBrand[brandName][materialName] = [];
                }
                materialsByBrand[brandName][materialName].push({
                    id: items[i].id,
                    name: items[i].name
                });
            }
        }

        for (var brand in materialsByBrand)
        {
            var materialsByBrandModel = [];
            var materials = materialsByBrand[brand];
            for (var material in materials)
            {
                materialsByBrandModel.push({
                    name: material,
                    colors: materials[material]
                })
            }
            brandModel.append({
                name: brand,
                materials: materialsByBrandModel
            });
        }
    }
}
