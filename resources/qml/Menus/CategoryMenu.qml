import QtQuick 2.2
import QtQuick.Controls 1.1

import UM 1.2 as UM
import Cura 1.0 as Cura

Menu
{
    id: menu
    title: "Category"

    property string category: Cura.MachineManager.currentCategory

    Instantiator
    {
        model: categoriesModel
        MenuItem
        {
            text: model.name
            checkable: true;
            checked: model.name == Cura.MachineManager.currentCategory;
            exclusiveGroup: group;
            onTriggered:
            {
                Cura.MachineManager.setCurrentCategory(model.name);
            }
        }
        onObjectAdded: menu.insertItem(index, object)
        onObjectRemoved: menu.removeItem(object)
    }

    function resetModel()
    {
        categoriesModel.clear();
        var categories = Cura.MachineManager.categories
        for(var i = 0; i < categories.length; i++)
        {
            categoriesModel.append({
                name: categories[i]
            });
        }
        Cura.MachineManager.setCurrentCategory(Cura.MachineManager.defaultCategory);
    }

    ListModel
    {
        id: categoriesModel
        Component.onCompleted: resetModel()
    }

    Connections
    {
        target: Cura.MachineManager
        onGlobalContainerChanged: resetModel()
    }

    ExclusiveGroup { id: group }
}
