// Copyright (c) 2019 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 2.15
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1

import UM 1.2 as UM
import Cura 1.0 as Cura

import "PrinterOutput"


Item {
    id: base
    UM.I18nCatalog { id: catalog; name: "cura"}

    function showTooltip(item, position, text) {
        tooltip.text = text;
        position = item.mapToItem(base, position.x - UM.Theme.getSize("default_arrow").width, position.y);
        tooltip.show(position);
    }

    function hideTooltip() {
        tooltip.hide();
    }

    function strPadLeft(string, pad, length) {
        return (new Array(length + 1).join(pad) + string).slice(-length);
    }

    function getPrettyTime(time) {
        var hours = Math.floor(time / 3600)
        time -= hours * 3600
        var minutes = Math.floor(time / 60);
        time -= minutes * 60
        var seconds = Math.floor(time);

        var finalTime = strPadLeft(hours, "0", 2) + ":" + strPadLeft(minutes, "0", 2) + ":" + strPadLeft(seconds, "0", 2);
        return finalTime;
    }

    property var outputDeviceCount: Cura.MachineManager.printerOutputDevices.length
    property var connectedDevice: outputDeviceCount >= 1 ? Cura.MachineManager.printerOutputDevices[outputDeviceCount - 1] : null
    property bool klipperPrinter: connectedDevice != null ? Cura.MachineManager.activeMachineFirmwareType == "Klipper" : false
    property var activePrinter: connectedDevice != null && connectedDevice.address != "None" ? connectedDevice.activePrinter : null
    property var activePrintJob: activePrinter != null ? activePrinter.activePrintJob: null

    ScrollView {

        anchors.fill: base
        clip: true
        contentHeight: contentItem.children[0].childrenRect.height * 1.2
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        Column {
            id: printMonitor
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            visible: !klipperPrinter

            spacing: UM.Theme.getSize("default_margin").height

            OutputDeviceHeader {
                outputDevice: connectedDevice
                activeDevice: activePrinter
            }

            MonitorSection {
                label: catalog.i18nc("@label", "Temperatures")
                width: base.width
                visible: true
            }

            Rectangle {
                color: UM.Theme.getColor("wide_lining")
                width: base.width
                height: childrenRect.height

                Flow {
                    id: extrudersGrid
                    spacing: UM.Theme.getSize("thick_lining").width
                    width: parent.width

                    Repeater {
                        id: extrudersRepeater
                        model: connectedDevice != null ? connectedDevice.activePrinter.extruders : null

                        ExtruderBox {
                            color: UM.Theme.getColor("main_background")
                            width: index == machineExtruderCount.properties.value - 1 && index % 2 == 0 ? extrudersGrid.width : Math.round(extrudersGrid.width / 2 - UM.Theme.getSize("thick_lining").width / 2)
                            extruderModel: modelData
                        }
                    }
                }
            }

            Rectangle {
                color: UM.Theme.getColor("wide_lining")
                width: base.width
                height: UM.Theme.getSize("thick_lining").width
            }

            HeatedBedBox {
                width: base.width
            }

            UM.SettingPropertyProvider {
                id: bedTemperature
                containerStack: Cura.MachineManager.activeMachine
                key: "material_bed_temperature"
                watchedProperties: ["value", "minimum_value", "maximum_value", "resolve"]
                storeIndex: 0

                property var resolve: Cura.MachineManager.activeStack != Cura.MachineManager.activeMachine ? properties.resolve : "None"
            }

            UM.SettingPropertyProvider {
                id: machineExtruderCount
                containerStack: Cura.MachineManager.activeMachine
                key: "machine_extruder_count"
                watchedProperties: ["value"]
            }

            ManualPrinterControl {
                width: base.width
                printerModel: activePrinter
                visible: true
            }

            function loadSection(label, path) {
                var title = Qt.createQmlObject('import QtQuick 2.2; Loader {property string label: ""}', printMonitor);
                title.label = label
                var content = Qt.createQmlObject('import QtQuick 2.2; Loader {}', printMonitor);
                content.source = "file:///" + path
                content.item.width = base.width - (2 * UM.Theme.getSize("default_margin").width)
            }

            Repeater {
                model: Printer.printMonitorAdditionalSections
                delegate: Item
                {
                    Component.onCompleted: printMonitor.loadSection(modelData["name"], modelData["path"])
                }
            }

            MonitorSection {
                label: catalog.i18nc("@label", "Active Print")
                width: base.width
                visible: true //activePrintJob != null
            }


            MonitorItem {
                label: catalog.i18nc("@label", "Job Name:")
                value: activePrintJob != null ? activePrintJob.name : "N/A"
                width: base.width
            }

            MonitorItem {
                label: catalog.i18nc("@label", "Printing Time:")
                value: activePrintJob != null ? getPrettyTime(activePrintJob.timeTotal) : "N/A"
                width: base.width
            }

            MonitorItem {
                label: catalog.i18nc("@label", "Estimated Time Remaining:")
                value: activePrintJob != null ? getPrettyTime(activePrintJob.timeTotal - activePrintJob.timeElapsed) : "N/A"
                width: base.width
            }
        }

        Column {
            id: klipperMonitor

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: UM.Theme.getSize("default_margin").width
            }

            visible: klipperPrinter

            spacing: UM.Theme.getSize("default_margin").height

            // Label {
            //     id: klipperConnectionInfoTitle
            //     font: UM.Theme.getFont("large_bold")
            //     color: UM.Theme.getColor("text")
            //     anchors.margins: UM.Theme.getSize("default_margin").width
            //     text: "Yeehaw!"
            // }

            Label {
                // text: machineAssociatedUrls.properties.value
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Printers running Klipper firmware cannot be printed tethered to Cura LE.\n Please see the Mini 3 Quick Start Guide for more information."
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                height: UM.Theme.getSize("setting_control").height * 2
                width: base.width / 2 - (UM.Theme.getSize("default_margin").width * 1.5)
                text: "Quick Start Guide"
                onClicked: Qt.openUrlExternally("https://lulzbot.com/mini-3-monitor-page")
            }

        //     GridLayout {
        //         id: addIPGrid
        //         anchors.horizontalCenter: parent.horizontalCenter
        //         columns: 2

        //         Label {
        //             Layout.row: 0
        //             Layout.column: 0
        //             text: "Nickname: "
        //         }

        //         TextField {
        //             id: ipNameField
        //             Layout.row: 0
        //             Layout.column: 1
        //         }

        //         Label {
        //             Layout.row: 1
        //             Layout.column: 0
        //             text: "Address: "
        //         }

        //         TextField {
        //             id: ipAddressField
        //             Layout.row: 1
        //             Layout.column: 1
        //         }

        //         Button {
        //             Layout.row: 2
        //             Layout.column: 1
        //             Layout.fillWidth: true
        //             text: "Add Web Interface"
        //             onClicked: {

        //                 let newName = ipNameField.text
        //                 let newIP = ipAddressField.text
        //                 let jsonString = machineAssociatedUrls.properties.value
        //                 let urlsObj = JSON.parse(jsonString)
        //                 if (newName == "") {
        //                     klipperIPAddWarningLabel.text = "Please provide a name!"
        //                     klipperIPAddWarningLabel.visible = true
        //                 }
        //                 else if (newIP == "") {
        //                     klipperIPAddWarningLabel.text = "Please provide a web address!"
        //                     klipperIPAddWarningLabel.visible = true
        //                 }
        //                 else if (urlsObj[newName] == undefined) {
        //                     klipperIPAddWarningLabel.visible = false
        //                     urlsObj[newName] = newIP
        //                     ipModel.append({ text: newName, value: newIP })
        //                     ipSelectionComboBox.currentIndex = 0
        //                     openLinkButton.userLink = get(0).value
        //                     ipNameField.text = ""
        //                     ipAddressField.text = ""
        //                     jsonString = JSON.stringify(urlsObj)
        //                     machineAssociatedUrls.setPropertyValue("value", jsonString)
        //                 }

        //             }
        //         }

        //         Label {
        //             id: klipperIPAddWarningLabel
        //             Layout.row: 3
        //             Layout.column: 1
        //             Layout.fillWidth: true
        //             visible: false
        //             color: "red"
        //             text: ""
        //         }
        //     }

        //     GridLayout {
        //         id: comboBoxIPGrid
        //         anchors.horizontalCenter: parent.horizontalCenter
        //         columns: 2

        //         Cura.ComboBox {
        //             id: ipSelectionComboBox
        //             Layout.row: 0
        //             Layout.column : 0
        //             Layout.columnSpan: 2
        //             Layout.fillWidth: true
        //             Layout.preferredHeight: UM.Theme.getSize("setting_control").height

        //             model: ipModel

        //             textRole: "text"

        //             currentIndex: 0

        //             onActivated: {
        //                 var newValue = model.get(index).value
        //                 openLinkButton.userLink = newValue
        //             }
        //         }

        //         Button {
        //             id: openLinkButton
        //             Layout.row: 1
        //             Layout.column: 0

        //             text: "Open Link"
        //             enabled: userLink != ""
        //             visible: true

        //             property string userLink: ""

        //             onClicked: {
        //                 if (userLink.startsWith("http")) {
        //                     Qt.openUrlExternally(userLink)
        //                 } else {
        //                     Qt.openUrlExternally("http://" + userLink)
        //                 }
        //             }
        //         }

        //         Button {
        //             id: deleteLinkButton
        //             Layout.row: 1
        //             Layout.column: 1

        //             enabled: ipModel.get(ipSelectionComboBox.currentIndex) != undefined

        //             text: "Remove"

        //             onClicked: {
        //                 let keyToDelete = ipModel.get(ipSelectionComboBox.currentIndex).text
        //                 let jsonString = machineAssociatedUrls.properties.value
        //                 let urlsObj = JSON.parse(jsonString)
        //                 ipModel.remove(ipSelectionComboBox.currentIndex)
        //                 ipSelectionComboBox.currentIndex = 0
        //                 openLinkButton.userLink = get(0).value
        //                 delete urlsObj[keyToDelete]
        //                 jsonString = JSON.stringify(urlsObj)
        //                 machineAssociatedUrls.setPropertyValue("value", jsonString)
        //             }
        //         }
        //     }

        //     ListModel {
        //         id: ipModel
        //         function updateModel() {
        //             clear()
        //             if(machineAssociatedUrls.properties.value) {
        //                 let dataModel = JSON.parse(machineAssociatedUrls.properties.value)
        //                 for(const nickname in dataModel) {
        //                     append({ text: nickname, value: dataModel[nickname] });
        //                 }
        //                 ipSelectionComboBox.currentIndex = 0
        //                 openLinkButton.userLink = get(0).value
        //             }
        //         }

        //         Component.onCompleted: updateModel()
        //     }

        //     // Remake the model when the model is bound to a different container stack
        //     Connections
        //     {
        //         target: machineAssociatedUrls
        //         function onContainerStackChanged() { ipModel.updateModel() }
        //         function onIsValueUsedChanged() { ipModel.updateModel() }
        //     }

        //     UM.SettingPropertyProvider {
        //         id: machineAssociatedUrls
        //         containerStack: Cura.MachineManager.activeMachine
        //         key: "machine_associated_urls"
        //         watchedProperties: ["value"]
        //     }
        }
    }

    PrintSetupTooltip {
        id: tooltip
    }
}
