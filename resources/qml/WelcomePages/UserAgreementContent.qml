// Copyright (c) 2022 UltiMaker
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 2.3

import UM 1.5 as UM
import Cura 1.1 as Cura

//
// This component contains the content for the "User Agreement" page of the welcome on-boarding process.
//
Item
{
    UM.I18nCatalog { id: catalog; name: "cura" }

    UM.Label
    {
        id: titleLabel
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        horizontalAlignment: Text.AlignHCenter
        text: catalog.i18nc("@label", "User Agreement")
        color: UM.Theme.getColor("primary_button")
        font: UM.Theme.getFont("huge")
    }

    UM.Label
    {
        id: disclaimerLineLabel
        anchors
        {
            top: titleLabel.bottom
            topMargin: UM.Theme.getSize("wide_margin").height
            left: parent.left
            right: parent.right
        }

        text: "<h2><b>Disclaimer</b></h2>"
            + "<p>Please read this disclaimer carefully.</p>"
            + "<p>Cura LulzBot Edition was created using source code for UltiMaker Cura released under the LGPLv3 or higher. All disclaimers relating to this software also apply to UltiMaker."
            + "<p>FAME3D provides this software \"As is\" without warranty of any kind. The entire risk as to the quality and performance of this software is with you, the user.</p>"
            + "<p>Unless required by applicable law or agreed to in writing, in no event will FAME3D be liable to you for damages, including any general, special, incidental, or consequential damages arising out of the use or inability to use any FAME3D software or third party software.</p>"
        textFormat: Text.RichText
        wrapMode: Text.WordWrap
        font: UM.Theme.getFont("medium")
    }

    Cura.PrimaryButton
    {
        id: agreeButton
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        text: catalog.i18nc("@button", "Agree")
        onClicked:
        {
            CuraApplication.writeToLog("i", "User accepted the User-Agreement.")
            CuraApplication.setNeedToShowUserAgreement(false)
            base.showNextPage()
        }
    }

    Cura.SecondaryButton
    {
        id: declineButton
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        text: catalog.i18nc("@button", "Decline and close")
        onClicked:
        {
            CuraApplication.writeToLog("i", "User declined the User Agreement.")
            CuraApplication.closeApplication() // NOTE: Hard exit, don't use if anything needs to be saved!
        }
    }
}