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

    property var printersModel: Cura.LulzBotPrintersModel{ }
    property int currentLevel: printersModel.level

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
        Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
    }

    ScrollView
    {
        Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
        Layout.fillHeight: true

        GridLayout
        {
            width: parent.width
            columns: 5
            columnSpacing: UM.Theme.getSize("default_margin").height
            rowSpacing: UM.Theme.getSize("default_margin").width
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: UM.Theme.getSize("default_margin").height
            Layout.bottomMargin: UM.Theme.getSize("default_margin").height
            uniformCellHeights: true
            uniformCellWidths: true

            Repeater
            {
                id: cardRepeater
                model: printersModel
                delegate: LulzPrinterCard
                {
                    onClicked: {
                        updateModel
                    }
                    text: catalog.i18nc("@button", name)
                    imageSource: UM.Theme.getImage(image)

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

    RowLayout
    {
        id: buttonRow
        Layout.alignment: Qt.AlignBottom

        Cura.SecondaryButton
        {
            id: restartButton
            enabled: currentLevel > 0
            text: catalog.i18nc("@button", "Restart")
            onClicked: {
                printersModel.level = 0
            }
        }

        Cura.SecondaryButton
        {
            id: backButton
            enabled: currentLevel > 0
            text: catalog.i18nc("@button", "Back")
            onClicked: {
                let backPage = printersModel.levelHistory
                printersModel.level = backPage
            }
        }
    }
}