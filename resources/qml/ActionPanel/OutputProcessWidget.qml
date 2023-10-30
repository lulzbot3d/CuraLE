// Copyright (c) 2019 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.3

import UM 1.1 as UM
import Cura 1.0 as Cura


// This element contains all the elements the user needs to visualize the data
// that is gather after the slicing process, such as printint time, material usage, ...
// There are also two buttons: one to previsualize the output layers, and the other to
// select what to do with it (such as print over network, save to file, ...)
Column
{
    id: widget

    spacing: UM.Theme.getSize("thin_margin").height / 2
    property bool preSlicedData: PrintInformation.preSliced
    property alias hasPreviewButton: previewStageShortcut.visible

    UM.I18nCatalog
    {
        id: catalog
        name: "cura"
    }

    Item {
        id: information
        width: parent.width
        height: childrenRect.height

        PrintInformationWidget {
            id: printInformationPanel
            visible: !preSlicedData
            anchors {
                top: parent.top
                right: parent.right
            }
        }

        ColumnLayout {
            id: glanceInformation
            spacing: UM.Theme.getSize("thin_margin").height / 3

            anchors {
                left: parent.left
                right: printInformationPanel.left
            }

            Cura.IconWithText {
                id: printerName

                Layout.fillWidth: true

                text: Cura.MachineManager.activeMachine.id
                // source: UM.Theme.getIcon("TAZPrinter")
                source: UM.Theme.getIcon("Printer")
                font: UM.Theme.getFont("small")
            }

            RowLayout {
                id: materialRow

                Cura.IconWithText {
                    id: printMaterial

                    text: PrintInformation.materialNames[0]
                    source: UM.Theme.getIcon("Extruder")
                    font: UM.Theme.getFont("small")
                }

                Cura.IconWithText {
                    id: printMaterial2
                    visible: PrintInformation.materialNames.length > 1
                    width: visible ? parent.width / 3 : 0

                    text: visible ? PrintInformation.materialNames[1] : ""
                    source: UM.Theme.getIcon("Extruder")
                    font: UM.Theme.getFont("small")
                }
            }

            RowLayout {
                id: timeAndCostsRow

                Cura.IconWithText {
                    id: estimatedTime

                    Layout.fillWidth: true

                    text: preSlicedData ? catalog.i18nc("@label", "No time estimation available") : PrintInformation.currentPrintTime.getDisplayString(UM.DurationFormat.Long)
                    source: UM.Theme.getIcon("Clock")
                    font: UM.Theme.getFont("small")
                }

                Cura.IconWithText {
                    id: estimatedCosts

                    Layout.fillWidth: true

                    property var printMaterialLengths: PrintInformation.materialLengths
                    property var printMaterialWeights: PrintInformation.materialWeights
                    property var printMaterialCosts: PrintInformation.materialCosts

                    text: {
                        if (preSlicedData) {
                            return catalog.i18nc("@label", "No cost estimation available")
                        }
                        var totalLengths = 0
                        var totalWeights = 0
                        var totalCosts = 0.0
                        if (printMaterialLengths) {
                            for(var index = 0; index < printMaterialLengths.length; index++) {
                                if(printMaterialLengths[index] > 0) {
                                    totalLengths += printMaterialLengths[index]
                                    totalWeights += Math.round(printMaterialWeights[index])
                                    var cost = printMaterialCosts[index] == undefined ? 0.0 : printMaterialCosts[index]
                                    totalCosts += cost
                                }
                            }
                        }
                        if(totalCosts > 0) {
                            var costString = "%1 %2".arg(UM.Preferences.getValue("cura/currency")).arg(totalCosts.toFixed(2))
                            return totalWeights + "g · " + totalLengths.toFixed(2) + "m · " + costString
                        }
                        return totalWeights + "g · " + totalLengths.toFixed(2) + "m"
                    }
                    source: UM.Theme.getIcon("Spool")
                    font: UM.Theme.getFont("small")
                }
            }
        }
    }

    Item {
        id: buttonRow
        anchors.right: parent.right
        anchors.left: parent.left
        height: UM.Theme.getSize("action_button").height

        Cura.SecondaryButton {
            id: previewStageShortcut

            anchors {
                left: parent.left
                right: outputDevicesButton.left
                rightMargin: UM.Theme.getSize("default_margin").width
            }

            height: UM.Theme.getSize("action_button").height
            text: catalog.i18nc("@button", "Preview")
            tooltip: text
            fixedWidthMode: true

            toolTipContentAlignment: Cura.ToolTip.ContentAlignment.AlignLeft

            onClicked: UM.Controller.setActiveStage("PreviewStage")
        }

        Cura.OutputDevicesActionButton {
            id: outputDevicesButton

            anchors.right: parent.right
            width: previewStageShortcut.visible ? UM.Theme.getSize("action_button").width : parent.width
            height: UM.Theme.getSize("action_button").height
        }
    }
}
