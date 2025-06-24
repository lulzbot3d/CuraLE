// Copyright (c) 2022 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 2.3
import QtQuick.Layouts 6.6

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
        //layout.currentIndex = 0
    }
    property var goToPrinterType: () => {
        console.log("Tryin'")
        printersModel.level = 1
        //layout.currentIndex = 1
    }
    property var goToPrinterSubtype: () => {
        printersModel.level = 2
        //layout.currentIndex = 2
    }
    property var goToPrinterToolHead: () => {
        printersModel.level = 3
        //layout.currentIndex = 3
    }
    property var goToPrinterConditionals: () => {
        printersModel.level = 4
        //layout.currentIndex = 4
    }

    UM.Label
    {
        id: title_label
        Layout.alignment: Qt.AlignTop
        Layout.fillWidth: true
        Layout.bottomMargin: UM.Theme.getSize("thin_margin").height
        horizontalAlignment: Text.AlignHCenter
        text: catalog.i18nc("@label", "Add Printer")
        color: UM.Theme.getColor("primary_button")
        font: UM.Theme.getFont("huge")
    }

    UM.Label
    {
        text: catalog.i18nc("@label", "In order to start using Cura LulzBot Edition, you will need to configure a printer.")
        font: UM.Theme.getFont("default")
        Layout.alignment: Qt.AlignTop
    }

    Control
    {

        contentItem: ColumnLayout
        {
            Layout.fillWidth: true
            Layout.fillHeight: true

            GridLayout
            {
                columns: 3
                columnSpacing: UM.Theme.getSize("wide_margin").height
                rowSpacing: UM.Theme.getSize("wide_margin").width
                Layout.topMargin: UM.Theme.getSize("wide_margin").height
                Layout.bottomMargin: UM.Theme.getSize("wide_margin").height
                Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                uniformCellHeights: true
                uniformCellWidths: true

                Repeater
                {
                    id: categoryRepeater
                    model: printersModel
                    delegate: PrinterCard
                    {
                        Layout.row: Math.floor(index/3)
                        Layout.column: index % 3
                        Layout.alignment: Qt.AlignBottom
                        onClicked: {
                            selectCategory
                        }
                        text: catalog.i18nc("@button", name)
                        imageSource: UM.Theme.getImage("ultimaker_printer")

                        function selectCategory () {
                            console.log("Selected a category: " + name)
                            printerModel.machineCategory = name
                            printerModel.level = 1
                        }
                    }
                }
            }
        }
    }

    //StackLayout
    //{
        //id: layout
        //Layout.fillWidth: true
        //Layout.fillHeight: true
        //currentIndex: 0
        //PrinterCategory
        //{
            //printerModel: root.printersModel
            //goToPrinterType: root.goToPrinterType
        //}
        //PrinterType
        //{
            //printerModel: root.printersModel
            //goToPrinterCategory: root.goToPrinterCategory
            //goToPrinterSubtype: root.goToPrinterSubtype
            //goToPrinterToolHead: root.goToPrinterToolHead
        //}
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
    //}
}