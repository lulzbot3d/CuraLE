//Copyright (c) 2020 Ultimaker B.V.
//Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 1.4

import UM 1.2 as UM
import Cura 1.0 as Cura

Menu {
    id: menu
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

    property string activeMaterialId: (activeExtruder === null || activeExtruder === undefined) ? false : activeExtruder.material.id

    property bool updateModels: true
    Cura.FavoriteMaterialsModel {
        id: favoriteMaterialsModel
        extruderPosition: menu.extruderIndex
        enabled: updateModels
    }

    Cura.GenericMaterialsModel {
        id: genericMaterialsModel
        extruderPosition: menu.extruderIndex
        enabled: updateModels
    }

    Cura.MaterialTypesModel {
        id: typesModel
        extruderPosition: menu.extruderIndex
        enabled: updateModels
    }

    MenuItem {
        text: catalog.i18nc("@label:category menu label", "Favorites")
        enabled: false
        visible: favoriteMaterialsModel.items.length > 0
    }

    Instantiator {
        model: favoriteMaterialsModel
        delegate: MenuItem {
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

    Menu {
        id: genericMenu
        title: catalog.i18nc("@label:category menu label", "Generic")

        Instantiator {
            model: genericMaterialsModel
            delegate: MenuItem {
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
    }

    MenuSeparator {}

    Instantiator {
        model: typesModel
        Menu {
            id: typeMenu
            title: typeName
            property string typeName: model.name
            property var typeBrands: model.brands

            Instantiator {
                model: typeBrands
                delegate: Menu {
                    id: typeBrandsMenu
                    title: brandName
                    property string brandName: model.name
                    property var brandMaterialColors: model.colors

                    Instantiator {
                        model: brandMaterialColors
                        delegate: MenuItem {
                            text: model.name
                            checkable: true
                            enabled: isActiveExtruderEnabled
                            checked: model.id === menu.activeMaterialId
                            exclusiveGroup: group
                            onTriggered: Cura.MachineManager.setMaterial(extruderIndex, model.container_node)
                        }
                        onObjectAdded: typeBrandsMenu.insertItem(index, object)
                        onObjectRemoved: typeBrandsMenu.removeItem(object)
                    }
                }
                onObjectAdded: typeMenu.insertItem(index, object)
                onObjectRemoved: typeMenu.removeItem(object)
            }
        }
        onObjectAdded: menu.insertItem(index, object)
        onObjectRemoved: menu.removeItem(object)
    }

    ExclusiveGroup {
        id: group
    }

    ExclusiveGroup {
        id: favoriteGroup
    }

    MenuSeparator {}

    MenuItem {
        action: Cura.Actions.manageMaterials
    }
}