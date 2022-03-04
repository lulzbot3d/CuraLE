// Copyright (c) 2017 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 1.4

import UM 1.3 as UM

UM.Dialog
{
    id: baseDialog
    minimumWidth: Math.floor(UM.Theme.getSize("modal_window_minimum").width * 0.75)
    minimumHeight: Math.floor(UM.Theme.getSize("modal_window_minimum").height * 0.5)
    width: minimumWidth
    height: minimumHeight
    title: catalog.i18nc("@title:window", "User Agreement")

    TextArea
    {
        anchors.top: parent.top
        width: parent.width
        anchors.bottom: buttonRow.top
        text: '
                <p>Cura LulzBot Edition, a Free Software solution for Fused Filament Fabrication 3D printing, is distributed under the terms of the GNU Lesser General Public License (LGPLv3).</p>
                <p>Copyright © 2017, 2018, 2019, 2020 Fargo Additive Manufacturing Equipment 3D, LLC. - Released under terms of the LGPLv3 License.</p>
                <p>Copyright © 2014, 2015, 2016, 2017 Fargo Additive Manufacturing Equipment 3D, LLC. - Released under terms of the AGPLv3 License.</p>
		<p>Derived from Cura, which was created by David Braam and Ultimaker. Copyright © 2013 David Braam - Released under terms of the AGPLv3 License.<p>
                <p>This program is Free Software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.</p>
                <p>This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU Lesser General Public License along with this program. If not, see http://www.gnu.org/licenses/.</p>
                '
        readOnly: true;
        textFormat: TextEdit.RichText
    }

    Item
    {
        id: buttonRow
        anchors.bottom: parent.bottom
        width: parent.width
        anchors.bottomMargin: UM.Theme.getSize("default_margin").height

        UM.I18nCatalog { id: catalog; name:"cura" }

        Button
        {
            anchors.right: parent.right
            text: catalog.i18nc("@action:button", "I understand and agree")
            onClicked: {
                baseDialog.accepted()
            }
        }

        Button
        {
            anchors.left: parent.left
            text: catalog.i18nc("@action:button", "I don't agree")
            onClicked: {
                baseDialog.rejected()
            }
        }
    }

    onAccepted: manager.didAgree(true)
    onRejected: manager.didAgree(false)
    onClosing: manager.didAgree(false)
}
