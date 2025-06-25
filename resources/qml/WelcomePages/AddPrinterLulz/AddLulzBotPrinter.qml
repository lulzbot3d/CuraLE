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
    property int currentLevel: printersModel.level
    property list<int> previousLevels

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
                    id: cardRepeater
                    model: printersModel
                    delegate: PrinterCard
                    {
                        Layout.row: Math.floor(index/3)
                        Layout.column: index % 3
                        Layout.alignment: Qt.AlignBottom
                        onClicked: {
                            updateModel
                        }
                        text: catalog.i18nc("@button", name)
                        imageSource: UM.Theme.getImage("ultimaker_printer")

                        function updateModel () {
                            switch (currentLevel) {
                                case 0:
                                    printersModel.machineCategory = name;
                                    printersModel.level = 1;
                                    break;
                                case 1:
                                    printersModel.machineType = name;
                                    if (has_subtypes == false) {
                                        printersModel.level = 3;
                                    } else {
                                        printersModel.level = 2;
                                    }
                                    break;
                                case 2:
                                    printersModel.machineSubtype = subtype;
                                    printersModel.level = 3;
                                    break;
                                case 3:
                                    printersModel.machineId = id
                                    printersModel.level = 4;
                                    break;
                                case 4:
                                    break;
                                default:
                                    console.log("Unknown level state! Reverting...");
                                    printersModel.level = 0;
                                    break;
                            }
                        }
                    }
                }
            }
        }
    }

    RowLayout
    {
        id: buttonRow
        Layout.alignment: Qt.AlignBottom

        Cura.SecondaryButton
        {
            id: restartButton
            visible: currentLevel > 0
            text: catalog.i18nc("@button", "Restart")
            onClicked: {
                printersModel.level = 0
            }
        }

        Cura.SecondaryButton
        {
            id: backButton
            visible: currentLevel > 0
            text: catalog.i18nc("@button", "Back")
            onClicked: {
                let backPage = printersModel.levelHistory
                printersModel.level = backPage
            }
        }
    }
}