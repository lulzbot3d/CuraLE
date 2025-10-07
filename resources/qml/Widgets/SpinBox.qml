// Copyright (c) 2022 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 2.3

import UM 1.5 as UM
import Cura 1.1 as Cura


//
// SpinBox with Cura styling.
//
SpinBox
{
    id: control

    property var defaultTextOnEmptyModel: catalog.i18nc("@label", "No items to select from")  // Text displayed in the combobox when the model is empty
    property var defaultTextOnEmptyIndex: ""  // Text displayed in the combobox when the model has items but no item is selected
    property alias textFormat: contentLabel.textFormat
    property alias backgroundColor: background.color
    property bool forceHighlight: false
    property int contentLeftPadding: UM.Theme.getSize("setting_unit_margin").width
    property var textFont: UM.Theme.getFont("default")
    property bool showDropdownSwatch: false

    enabled: delegateModel.count > 0

    height: UM.Theme.getSize("combobox").height

    onVisibleChanged: { popup.close() }

    states: [
        State
        {
            name: "disabled"
            when: !control.enabled
            PropertyChanges { target: background; color: UM.Theme.getColor("setting_control_disabled")}
            PropertyChanges { target: contentLabel; color: UM.Theme.getColor("setting_control_disabled_text")}
        },
        State
        {
            name: "active"
            when: control.activeFocus
            PropertyChanges
            {
                target: background
                borderColor: UM.Theme.getColor("text_field_border_active")
                liningColor: UM.Theme.getColor("text_field_border_active")
            }
        },
        State
        {
            name: "highlighted"
            when: (control.hovered && !control.activeFocus) || forceHighlight
            PropertyChanges
            {
                target: background
                liningColor: UM.Theme.getColor("text_field_border_hovered")
            }
        }
    ]

    background: UM.UnderlineBackground
    {
        id: background
        // Rectangle for highlighting when this combobox needs to pulse.
        Rectangle
        {
            anchors.fill: parent
            opacity: 0
            color: "transparent"

            border.color: UM.Theme.getColor("text_field_border_active")
            border.width: UM.Theme.getSize("default_lining").width

            SequentialAnimation on opacity
            {
                id: pulseAnimation
                running: false
                loops: 2
                PropertyAnimation
                {
                    to: 1
                    duration: 150
                }
                PropertyAnimation
                {
                    to: 0
                    duration : 150
                }
            }
        }
    }

    down.indicator: UM.ColorImage
    {
        id: downArrow
        x: control.mirrored ? parent.width - width : 0

        source: UM.Theme.getIcon("ChevronSingleDown")
        width: UM.Theme.getSize("standard_arrow").width
        height: UM.Theme.getSize("standard_arrow").height

        color: UM.Theme.getColor("setting_control_button")
    }

    up.indicator: UM.ColorImage
    {
        id: upArrow
        x: control.mirrored ? 0 : parent.width - width

        source: UM.Theme.getIcon("ChevronSingleUp")
        width: UM.Theme.getSize("standard_arrow").width
        height: UM.Theme.getSize("standard_arrow").height

        color: UM.Theme.getColor("setting_control_button")
    }

    contentItem: UM.Label
    {
        id: contentLabel
        leftPadding: contentLeftPadding + UM.Theme.getSize("default_margin").width
        anchors.right: downArrow.left
        wrapMode: Text.NoWrap
        font: textFont
        text:
        {
            if (control.delegateModel.count == 0)
            {
                return control.defaultTextOnEmptyModel != "" ? control.defaultTextOnEmptyModel : control.defaultTextOnEmptyIndex
            }
            else
            {
                return control.currentIndex == -1 ? control.defaultTextOnEmptyIndex : control.currentText
            }
        }

        textFormat: Text.PlainText
        color: control.currentIndex == -1 ? UM.Theme.getColor("setting_control_disabled_text") : UM.Theme.getColor("setting_control_text")
        elide: Text.ElideRight
    }

    function pulse()
    {
        pulseAnimation.restart();
    }
}
