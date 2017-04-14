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

    ListModel
    {
        id: categoriesModel
        Component.onCompleted:
        {
            categoriesModel.clear();
            for(var i = 0; i < Cura.MachineManager.categories.length; i++)
            {
                categoriesModel.append({
                    name: Cura.MachineManager.categories[i]
                });
            }
        }
    }

    ExclusiveGroup { id: group }
}
