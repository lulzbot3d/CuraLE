// Copyright (c) 2019 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.3

import UM 1.5 as UM
import Cura 1.0 as Cura


// This element contains all the elements the user needs to visualize the data
// that is gather after the slicing process, such as printing time, material usage, ...
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

    Item
    {
        id: information
        width: parent.width
        height: childrenRect.height
        
        PrintInformationWidget
        {
            id: printInformationPanel
            visible: !preSlicedData
            anchors
            {
                top: parent.top
                right: parent.right
            }
        }

        ColumnLayout
        {
            id: glanceInformation
            spacing: UM.Theme.getSize("thin_margin").height / 3

            anchors
            {
                left: parent.left
                right: printInformationPanel.left
            }

            Cura.IconWithText
            {
                id: printerName

                Layout.fillWidth: true

                text: Cura.MachineManager.activeMachine != null ? Cura.MachineManager.activeMachine.id : ""
                source: UM.Theme.getIcon("TAZPrinter")
                font: UM.Theme.getFont("small")
            }

            RowLayout
            {
                id: timeAndCostsRow

                Cura.IconWithText
                {
                    id: estimatedTime

                    Layout.fillWidth: true

                    source: UM.Theme.getIcon("Clock")
                    font: UM.Theme.getFont("small")
                    text:
                    {
                        if (preSlicedData)
                        {
                            return catalog.i18nc("@label", "No time estimation available")
                        }
                        let printDuration = PrintInformation.currentPrintTime
                        let displayFormat = printDuration.days ? UM.DurationFormat.Short : UM.DurationFormat.Long
                        return printDuration.getDisplayString(displayFormat)
                    }
                }

                Cura.IconWithText
                {
                    id: estimatedCosts

                    Layout.fillWidth: true

                    source: UM.Theme.getIcon("Spool")
                    font: UM.Theme.getFont("small")

                    property int printMaterialsCount: PrintInformation.materialNames.length
                    property string printMaterialName: PrintInformation.materialNames[0]
                    property string printMaterialName2: printMaterialsCount > 1 ? PrintInformation.materialNames[1] : ""
                    property var printMaterialLengths: PrintInformation.materialLengths
                    property var printMaterialWeights: PrintInformation.materialWeights
                    property var printMaterialCosts: PrintInformation.materialCosts

                    text:
                    {
                        let outputString = "No cost estimation available"
                        if (preSlicedData)
                        {
                            return outputString
                        }

                        // PrintInformation doesn't actually supply just a total number so we've gotta add each part together.
                        // This should actually probably be done there, might do that eventually.
                        let totalWeights = 0
                        let totalLengths = 0.0
                        let totalCosts = 0.0
                        if (printMaterialLengths)
                        {
                            for(let i = 0; i < printMaterialLengths.length; i++)
                            {
                                if(printMaterialLengths[i] > 0)
                                {
                                    totalLengths += printMaterialLengths[i]
                                    totalWeights += Math.round(printMaterialWeights[i])
                                    totalCosts += printMaterialCosts[i] == undefined ? 0.0 : printMaterialCosts[i]
                                }
                            }
                        }

                        outputString = printMaterialName + " · " + totalWeights + "g · " + totalLengths.toFixed(2) + "m"
                        if(totalCosts > 0) // Add cost only if they've actually told us how much the filament costs
                        {
                            outputString += " · %1%2".arg(UM.Preferences.getValue("cura/currency")).arg(totalCosts.toFixed(2))
                        }
                        return outputString
                    }
                }
            }
        }
    }

    Item
    {
        id: buttonRow
        anchors.right: parent.right
        anchors.left: parent.left
        height: UM.Theme.getSize("action_button").height
        property bool currentlyPreview: UM.Controller.activeStage.stageId == "PreviewStage"
        property string nextStage: currentlyPreview ? "PrepareStage" : "PreviewStage"

        Cura.SecondaryButton
        {
            id: previewStageShortcut

            anchors
            {
                left: parent.left
                right: outputDevicesButton.left
                rightMargin: UM.Theme.getSize("default_margin").width
            }

            height: UM.Theme.getSize("action_button").height
            text: buttonRow.currentlyPreview ? catalog.i18nc("@button", "Prepare") : catalog.i18nc("@button", "Preview")
            tooltip: text
            fixedWidthMode: true

            toolTipContentAlignment: UM.Enums.ContentAlignment.AlignLeft

            onClicked: UM.Controller.setActiveStage(buttonRow.nextStage)
        }

        Cura.OutputDevicesActionButton
        {
            id: outputDevicesButton

            anchors.right: parent.right
            width: previewStageShortcut.visible ? UM.Theme.getSize("action_button").width * 1.5 : parent.width
            height: UM.Theme.getSize("action_button").height
        }
    }
}
