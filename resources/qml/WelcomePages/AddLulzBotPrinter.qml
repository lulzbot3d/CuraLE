// Copyright (c) 2022 UltiMaker
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3

import UM 1.5 as UM
import Cura 1.1 as Cura

Control
{
    UM.I18nCatalog { id: catalog; name: "cura" }

    property var goToCustomPrinter

    contentItem: ColumnLayout
    {
        Layout.fillWidth: true
        UM.Label
        {
            Layout.fillWidth: true
            text: catalog.i18nc("@label", "Add LulzBot Printers")
            wrapMode: Text.WordWrap
        }

        RowLayout
        {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true

            Item
            {
                Layout.fillWidth: true
                Layout.minimumWidth: childrenRect.width
                Layout.preferredHeight: childrenRect.height

                Image
                {
                    anchors.right: parent.right
                    source: UM.Theme.getImage("add_printer")
                    Layout.preferredWidth: 200 * screenScaleFactor
                    Layout.preferredHeight: 200 * screenScaleFactor
                }
            }

            ColumnLayout
            {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: UM.Theme.getSize("default_margin").height

                UM.Label
                {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    wrapMode: Text.WordWrap
                    font: UM.Theme.getFont("default_bold")
                    text: catalog.i18nc("@label", "If you are trying to add a new LulzBot printer to Cura LulzBot Edition")
                }

                Cura.TertiaryButton
                {
                    id: learnMoreButton
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    leftPadding: 0
                    text: catalog.i18nc("@button", "Learn more")
                    iconSource: UM.Theme.getIcon("LinkExternal")
                    isIconOnRightSide: true
                    textFont: UM.Theme.getFont("small")
                    onClicked: Qt.openUrlExternally("https://lulzbot.com/")
                }
            }
        }

        Control
        {
            Layout.alignment: Qt.AlignBottom
            Layout.fillWidth: true

            contentItem: RowLayout
            {

                Cura.SecondaryButton
                {
                    id: addLocalPrinterButton
                    Layout.alignment: Qt.AlignLeft
                    text: catalog.i18nc("@button", "Add Custom printer")
                    onClicked: goToCustomPrinter()
                }

                Cura.PrimaryButton
                {
                    id: signInButton
                    Layout.alignment: Qt.AlignRight
                    text: catalog.i18nc("@button", "Sign in to Digital Factory")
                    onClicked: function()
                    {
                        Qt.openUrlExternally("https://lulzbot.com/")
                        text = catalog.i18nc("@button", "LulzBot Website :)")
                        busy = true;
                        enabled = false;
                    }
                }
            }
        }
    }
}
