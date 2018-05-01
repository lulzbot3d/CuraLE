// Copyright (c) 2016 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import QtQuick.Window 2.1
import QtQuick.Dialogs 1.2 // For filedialog

import UM 1.2 as UM
import Cura 1.0 as Cura


Cura.MachineAction
{
    anchors.fill: parent;

    Item
    {
        id: upgradeFirmwareMachineAction
        anchors.fill: parent
        UM.I18nCatalog { id: catalog; name:"cura"}

        Label
        {
            id: pageTitle
            width: parent.width
            text: catalog.i18nc("@title", "Upgrade Firmware")
            wrapMode: Text.WordWrap
            font.pointSize: 18
        }
        Label
        {
            id: pageDescription
            anchors.top: pageTitle.bottom
            anchors.topMargin: UM.Theme.getSize("default_margin").height
            width: parent.width
            wrapMode: Text.WordWrap
            text: catalog.i18nc("@label", "Firmware is the piece of software running directly on your 3D printer. This firmware controls the stepper motors, regulates the temperature, and ultimately makes your printer work.")
        }

        Label {
            id: upgradeText1
            anchors.top: pageDescription.bottom
            anchors.topMargin: UM.Theme.getSize("default_margin").height
            width: parent.width
            wrapMode: Text.WordWrap
            text: catalog.i18nc("@label", "The firmware shipping with new printers works, but new versions tend to have more features and improvements.")
        }
        Label {
            id: upgradeText2
            anchors.top: upgradeText1.bottom
            anchors.topMargin: UM.Theme.getSize("default_margin").height
            width: parent.width
            wrapMode: Text.WordWrap
            text: catalog.i18nc("@label", "
                <b>WARNING</b>: Firmware upgrading process might overwrite your tuned parameters with default values.<br>
                Please have the following recorded <u>before</u> upgrading firmware:
                <ul type=\"bullet\">
                    <li>Extruder Steps per unit
                        (<a href='https://www.lulzbot.com/learn/tutorials/firmware-flashing-through-cura#get-esteps'>E-steps</a>)
                    <li>Z-axis offset
                        (<a href='https://www.lulzbot.com/learn/tutorials/Z-axis-offset#get-offset'>Z-offset</a>)
                </ul>
                You will need to restore
                <a href='https://www.lulzbot.com/learn/tutorials/firmware-flashing-through-cura#esteps'>E-steps</a> and
                <a href='https://www.lulzbot.com/learn/tutorials/Z-axis-offset#restore-offset'>Z-offset</a> after firmware upgrade.
                ")
            onLinkActivated: Qt.openUrlExternally(link)
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton // we don't want to eat clicks on the Text
                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }
        Row
        {
            id: buttonRow
            anchors.top: upgradeText2.bottom
            anchors.topMargin: UM.Theme.getSize("default_margin").height
            anchors.horizontalCenter: parent.horizontalCenter
            width: childrenRect.width
            spacing: UM.Theme.getSize("default_margin").width
            property var firmwareName: Cura.USBPrinterManager.getDefaultFirmwareName()
            Button
            {
                id: autoUpgradeButton
                text: catalog.i18nc("@action:button", "Automatically upgrade Firmware");
                enabled: parent.firmwareName != ""
                onClicked:
                {
                    Cura.USBPrinterManager.updateAllFirmware(parent.firmwareName, updateEepromCheckbox.checked)
                }
            }
            Button
            {
                id: manualUpgradeButton
                text: catalog.i18nc("@action:button", "Upload custom Firmware");
                onClicked:
                {
                    customFirmwareDialog.open()
                }
            }
        }
        Row
        {
            anchors.topMargin: UM.Theme.getSize("default_margin").height
            anchors.top: buttonRow.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            CheckBox
            {
                id: updateEepromCheckbox
                text: qsTr("Update EEPROM")
                checked: true

            }
        }



        FileDialog
        {
            id: customFirmwareDialog
            title: catalog.i18nc("@title:window", "Select custom firmware")
            nameFilters:  "Firmware image files (*.hex)"
            selectExisting: true
            onAccepted: Cura.USBPrinterManager.updateAllFirmware(fileUrl, updateEepromCheckbox.checked)
        }
    }
}
