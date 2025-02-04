// Copyright (c) 2023 Fargo Additive Manufacturing Equipment 3D, LLC.
// CuraLE is released under the terms of the LGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.15

import UM 1.5 as UM
import Cura 1.0 as Cura

Item
{
    id: base
    width: childrenRect.width
    height: childrenRect.height
    UM.I18nCatalog { id: catalog; name: "uranium"}

    property string quantity

    function selectTextInTextfield(selected_item)
    {
        selected_item.selectAll()
        selected_item.focus = true
    }

    GridLayout
    {
        columns: 2
        rows: 2
        columnSpacing: UM.Theme.getSize("default_margin").width
        rowSpacing: UM.Theme.getSize("default_margin").width

        UM.Label
        {
            id: quantityLabel

            Layout.column: 0
            Layout.row: 0
            height: UM.Theme.getSize("setting").height
            text: "Quantity";
        }

        SpinBox
        {
            id: quantityTextField

            Layout.column: 1
            Layout.row: 0

            width: UM.Theme.getSize("setting_control").width;
            height: UM.Theme.getSize("setting_control").height;

            from: 1
            to: 99
        }

        Cura.SecondaryButton
        {
            id: multiplyButton

            Layout.columnSpan: 2
            Layout.fillWidth: true
            Layout.row: 1

            text: catalog.i18nc("@action:label","Multiply")
            onClicked: CuraActions.multiplySelection(quantityTextField.value)
        }
    }
}
