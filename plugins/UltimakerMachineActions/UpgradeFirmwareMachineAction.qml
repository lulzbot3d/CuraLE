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
            text: catalog.i18nc("@label", "Your LulzBot 3D Printer ships from our factory ready to help you Make Everything, right out of the box. Get the latest features and the most performance out of your LulzBot 3D Printer by keeping your firmware updated.")
        }

        Label
        {
            id: upgradeText1
            anchors.top: pageDescription.bottom
            anchors.topMargin: UM.Theme.getSize("default_margin").height
            width: parent.width
            wrapMode: Text.WordWrap
            color: "red"
            text: catalog.i18nc("@label", "
                <font color=\"red\"><b>WARNING:</b>The firmware updating process will overwrite certain parameters. Restore the tuned values by following the steps below after the firmware update is complete.</font><br>")

        }
        Label
        {
            id: upgradeText2
            anchors.top: upgradeText1.bottom
            anchors.topMargin: UM.Theme.getSize("default_margin").height
            width: parent.width
            wrapMode: Text.WordWrap
            color: "red"
            text: catalog.i18nc("@label", "Please have the following recorded <u>before</u> upgrading firmware:
                <ul type=\"bullet\">
                    <li>Extruder steps per unit
                        (<a href='https://www.lulzbot.com/learn/tutorials/firmware-flashing-through-cura#get-esteps'>E-steps</a>)
                    <li>Z-axis offset
                        (<a href='https://www.lulzbot.com/learn/tutorials/Z-axis-offset#get-offset'>Z-offset</a>)
                </ul>")
                onLinkActivated: Qt.openUrlExternally(link)
            MouseArea
            {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton // we don't want to eat clicks on the Text
                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }
        Label
        {
        id: upgradeText3
            anchors.top: upgradeText2.bottom
            anchors.topMargin: UM.Theme.getSize("default_margin").height
            width: parent.width
            wrapMode: Text.WordWrap
            text: catalog.i18nc("@label", "You will need to <a href='https://www.lulzbot.com/learn/tutorials/firmware-flashing-through-cura#esteps'>restore the E-steps</a> and <a href='https://www.lulzbot.com/learn/tutorials/Z-axis-offset#restore-offset'>restore the Z-offset</a> after firmware upgrade.")
            onLinkActivated: Qt.openUrlExternally(link)
            MouseArea
            {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton // we don't want to eat clicks on the Text
                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }
        Label
        {
        id: upgradeText4
            anchors.top: upgradeText3.bottom
            anchors.topMargin: UM.Theme.getSize("default_margin").height
            width: parent.width
            wrapMode: Text.WordWrap
            color: "red"
            text: catalog.i18nc("@label", "If installing universal tool head firmware (2.0.9.X+), ensure that you select the installed tool head via your printers LCD prior to printing.")
        }
        Row
        {
            id: buttonRow
            anchors.top: upgradeText4.bottom
            anchors.topMargin: UM.Theme.getSize("default_margin").height
            anchors.horizontalCenter: parent.horizontalCenter
            width: childrenRect.width
            spacing: UM.Theme.getSize("default_margin").width
            Button
            {
                id: autoUpgradeButton
                text: catalog.i18nc("@action:button", "Automatically upgrade Firmware");
                // enabled: Cura.USBPrinterManager.getDefaultFirmwareName() != ""
                onClicked:
                {
                    Cura.USBPrinterManager.updateAllFirmware(Cura.USBPrinterManager.getDefaultFirmwareName(), updateEepromCheckbox.checked)
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
            id: newFirmwareRow
            anchors.topMargin: UM.Theme.getSize("default_margin").height
            anchors.top: buttonRow.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            Label
            {
                text: catalog.i18nc("@action:button", "Automatically upgrade Firmware version:") + " " + Cura.MachineManager.currentPrinterLastFirmwareVersion;
            }
        }
        Row
        {
            anchors.topMargin: UM.Theme.getSize("default_margin").height
            anchors.top: newFirmwareRow.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            CheckBox
            {
                id: updateEepromCheckbox
                text: qsTr("Update EEPROM")
                checked: Cura.MachineManager.currentPrinterEEPROMDefaultState

            }
        }


        FileDialog
        {
            id: customFirmwareDialog
            title: catalog.i18nc("@title:window", "Select custom firmware")
            nameFilters:  "Firmware image files (*.hex *.bin)"
            selectExisting: true
            selectMultiple: false
            onAccepted: {
                Cura.USBPrinterManager.updateAllFirmware(customFirmwareDialog.fileUrl, updateEepromCheckbox.checked)
            }
        }
    }
}
