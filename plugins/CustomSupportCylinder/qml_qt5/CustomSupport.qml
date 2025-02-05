//-----------------------------------------------------------------------------
// Copyright (c) 2022 5@xes
//
// proterties values
//   "SSize"       : Support Size in mm
//   "MSize"       : Support Maximum Size in mm
//   "ISize"       : Support Interior Size in mm
//   "AAngle"      : Support Angle in °
//   "YDirection"  : Support Y direction (Abutment)
//   "EHeights"    : Equalize heights (Abutment)
//   "SMain"       : Scale Main direction (Freeform)
//   "SType"       : Support Type ( Cylinder/Tube/Cube/Abutment/Freeform/Custom )
//   "SubType"     : Support Freeform Type ( Cross/Section/Pillar/Bridge/Custom )
//   "SMirror"     : Support Mirror for Freeform Type
//-----------------------------------------------------------------------------

import QtQuick 2.2
import QtQuick.Controls 1.2

import UM 1.1 as UM

Item
{
    id: base
    width: childrenRect.width
    height: childrenRect.height
    UM.I18nCatalog { id: catalog; name: "customsupport"}

    property var s_size: UM.Controller.properties.getValue("SSize")

    function setSType(type)
    {
        // set checked state of mesh type buttons
        cylinderButton.checked = type === 'cylinder'
        tubeButton.checked = type === 'tube'
        cubeButton.checked = type === 'cube'
        abutmentButton.checked = type === 'abutment'
        customButton.checked = type === 'custom'
        freeformButton.checked = type === 'freeform'
        UM.Controller.setProperty("SType", type)
    }

    Column
    {
        id: sTypeItems
        anchors.top: parent.top;
        anchors.left: parent.left;
        spacing: UM.Theme.getSize("default_margin").height;

        Row // Mesh type buttons
        {
            id: sTypeButtons
            spacing: UM.Theme.getSize("default_margin").width

            Button
            {
                id: cylinderButton
                text: catalog.i18nc("@label", "Cylinder")
                iconSource: "type_cylinder.svg"
                property bool needBorder: true
                checkable:true
                onClicked: setSType('cylinder')
                style: UM.Theme.styles.tool_button
                checked: UM.Controller.properties.getValue("SType") === 'cylinder'
                z: 6; // Depth position
            }

            Button
            {
                id: tubeButton
                text: catalog.i18nc("@label", "Tube");
                iconSource: "type_tube.svg";
                property bool needBorder: true;
                checkable:true;
                onClicked: setSType('tube');
                style: UM.Theme.styles.tool_button;
                checked: UM.Controller.properties.getValue("SType") === 'tube';
                z: 5; // Depth position
            }

            Button
            {
                id: cubeButton;
                text: catalog.i18nc("@label", "Cube")
                iconSource: "type_cube.svg"
                property bool needBorder: true
                checkable: true
                onClicked: setSType('cube')
                style: UM.Theme.styles.tool_button
                checked: UM.Controller.properties.getValue("SType") === 'cube'
                z: 4; // Depth position
            }

            Button
            {
                id: abutmentButton
                text: catalog.i18nc("@label", "Abutment")
                iconSource: "type_abutment.svg"
                property bool needBorder: true
                checkable: true
                onClicked: setSType('abutment')
                style: UM.Theme.styles.tool_button
                checked: UM.Controller.properties.getValue("SType") === 'abutment'
                z: 3; // Depth position
            }

            Button
            {
                id: freeformButton
                text: catalog.i18nc("@label", "Freeform")
                iconSource: "type_freeform.svg"
                property bool needBorder: true
                checkable:true
                onClicked: setSType('freeform')
                style: UM.Theme.styles.tool_button
                checked: UM.Controller.properties.getValue("SType") === 'freeform'
                z: 2; // Depth position
            }

            Button
            {
                id: customButton
                text: catalog.i18nc("@label", "Custom")
                iconSource: "type_custom.svg"
                property bool needBorder: true
                checkable:true
                onClicked: setSType('custom')
                style: UM.Theme.styles.tool_button
                checked: UM.Controller.properties.getValue("SType") === 'custom'
                z: 1; // Depth position
            }
        }
    }
    Grid
    {
        id: textfields;
        anchors.leftMargin: UM.Theme.getSize("default_margin").width
        anchors.top: sTypeItems.bottom
        anchors.topMargin: UM.Theme.getSize("default_margin").height

        columns: 2
        flow: Grid.TopToBottom
        spacing: Math.round(UM.Theme.getSize("default_margin").width / 2)

        Label
        {
            height: UM.Theme.getSize("setting_control").height
            text: catalog.i18nc("@label","Size")
            font: UM.Theme.getFont("default")
            color: UM.Theme.getColor("text")
            verticalAlignment: Text.AlignVCenter
            renderType: Text.NativeRendering
            width: Math.ceil(contentWidth) //Make sure that the grid cells have an integer width.
        }

        Label
        {
            height: UM.Theme.getSize("setting_control").height
            text: catalog.i18nc("@label","Max Size")
            font: UM.Theme.getFont("default")
            color: UM.Theme.getColor("text")
            verticalAlignment: Text.AlignVCenter
            visible: !freeformButton.checked
            renderType: Text.NativeRendering
            width: Math.ceil(contentWidth) //Make sure that the grid cells have an integer width.
        }

        Label
        {
            height: UM.Theme.getSize("setting_control").height
            text: catalog.i18nc("@label","Type")
            font: UM.Theme.getFont("default")
            color: UM.Theme.getColor("text")
            verticalAlignment: Text.AlignVCenter
            visible: freeformButton.checked
            renderType: Text.NativeRendering
            width: Math.ceil(contentWidth) //Make sure that the grid cells have an integer width.
        }

        Label
        {
            height: UM.Theme.getSize("setting_control").height
            text: catalog.i18nc("@label","Interior Size")
            font: UM.Theme.getFont("default")
            color: UM.Theme.getColor("text")
            verticalAlignment: Text.AlignVCenter
            renderType: Text.NativeRendering
            visible: tubeButton.checked
            width: Math.ceil(contentWidth) //Make sure that the grid cells have an integer width.
        }

        Label
        {
            height: UM.Theme.getSize("setting_control").height
            text: catalog.i18nc("@label","Angle")
            font: UM.Theme.getFont("default")
            color: UM.Theme.getColor("text")
            verticalAlignment: Text.AlignVCenter
            visible: !freeformButton.checked
            renderType: Text.NativeRendering
            width: Math.ceil(contentWidth) //Make sure that the grid cells have an integer width.
        }

        TextField
        {
            id: sizeTextField
            width: UM.Theme.getSize("setting_control").width
            height: UM.Theme.getSize("setting_control").height
            property string unit: "mm"
            style: UM.Theme.styles.text_field;
            text: {
                let val = UM.Controller.properties.getValue("SSize")
                return val != null ? val : ""
            }
            validator: DoubleValidator
            {
                decimals: 2
                bottom: 0.1
                locale: "en_US"
            }

            onEditingFinished:
            {
                var modified_text = text.replace(",", ".") // User convenience. We use dots for decimal values
                UM.Controller.setProperty("SSize", modified_text)
            }
        }

        TextField
        {
            id: maxTextField
            width: UM.Theme.getSize("setting_control").width
            height: UM.Theme.getSize("setting_control").height
            property string unit: "mm"
            style: UM.Theme.styles.text_field
            visible: !freeformButton.checked
            text: {
                let val = UM.Controller.properties.getValue("MSize")
                return val != null ? val : ""
            }
            validator: DoubleValidator
            {
                decimals: 2
                bottom: 0
                locale: "en_US"
            }

            onEditingFinished:
            {
                var modified_text = text.replace(",", ".") // User convenience. We use dots for decimal values
                UM.Controller.setProperty("MSize", modified_text);
            }
        }

        ComboBox {
            id: supportComboType
            objectName: "Support_Type"
            model: ListModel {
               id: cbItems
               ListElement { text: "cross"}
               ListElement { text: "section"}
               ListElement { text: "pillar"}
               ListElement { text: "bridge"}
               ListElement { text: "arch-buttress"}
               ListElement { text: "t-support"}
               ListElement { text: "custom"}
            }
            width: UM.Theme.getSize("setting_control").width
            height: UM.Theme.getSize("setting_control").height
            visible: freeformButton.checked
            Component.onCompleted: currentIndex = find(UM.Controller.properties.getValue("SubType"))

            onCurrentIndexChanged:
            {
                UM.Controller.setProperty("SubType",cbItems.get(currentIndex).text);
            }
        }

        TextField {
            id: sizeInteriorTextField
            width: UM.Theme.getSize("setting_control").width
            height: UM.Theme.getSize("setting_control").height
            property string unit: "mm"
            style: UM.Theme.styles.text_field
            visible: tubeButton.checked
            text: {
                let val = UM.Controller.properties.getValue("ISize")
                return val != null ? val : ""
            }
            validator: DoubleValidator
            {
                decimals: 2
                top: s_size != null ? s_size : 0.1
                bottom: 0.1
                locale: "en_US"
            }

            onEditingFinished:
            {
                var cur_text = parseFloat(text)
                if ( cur_text >= s_size )
                {
                }
                var modified_text = text.replace(",", ".") // User convenience. We use dots for decimal values
                UM.Controller.setProperty("ISize", modified_text)
            }
        }

        TextField {
            id: angleTextField
            width: UM.Theme.getSize("setting_control").width
            height: UM.Theme.getSize("setting_control").height
            property string unit: "°"
            style: UM.Theme.styles.text_field
            visible: !freeformButton.checked
            text: {
                let val = UM.Controller.properties.getValue("AAngle")
                return val != null ? val : ""
            }
            validator: IntValidator
            {
                bottom: 0
            }

            onEditingFinished:
            {
                var modified_angle_text = text.replace(",", ".") // User convenience. We use dots for decimal values
                UM.Controller.setProperty("AAngle", modified_angle_text)
            }
        }
    }

    Item {
        id: baseCheckBox
        width: childrenRect.width
        height: !freeformButton.checked && !abutmentButton.checked  ? 0 : (abutmentButton.checked ? (UM.Theme.getSize("setting_control").height*2+UM.Theme.getSize("default_margin").height): childrenRect.height)
        anchors.leftMargin: UM.Theme.getSize("default_margin").width
        anchors.top: textfields.bottom
        anchors.topMargin: UM.Theme.getSize("default_margin").height

        CheckBox {
            id: useYDirectionCheckbox
            anchors.top: baseCheckBox.top
            // anchors.topMargin: UM.Theme.getSize("default_margin").height
            anchors.left: parent.left
            text: catalog.i18nc("@option:check","Set on Y direction")
            style: UM.Theme.styles.partially_checkbox
            visible: abutmentButton.checked || freeformButton.checked

            checked: {
                let val = UM.Controller.properties.getValue("YDirection")
                return val != null ? val : false
            }
            onClicked: UM.Controller.setProperty("YDirection", checked)

        }

        CheckBox {
            id: mirrorCheckbox
            anchors.top: useYDirectionCheckbox.bottom
            anchors.topMargin: UM.Theme.getSize("default_margin").height
            anchors.left: parent.left
            text: catalog.i18nc("@option:check","Rotate 180°")
            style: UM.Theme.styles.partially_checkbox
            visible: freeformButton.checked

            checked: {
                let val = UM.Controller.properties.getValue("SMirror")
                return val != null ? val : false
            }
            onClicked: UM.Controller.setProperty("SMirror", checked)

        }

        CheckBox {
            id: scaleMainDirectionCheckbox
            anchors.top: mirrorCheckbox.bottom
            anchors.topMargin: UM.Theme.getSize("default_margin").height
            anchors.left: parent.left
            text: catalog.i18nc("@option:check","Scaling in main Directions")
            style: UM.Theme.styles.partially_checkbox
            visible: freeformButton.checked

            checked: {
                let val = UM.Controller.properties.getValue("SMain")
                return val != null ? val : false
            }
            onClicked: UM.Controller.setProperty("SMain", checked)
        }

        CheckBox {
            id: equalizeHeightsCheckbox
            anchors.top: useYDirectionCheckbox.bottom
            anchors.topMargin: UM.Theme.getSize("default_margin").height
            anchors.left: parent.left
            text: catalog.i18nc("@option:check","Equalize heights")
            style: UM.Theme.styles.partially_checkbox
            visible: abutmentButton.checked

            checked: {
                let val = UM.Controller.properties.getValue("EHeights")
                return val != null ? val : false
            }
            onClicked: UM.Controller.setProperty("EHeights", checked)
        }
    }

    Rectangle {
        id: rightRect
        anchors.top: baseCheckBox.bottom
        //color: UM.Theme.getColor("toolbar_background")
        color: "#00000000"
        width: UM.Theme.getSize("setting_control").width * 1.8
        height: UM.Theme.getSize("setting_control").height
        anchors.left: parent.left
        anchors.topMargin: UM.Theme.getSize("default_margin").height
    }

    Button {
        id: removeAllButton
        anchors.centerIn: rightRect
        width: UM.Theme.getSize("setting_control").width
        height: UM.Theme.getSize("setting_control").height
        text: catalog.i18nc("@label", UM.Controller.properties.getValue("SMsg"))
        style: UM.Theme.styles.toolbox_action_button
        onClicked: UM.Controller.triggerAction("removeAllSupportMesh")
    }

    CheckBox {
        id: ensureKeptApartCheckbox
        anchors {
            left: rightRect.right
            verticalCenter: rightRect.verticalCenter
        }
        text: catalog.i18nc("@option:check", "Ensure Models/Supports Kept Apart")
        style: UM.Theme.styles.partially_checkbox

        checked: UM.Preferences.getValue("physics/automatic_push_free")
        onCheckedChanged: UM.Preferences.setValue("physics/automatic_push_free", checked)
    }
}
