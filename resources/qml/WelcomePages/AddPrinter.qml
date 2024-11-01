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

            PrinterCard
            {
                id: tazPrinterCard
                Layout.row: 0
                Layout.column: 0
                Layout.alignment: Qt.AlignBottom
                onClicked: goToLulzBotPrinter
                text: catalog.i18nc("@button", "TAZ")
                imageSource: UM.Theme.getImage("ultimaker_printer")
            }

            PrinterCard
            {
                id: workhorsePrinterCard
                Layout.row: 0
                Layout.column: 1
                Layout.alignment: Qt.AlignBottom
                onClicked: goToLulzBotPrinter;
                text: catalog.i18nc("@button", "Workhorse")
                imageSource: UM.Theme.getImage("ultimaker_printer")
            }

            PrinterCard
            {
                id: miniPrinterCard
                Layout.row: 0
                Layout.column: 2
                Layout.alignment: Qt.AlignBottom
                onClicked:goToLulzBotPrinter;
                text: catalog.i18nc("@button", "Mini")
                imageSource: UM.Theme.getImage("ultimaker_printer")
            }

            PrinterCard
            {
                id: sidekickPrinterCard
                Layout.row: 1
                Layout.column: 0
                Layout.alignment: Qt.AlignBottom
                onClicked: goToLulzBotPrinter
                text: catalog.i18nc("@button", "SideKick")
                imageSource: UM.Theme.getImage("ultimaker_printer")
            }

            PrinterCard
            {
                id: otherPrinterCard
                Layout.row: 1
                Layout.column: 1
                Layout.alignment: Qt.AlignBottom
                onClicked: goToOtherPrinter
                text: catalog.i18nc("@button", "Other")
                imageSource: UM.Theme.getImage("ultimaker_printer")
            }

            PrinterCard
            {
                id: customPrinterCard
                Layout.row: 1
                Layout.column: 2
                Layout.alignment: Qt.AlignBottom
                onClicked: goToCustomPrinter
                text: catalog.i18nc("@button", "Custom")
                imageSource: UM.Theme.getImage("third_party_printer")
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