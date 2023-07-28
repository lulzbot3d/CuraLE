// Copyright (c) 2023 Fargo Additive Manufacturing Equipment 3D, LLC.
// CuraLE is released under the terms of the LGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.15

import UM 1.1 as UM

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

        Label {
            id: quantityLabel

            Layout.column: 0
            Layout.row: 0
            height: UM.Theme.getSize("setting_control").height
            text: "Quantity";
        }

        SpinBox {
            id: quantityTextField

            Layout.column: 1
            Layout.row: 0

            width: UM.Theme.getSize("setting_control").width;
            height: UM.Theme.getSize("setting_control").height;

            minimumValue: 1
            maximumValue: 99
        }

        Button {
            id: multiplyButton

            Layout.columnSpan: 2
            Layout.fillWidth: true
            Layout.row: 1

            text: catalog.i18nc("@action:button","Multiply")
            property bool needBorder: true

            onClicked: CuraActions.multiplySelection(quantityTextField.value)
        }
    }


}
