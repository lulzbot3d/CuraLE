// Copyright (c) 2015 Ultimaker B.V.
// Cura is released under the terms of the AGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Window 2.1

import UM 1.1 as UM

UM.Dialog
{
    id: base

    //: About dialog title
    title: catalog.i18nc("@title:window","Duplicate settings")

    minimumWidth: 200 * Screen.devicePixelRatio
    minimumHeight: 100 * Screen.devicePixelRatio
    width: minimumWidth
    height: minimumHeight
    signal duplicate(int count_times)
    //UM.I18nCatalog { id: catalog; }

    Label
    {
        id: dup_label;

        anchors
        {
            top: parent.top
            left: parent.left
            leftMargin: UM.Theme.getSize("default_margin").width
        }
        text: catalog.i18nc("@label:label", "Duplicate times")
    }


    TextField
    {
        id: dup_count;

        anchors
        {
            top: parent.top
            left: dup_label.right
            leftMargin: UM.Theme.getSize("default_margin").width
            right: parent.right
        }

        text: "1"
        validator: RegExpValidator { regExp: /[0-9]{0,2}/ }
    }

    rightButtons: [
        Button
        {
            //: Close about dialog button
            text: catalog.i18nc("@action:button","Close");

            onClicked: base.visible = false;
        },

        Button
        {
            text: catalog.i18nc("@action:button","OK");

            onClicked:
            {
                base.duplicate(parseInt(dup_count.text));
                base.visible = false;
            }
        }
    ]
}

