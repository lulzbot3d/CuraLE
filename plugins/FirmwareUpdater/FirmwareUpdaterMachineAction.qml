// Copyright (c) 2018 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Controls 1.4 as OldControls
import QtQuick.Layouts 1.1
import QtQuick.Window 2.1
import QtQuick.Dialogs 1.2 // For filedialog

import UM 1.3 as UM
import Cura 1.0 as Cura


Cura.MachineAction {
    anchors.fill: parent;
    property int outputDevicesCount: Cura.MachineManager.printerOutputDevices.length
    property bool printerConnected: outputDevicesCount > 1
    property var activeOutputDevice: printerConnected ? Cura.MachineManager.printerOutputDevices[outputDevicesCount - 1] : null
    property bool canUpdateFirmware: activeOutputDevice ? activeOutputDevice.activePrinter.canUpdateFirmware : false
    property string firmwareName: Cura.MachineManager.activeMachine.getDefaultFirmwareName()

    Column {
        id: firmwareUpdaterMachineAction
        anchors.fill: parent;
        anchors.leftMargin: UM.Theme.getSize("default_margin").width * 2
        anchors.rightMargin: UM.Theme.getSize("default_margin").width * 2
        UM.I18nCatalog { id: catalog; name: "cura"}
        spacing: UM.Theme.getSize("default_margin").height

        Label {
            width: parent.width
            text: catalog.i18nc("@title", "<b>Updating Your LulzBot's Firmware</b>")
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.pointSize: 18
        }

        Label {
            text: " " //Spacer
        }

        Label {
            width: parent.width
            wrapMode: Text.WordWrap
            font.pointSize: 10
            text: catalog.i18nc("@label", "<b>What It Does:</b> Firmware controls your 3D printer's mechanical functions.")
        }

        Label {
            width: parent.width
            wrapMode: Text.WordWrap
            font.pointSize: 10
            text: catalog.i18nc("@label", "<b>Why Update:</b> Gain new features and boost performance.")
        }

        Label {
            width: parent.width
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            color: "red"
            text: catalog.i18nc("@label", "<b>WARNING:</b> Updating will reset certain machine settings. It's a good idea to note down any settings you might want later.</font><br>")

        }

        Label {
            width: parent.width
            wrapMode: Text.WordWrap
            font.pointSize: 10
            text: {
                catalog.i18nc("@label", " \
                <b>Before Updating, Note Down:</b> \
                <ul type=\"bullet\"> \
                    <li>For All Machines: \
                        (<a href='https://ohai.lulzbot.com/project/finding-recording-and-restoring-your-z-axis-offset/maintenance-repairs/'>Z-offset</a>) \
                    <li>For TAZ Pro Platform: \
                        (<a href='https://www.youtube.com/watch?v=fwazYrkyaMI'>Backlash Compensation</a>) \
                    <li>For Legacy Machines (Mini 1, TAZ 6, etc): \
                        (<a href='https://ohai.lulzbot.com/project/fine-tune-mini-extruder/calibration/'>E-Steps</a>) \
                </ul>")
            }
            onLinkActivated: Qt.openUrlExternally(link)

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton // we don't want to eat clicks on the Text
                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }

        Label {
            width: parent.width
            wrapMode: Text.WordWrap
            font.pointSize: 10
            text: {
                catalog.i18nc("@label", " \
                <b>After Updating:</b> \
                <ul type=\"bullet\"> \
                    <li>Re-enter the noted values or calibrate them anew. \
                    <li>If using Universal Firmware (2.0.9.X+), <a href='https://ohai.lulzbot.com/project/flashing-firmware-through-cura-3620/firmware-flashing/'>select the proper tool head</a> from the printer's display. \
                </ul>")
            }
            onLinkActivated: Qt.openUrlExternally(link)
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton // we don't want to eat clicks on the Text
                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }

        Label {
            width: parent.width
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 12
            text: catalog.i18nc("@label", "Enjoy enhanced reliability, repeatability, and performance from your LulzBot!")
        }

        Label {
            text: " " // spacer
        }

        Label {
            width: parent.width
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 10
            visible: printerConnected && canUpdateFirmware && firmwareName != ""
            text: catalog.i18nc("@action:button", "Newest Firmware For Selected Printer Configuration: <b>") + Cura.MachineManager.activeMachineLatestFirmwareVersion + "</b>";
        }

        Label {
            width: parent.width
            wrapMode: Text.WordWrap
            visible: printerConnected && !canUpdateFirmware
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 8
            text: catalog.i18nc("@label", "Firmware can not be updated because the connection with the printer does not support updating firmware.");
        }

        Label {
            width: parent.width
            wrapMode: Text.WordWrap
            visible: !printerConnected
            horizontalAlignment: Text.AlignHCenter
            color: "red"
            text: catalog.i18nc("@label", "Firmware can not be updated because there is no 3D printer detected!");
        }

        OldControls.Button {
            id: autoUpgradeButton
            anchors.horizontalCenter: parent.horizontalCenter
            width: UM.Theme.getSize("setting_control").width * 2
            height: UM.Theme.getSize("setting_control").height * 2
            text: catalog.i18nc("@action:button", "Update Firmware");
            style: UM.Theme.styles.monitor_checkable_button_style
            enabled: printerConnected && firmwareName != ""
            onClicked: {
                updateProgressDialog.visible = true;
                activeOutputDevice.updateFirmware(firmwareName);
            }
        }

        Text {
            id: manualUpgradeTextButton
            anchors.horizontalCenter: parent.horizontalCenter
            text: catalog.i18nc("@action:button", "Upload Custom Firmware")
            color: "grey"
            font.pixelSize: 10
            font.underline: true
            font.bold: true

            MouseArea {
                id: manualUpgradeTextButtonArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: {
                    if (printerConnected) {
                        return Qt.PointingHandCursor
                    } else { return Qt.ArrowCursor }
                }
                onClicked: {
                    if (printerConnected) {
                        customFirmwareDialog.open()
                    }
                }
            }
        }
    }

    FileDialog {
        id: customFirmwareDialog
        title: catalog.i18nc("@title:window", "Select custom firmware")
        nameFilters:  "Firmware image files (*.hex *.bin)"
        folder: "../../resources/firmware"
        selectExisting: true
        onAccepted: {
            updateProgressDialog.visible = true;
            activeOutputDevice.updateFirmware(fileUrl);
        }
    }

    UM.Dialog {
        id: updateProgressDialog

        width: minimumWidth
        minimumWidth: 500 * screenScaleFactor
        height: minimumHeight
        minimumHeight: 100 * screenScaleFactor

        modality: Qt.ApplicationModal

        title: catalog.i18nc("@title:window","Firmware Update")

        Column {
            anchors.fill: parent
            spacing: 5

            Label {
                id: statusLabel

                anchors {
                    left: parent.left
                    right: parent.right
                }

                text: {
                    if(manager.firmwareUpdater == null) {
                        return "";
                    }
                    switch (manager.firmwareUpdater.firmwareUpdateState) {
                        case 0:
                            return ""; //Not doing anything (eg; idling)
                        case 1:
                            return catalog.i18nc("@label","Updating firmware...");
                        case 2:
                            return catalog.i18nc("@label","Firmware update completed!");
                        case 3:
                            return catalog.i18nc("@label","Firmware update failed due to an unknown error!");
                        case 4:
                            return catalog.i18nc("@label","Firmware update failed due to an communication error!");
                        case 5:
                            return catalog.i18nc("@label","Firmware update failed due to an input/output error!");
                        case 6:
                            return catalog.i18nc("@label","Firmware update failed due to missing firmware!");
                        case 7:
                            return catalog.i18nc("@label","Preparing to update firmware...")
                        case 8:
                            return catalog.i18nc("@label","Printer not quite ready, please wait...")
                        default:
                            return catalog.i18nc("@label","Unknown State, something has gone wrong!")
                    }
                }

                wrapMode: Text.Wrap
            }

            ProgressBar {
                id: progBar
                value: (manager.firmwareUpdater != null) ? manager.firmwareUpdater.firmwareProgress : 0
                from: 0
                to: 100
                indeterminate: {
                    if(manager.firmwareUpdater == null) {
                        return false;
                    }
                    return manager.firmwareUpdater.firmwareProgress < 0
                }
                anchors {
                    left: parent.left;
                    right: parent.right;
                }
            }
        }

        rightButtons: [
            Button {
                id: exitButton
                text: catalog.i18nc("@action:button","Close");
                enabled: (manager.firmwareUpdater != null) ? manager.firmwareUpdater.firmwareUpdateState != 1 : true;
                onClicked: {
                    updateProgressDialog.visible = false
                }
            }
        ]
    }
}