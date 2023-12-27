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
        id: platformLinksGrid
        columns: 2
        spacing: UM.Theme.getSize("default_margin").width

        Repeater
        {
            model:
            [
                {
                    displayName: catalog.i18nc("@label:button", "LulzBot\nSupport"),
                    thumbnail: UM.Theme.getIcon("Help", "high"),
                    description: catalog.i18nc("@tooltip:button", "Contact LulzBot support."),
                    link: "https://lulzbot.com/support/contact-us",
                },
                {
                    displayName: "UltiMaker Marketplace", //Not translated, since it's a brand name.
                    thumbnail: UM.Theme.getIcon("Shop", "high"),
                    description: catalog.i18nc("@tooltip:button", "Extend UltiMaker Cura with plugins and material profiles."),
                    link: "https://marketplace.ultimaker.com/?utm_source=cura&utm_medium=software&utm_campaign=switcher-marketplace-materials",
                    permissionsRequired: []
                },
                {
                    displayName: catalog.i18nc("@label:button", "Sponsor Cura"),
                    thumbnail: UM.Theme.getIcon("Heart"),
                    description: catalog.i18nc("@tooltip:button", "Show your support for Cura with a donation."),
                    link: "https://ultimaker.com/software/ultimaker-cura/sponsor/",
                    permissionsRequired: []
                },
                {
                    displayName: catalog.i18nc("@label:button", "Ask the Community"),
                    thumbnail: UM.Theme.getIcon("Speak", "high"),
                    description: catalog.i18nc("@tooltip:button", "Discuss with the LulzBot Community."),
                    link: "https://forum.lulzbot.com/",
                    DFAccessRequired: false
                },
                {
                    displayName: catalog.i18nc("@label:button", "Report a Bug"),
                    thumbnail: UM.Theme.getIcon("Bug", "high"),
                    description: catalog.i18nc("@tooltip:button", "Let developers know that something is going wrong."),
                    link: "https://gitlab.com/lulzbot3d/cura-le/cura-lulzbot/-/issues/new",
                    DFAccessRequired: false
                },
                {
                    displayName: "LulzBot Homepage", //Not translated, since it's a URL.
                    thumbnail: UM.Theme.getIcon("Browser"),
                    description: catalog.i18nc("@tooltip:button", "Visit the LulzBot website."),
                    link: "https://lulzbot.com/",
                    DFAccessRequired: false
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
