// Copyright (c) 2022 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 2.4

import UM 1.5 as UM
import Cura 1.0 as Cura

Cura.Menu
{
    id: materialMenu
    title: catalog.i18nc("@label:category menu label", "Material")

    property int extruderIndex: 0
    property string currentRootMaterialId:
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

    property string activeMaterialId: (activeExtruder === null || activeExtruder === undefined) ? "" : activeExtruder.material.id
    property bool updateModels: true
    Cura.FavoriteMaterialsModel
    {
        id: favoriteMaterialsModel
        extruderPosition: materialMenu.extruderIndex
        enabled: updateModels
    }

    Cura.MaterialTypesModel
    {
        id: typeModel
        extruderPosition: materialMenu.extruderIndex
        enabled: updateModels
    }

    Cura.MenuItem
    {
        text: catalog.i18nc("@label:category menu label", "Favorites")
        enabled: false
        visible: favoriteMaterialsModel.items.length > 0
    }

    Instantiator
    {
        model: favoriteMaterialsModel
        delegate: Cura.MenuItem
        {
            text: model.brand + " " + model.name
            checkable: true
            enabled: isActiveExtruderEnabled
            checked: model.root_material_id === materialMenu.currentRootMaterialId
            onTriggered: Cura.MachineManager.setMaterial(extruderIndex, model.container_node)
        }
        onObjectAdded: function(index, object) { materialMenu.insertItem(index + 1, object) }
        onObjectRemoved: function(index, object) { materialMenu.removeItem(index) }
    }

    Cura.MenuSeparator { visible: favoriteMaterialsModel.items.length > 0}

    Instantiator
    {
        model: typeModel
        Cura.Menu
        {
            id: typeMenu
            title: typeName
            property string typeName: model.name
            property var typeBrands: model.brands

            Instantiator
            {
                model: typeBrands
                delegate: Cura.Menu
                {
                    id: typeBrandsMenu
                    title: brandName
                    property string brandName: model.name
                    property var brandMaterialColors: model.colors

                    Instantiator
                    {
                        model: brandMaterialColors
                        delegate: Cura.MenuItem
                        {
                            text: model.name
                            checkable: true
                            enabled: isActiveExtruderEnabled
                            checked: model.id === materialMenu.activeMaterialId
                            onTriggered: Cura.MachineManager.setMaterial(extruderIndex, model.container_node)
                        }
                        onObjectAdded: function(index, object) { typeBrandsMenu.insertItem(index, object) }
                        onObjectRemoved: function(index, object) { typeBrandsMenu.removeItem(index) }
                    }
                }
                onObjectAdded: function(index, menu) { typeMenu.insertMenu(index, menu) }
                onObjectRemoved: function(index, menu) { typeMenu.removeMenu(menu) }
            }
        }
        onObjectAdded: function(index, menu) { materialMenu.insertMenu(index, menu) }
        onObjectRemoved: function(index, menu) { materialMenu.removeMenu(menu) }

    }

    Cura.MenuSeparator {}

    Cura.MenuItem
    {
        action: Cura.Actions.manageMaterials
    }

    // Cura.MenuSeparator {}

    // Cura.MenuItem
    // {
    //     action: Cura.Actions.marketplaceMaterials
    // }
}
