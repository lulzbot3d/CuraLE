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

    property var updateLulzBotCategory
    property var goToLulzBotPrinter
    property var goToOtherPrinter
    property var goToCustomPrinter

    contentItem: ColumnLayout
    {
        Layout.fillWidth: true
        Layout.fillHeight: true

        UM.Label
        {
            text: catalog.i18nc("@label", "In order to start using Cura LulzBot Edition, you will need to configure a printer.")
            font: UM.Theme.getFont("default")
            Layout.alignment: Qt.AlignTop
        }

        UM.Label
        {
            text: catalog.i18nc("@label", "What printer would you like to setup?")
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
                model: Cura.LulzBotNewPrintersModel {
                    id: lulzPrinterModel
                }
                PrinterCard
                {
                    Layout.row: Math.floor(index/3)
                    Layout.column: index % 3
                    Layout.alignment: Qt.AlignBottom
                    onClicked: {
                        lulzPrinterModel.setMachineCategoryProperty(lulzPrinterModel.name)
                        lulzPrinterModel.setLevelProperty("1")
                        goToLulzBotPrinter
                    }
                    text: catalog.i18nc("@button", modelData.name)
                    imageSource: UM.Theme.getImage("ultimaker_printer")
                }
            }
        }

        Cura.TertiaryButton
        {
            id: learnMoreButton
            Layout.alignment: Qt.AlignBottom
            text: catalog.i18nc("@button", "Learn more about adding printers to CuraLE")
            iconSource: UM.Theme.getIcon("LinkExternal")
            isIconOnRightSide: true
            textFont: UM.Theme.getFont("small")
            onClicked: Qt.openUrlExternally("https://lulzbot.com/")
        }
    }
}