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

    // Stack navigation
    property var goToPrinterCategory: () => layout.currentIndex = 0
    property var goToPrinterType: () => layout.currentIndex = 1
    property var goToPrinterSubType: () => layout.currentIndex = 2
    property var goToPrinterConditionals: () => layout.currentIndex = 3
    property var goToPrinterToolHead: () => layout.currentIndex = 4

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
            goToPrinterType: root.goToPrinterType
        }
        PrinterType
        {
            goToPrinterCategory: root.goToPrinterCategory
            goToPrinterSubType: root.goToPrinterSubType
            goToPrinterConditionals: root.goToPrinterConditionals
            goToPrinterToolHead: root.goToPrinterToolHead
        }
        PrinterSubType
        {
            goToPrinterCategory: root.goToPrinterCategory
            goToPrinterType: root.goToPrinterType
            goToPrinterConditionals: root.goToPrinterConditionals
            goToPrinterToolHead: root.goToPrinterToolHead
        }
        PrinterConditionals
        {
            goToPrinterCategory: root.goToPrinterCategory
            goToPrinterType: root.goToPrinterType
            goToPrinterSubType: root.goToPrinterSubType
            goToPrinterToolHead: root.goToPrinterToolHead
        }
        PrinterToolHead
        {
            goToPrinterCategory: root.goToPrinterCategory
        }
        AddCustomPrinter
        {
            goToAddPrinter: root.goToAddPrinter
        }
    }
}