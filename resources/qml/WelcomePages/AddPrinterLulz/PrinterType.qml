// Copyright (c) 2022 UltiMaker
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 2.3
import QtQuick.Layouts 6.6

import UM 1.5 as UM
import Cura 1.1 as Cura


//
// This component contains the content for the "Add a printer" (network) page of the welcome on-boarding process.
//
Control
{
    UM.I18nCatalog { id: catalog; name: "cura" }

    property alias printerModel: printerTypeRepeater.model
    property var goToPrinterCategory
    property var goToPrinterSubtype

    contentItem: ColumnLayout
    {
        Layout.fillWidth: true
        Layout.fillHeight: true

        UM.Label
        {
            text: catalog.i18nc("@label", "What type of printer would you like to setup?")
            font: UM.Theme.getFont("default_bold")
            Layout.alignment: Qt.AlignTop
        }

        GridLayout
        {
            columns: 3
            columnSpacing: UM.Theme.getSize("wide_margin").height
            rows: 2
            rowSpacing: UM.Theme.getSize("wide_margin").width
            Layout.topMargin: UM.Theme.getSize("wide_margin").height
            Layout.bottomMargin: UM.Theme.getSize("wide_margin").height
            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
            uniformCellHeights: true
            uniformCellWidths: true

            Repeater 
            {
                id: printerTypeRepeater
                PrinterCard
                {
                    Layout.row: Math.floor(index/3)
                    Layout.column: index % 3
                    Layout.alignment: Qt.AlignBottom
                    onClicked: {
                        model.level = 1
                        goToPrinterCategory
                    }
                    text: catalog.i18nc("@button", name)
                    imageSource: UM.Theme.getImage("ultimaker_printer")
                }
            }
        }
    }
}