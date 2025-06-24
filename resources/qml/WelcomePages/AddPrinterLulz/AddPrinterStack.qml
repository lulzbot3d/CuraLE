// Copyright (c) 2022 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3

import UM 1.5 as UM
import Cura 1.1 as Cura

ColumnLayout
{
    id: root

    UM.I18nCatalog { id: catalog; name: "cura" }

    Layout.fillWidth: true
    Layout.fillHeight: true

    property var printersModel: Cura.LulzBotNewPrintersModel{ }

    // Stack navigation
    property var goToPrinterCategory: () => {
        printersModel.level = 0
        layout.currentIndex = 0
    }
    property var goToPrinterType: (pCat) => {
        console.log(pCat)
        printersModel.machineCategory = pCat
        printersModel.level = 1
        layout.currentIndex = 1
    }
    property var goToPrinterSubtype: (pCat, pType) => {
        printersModel.machineCategory = pCat
        printersModel.machineType = pType
        printersModel.level = 2
        layout.currentIndex = 2
    }
    property var goToPrinterToolHead: (pCat, pType, pSub) => {
        printersModel.machineCategory = pCat
        printersModel.machineType = pType
        printersModel.machineSubtype = pSub
        printersModel.level = 3
        layout.currentIndex = 3
    }
    property var goToPrinterConditionals: () => {
        printersModel.level = 4
        layout.currentIndex = 4
    }

    UM.Label
    {
        id: title_label
        Layout.fillWidth: true
        Layout.bottomMargin: UM.Theme.getSize("thick_margin").height
        horizontalAlignment: Text.AlignHCenter
        text: catalog.i18nc("@label", "Add Printer")
        color: UM.Theme.getColor("primary_button")
        font: UM.Theme.getFont("huge")
    }

    StackLayout
    {
        id: layout
        Layout.fillWidth: true
        Layout.fillHeight: true
        currentIndex: 0
        PrinterCategory
        {
            printerModel: root.printersModel
            goToPrinterType: root.goToPrinterType
        }
        PrinterType
        {
            printerModel: root.printersModel
            goToPrinterCategory: root.goToPrinterCategory
            //goToPrinterSubtype: root.goToPrinterSubtype
            //goToPrinterToolHead: root.goToPrinterToolHead
        }
        //PrinterSubtype
        //{
            //goToPrinterCategory: root.goToPrinterCategory
            //goToPrinterType: root.goToPrinterType
            //goToPrinterToolHead: root.goToPrinterToolHead
        //}
        //PrinterToolHead
        //{
            //goToPrinterCategory: root.goToPrinterCategory
            //goToPrinterOptions: root.goToPrinterOptions
        //}
        //PrinterOptions
        //{
            //goToPrinterCategory: root.goToPrinterCategory
            //goToPrinterType: root.goToPrinterType
            //goToPrinterSubtype: root.goToPrinterSubtype
            //goToPrinterToolHead: root.goToPrinterToolHead
        //}
        //AddCustomPrinter
        //{
            //goToAddPrinter: root.goToAddPrinter
        //}
    }
}