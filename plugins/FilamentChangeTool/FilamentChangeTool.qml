// Copyright (c) 2023 Fargo Additive Manufacturing Equipment 3D, LLC.
// CuraLE is released under the terms of the LGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.15

import UM 1.1 as UM
import Cura 1.0 as Cura

Item {
    id: base
    width: childrenRect.width
    height: childrenRect.height
    UM.I18nCatalog { id: catalog; name: "uranium"}

    property string quantity

    function selectTextInTextfield(selected_item) {
        selected_item.selectAll()
        selected_item.focus = true
    }
    GridLayout {

        columns: 2
        rows: 2
        columnSpacing: UM.Theme.getSize("default_margin").width
        rowSpacing: UM.Theme.getSize("default_margin").width

        Column {
            Label {
                text: "Filament Change"
            }
        }
    }


}
