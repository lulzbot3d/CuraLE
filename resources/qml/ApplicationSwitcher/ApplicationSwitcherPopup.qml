// Copyright (c) 2021 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.15

import UM 1.4 as UM
import Cura 1.1 as Cura

Popup
{
    id: applicationSwitcherPopup

    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

    opacity: opened ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 100 } }
    padding: UM.Theme.getSize("wide_margin").width

    contentItem: Grid
    {
        id: ultimakerPlatformLinksGrid
        columns: 3
        spacing: UM.Theme.getSize("default_margin").width

        Repeater
        {
            model:
            [
                //// These first three aren't needed here since obviously we aren't using UltiMaker printers.
                // *thanks though UltiMaker for keeping Cura open source wij houden van je muahmuah*
                // {
                //     displayName: catalog.i18nc("@label:button", "My printers"),
                //     thumbnail: UM.Theme.getIcon("PrinterTriple", "high"),
                //     description: catalog.i18nc("@tooltip:button", "Monitor printers in Ultimaker Digital Factory."),
                //     link: "https://digitalfactory.ultimaker.com/app/printers",
                //     permissionsRequired: ["digital-factory.printer.read"]
                // },
                // {
                //     displayName: "Digital Library", //Not translated, since it's a brand name.
                //     thumbnail: UM.Theme.getIcon("Library", "high"),
                //     description: catalog.i18nc("@tooltip:button", "Create print projects in Digital Library."),
                //     link: "https://digitalfactory.ultimaker.com/app/library",
                //     permissionsRequired: ["digital-factory.project.read.shared"]
                // },
                // {
                //     displayName: catalog.i18nc("@label:button", "Print jobs"),
                //     thumbnail: UM.Theme.getIcon("Nozzle"),
                //     description: catalog.i18nc("@tooltip:button", "Monitor print jobs and reprint from your print history."),
                //     link: "https://digitalfactory.ultimaker.com/app/print-jobs",
                //     permissionsRequired: ["digital-factory.print-job.read"]
                // },
                {
                    displayName: "UltiMaker Marketplace", //Not translated, since it's a brand name.
                    thumbnail: UM.Theme.getIcon("Shop", "high"),
                    description: catalog.i18nc("@tooltip:button", "Extend UltiMaker Cura with plugins and material profiles."),
                    link: "https://marketplace.ultimaker.com/",
                    permissionsRequired: []
                },
                // {
                //     displayName: catalog.i18nc("@label:button", "Sponsor Cura"),
                //     thumbnail: UM.Theme.getIcon("Heart"),
                //     description: catalog.i18nc("@tooltip:button", "Show your support for Cura with a donation."),
                //     link: "https://lulzbot.com/", // Just buy a LulzBot printer, dude, they cost enough as it is. :P
                //     permissionsRequired: []
                // },
                {
                    displayName: catalog.i18nc("@label:button", "LulzBot support"),
                    thumbnail: UM.Theme.getIcon("Help", "high"),
                    description: catalog.i18nc("@tooltip:button", "View LulzBot's support pages."),
                    link: "https://lulzbot.com/support/",
                    permissionsRequired: []
                },
                {
                    displayName: catalog.i18nc("@label:button", "Ask a question"),
                    thumbnail: UM.Theme.getIcon("Speak", "high"),
                    description: catalog.i18nc("@tooltip:button", "Consult the LulzBot Community."),
                    link: "https://forum.lulzbot.com/",
                    permissionsRequired: []
                },
                {
                    displayName: catalog.i18nc("@label:button", "Report a bug"),
                    thumbnail: UM.Theme.getIcon("Bug", "high"),
                    description: catalog.i18nc("@tooltip:button", "Let developers know that something is going wrong."),
                    link: "https://github.com/lulzbot3d/CuraLE/issues/new/choose",
                    permissionsRequired: []
                },
                {
                    displayName: "LulzBot.com", //Not translated, since it's a URL.
                    thumbnail: UM.Theme.getIcon("Browser"),
                    description: catalog.i18nc("@tooltip:button", "Visit the LulzBot website."),
                    link: "https://lulzbot.com/",
                    permissionsRequired: []
                }
            ]

            delegate: ApplicationButton
            {
                displayName: modelData.displayName
                iconSource: modelData.thumbnail
                tooltipText: modelData.description
                isExternalLink: true
                visible:
                {
                    try
                    {
                        modelData.permissionsRequired.forEach(function(permission)
                        {
                            if(!Cura.API.account.isLoggedIn || !Cura.API.account.permissions.includes(permission)) //This required permission is not in the account.
                            {
                                throw "No permission to use this application."; //Can't return from within this lambda. Throw instead.
                            }
                        });
                    }
                    catch(e)
                    {
                        return false;
                    }
                    return true;
                }

                onClicked: Qt.openUrlExternally(modelData.link)
            }
        }
    }

    background: UM.PointingRectangle
    {
        color: UM.Theme.getColor("tool_panel_background")
        borderColor: UM.Theme.getColor("lining")
        borderWidth: UM.Theme.getSize("default_lining").width

        // Move the target by the default margin so that the arrow isn't drawn exactly on the corner
        target: Qt.point(width - UM.Theme.getSize("default_margin").width - (applicationSwitcherButton.width / 2), -10)

        arrowSize: UM.Theme.getSize("default_arrow").width
    }
}