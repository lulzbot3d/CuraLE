// Copyright (c) 2021 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.1

import UM 1.6 as UM
import Cura 1.6 as Cura

Rectangle
{
    property alias packageData: packageCardHeader.packageData
    property alias manageableInListView: packageCardHeader.showManageButtons

    height: childrenRect.height
    color: UM.Theme.getColor("main_background")
    radius: UM.Theme.getSize("default_radius").width

    PackageCardHeader
    {
        id: packageCardHeader

        Item
        {
            id: shortDescription

            anchors.fill: parent

            Label
            {
                id: descriptionLabel
                width: parent.width
                property real lastLineWidth: 0; //Store the width of the last line, to properly position the elision.

                text: packageData.description
                textFormat: Text.PlainText //Must be plain text, or we won't get onLineLaidOut signals. Don't auto-detect!
                font: UM.Theme.getFont("default")
                color: UM.Theme.getColor("text")
                maximumLineCount: 2
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                visible: text !== ""

                onLineLaidOut:
                {
                    if(truncated && line.isLast)
                    {
                        let max_line_width = parent.width - readMoreButton.width - fontMetrics.advanceWidth("… ") - 2 * UM.Theme.getSize("default_margin").width;
                        if(line.implicitWidth > max_line_width)
                        {
                            line.width = max_line_width;
                        }
                        else
                        {
                            line.width = line.implicitWidth - fontMetrics.advanceWidth("…"); //Truncate the ellipsis. We're adding this ourselves.
                        }
                        descriptionLabel.lastLineWidth = line.implicitWidth;
                    }
                }
            }
            Label
            {
                id: tripleDotLabel
                anchors.left: parent.left
                anchors.leftMargin: descriptionLabel.lastLineWidth
                anchors.bottom: descriptionLabel.bottom

                text: "… "
                font: descriptionLabel.font
                color: descriptionLabel.color
                visible: descriptionLabel.truncated && descriptionLabel.text !== ""
            }
            Cura.TertiaryButton
            {
                id: readMoreButton
                anchors.right: parent.right
                anchors.bottom: descriptionLabel.bottom
                height: fontMetrics.height //Height of a single line.

                text: catalog.i18nc("@info", "Read more")
                iconSource: UM.Theme.getIcon("LinkExternal")

                visible: descriptionLabel.truncated && descriptionLabel.text !== ""
                enabled: visible
                leftPadding: UM.Theme.getSize("default_margin").width
                rightPadding: UM.Theme.getSize("wide_margin").width
                textFont: descriptionLabel.font
                isIconOnRightSide: true

                onClicked: Qt.openUrlExternally(packageData.packageInfoUrl)
            }
        }
    }

    FontMetrics
    {
        id: fontMetrics
        font: UM.Theme.getFont("default")
    }
}
