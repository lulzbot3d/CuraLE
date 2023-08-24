import QtQuick 2.10
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3

import UM 1.3 as UM
import Cura 1.6 as Cura
import ".."
import "../Custom"

Item {
    id: intent
    height: childrenRect.height

    anchors {
        left: parent.left
        right: parent.right
    }

    Label {
        id: profileLabel
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            right: intentSelection.left
        }
        text: catalog.i18nc("@label", "Profile")
        font: UM.Theme.getFont("medium")
        renderType: Text.NativeRendering
        color: UM.Theme.getColor("text")
        verticalAlignment: Text.AlignVCenter
    }

    NoIntentIcon {
        affected_extruders: Cura.MachineManager.extruderPositionsWithNonActiveIntent
        intent_type: Cura.MachineManager.activeIntentCategory
        anchors.right: intentSelection.left
        anchors.rightMargin: UM.Theme.getSize("narrow_margin").width
        width: Math.round(profileLabel.height * 0.5)
        anchors.verticalCenter: parent.verticalCenter
        height: width
        visible: affected_extruders.length
    }

    Button {
        id: intentSelection
        onClicked: menu.opened ? menu.close() : menu.open()

        anchors.right: parent.right
        width: UM.Theme.getSize("print_setup_big_item").width
        height: textLabel.contentHeight + 2 * UM.Theme.getSize("narrow_margin").height
        hoverEnabled: true

        contentItem: RowLayout {
            spacing: 0
            anchors.left: parent.left
            anchors.right: customisedSettings.left
            anchors.leftMargin: UM.Theme.getSize("default_margin").width

            Label {
                id: textLabel
                text: Cura.MachineManager.activeQualityDisplayNameMap["main"]
                font: UM.Theme.getFont("default")
                color: UM.Theme.getColor("text")
                Layout.margins: 0
                Layout.maximumWidth: Math.floor(parent.width * 0.7)  // Always leave >= 30% for the rest of the row.
                height: contentHeight
                verticalAlignment: Text.AlignVCenter
                renderType: Text.NativeRendering
                elide: Text.ElideRight
            }

            Label {
                text: activeQualityDetailText()
                font: UM.Theme.getFont("default")
                color: UM.Theme.getColor("text_detail")
                Layout.margins: 0
                Layout.fillWidth: true

                height: contentHeight
                verticalAlignment: Text.AlignVCenter
                renderType: Text.NativeRendering
                elide: Text.ElideRight

                function activeQualityDetailText() {
                    var resultMap = Cura.MachineManager.activeQualityDisplayNameMap
                    var resultSuffix = resultMap["suffix"]
                    var result = ""

                    if (Cura.MachineManager.isActiveQualityExperimental) {
                        resultSuffix += " (Experimental)"
                    }

                    if (Cura.MachineManager.isActiveQualitySupported) {
                        if (Cura.MachineManager.activeQualityLayerHeight > 0) {
                            if (resultSuffix) {
                                result += " - " + resultSuffix
                            }
                            result += " - "
                            result += Cura.MachineManager.activeQualityLayerHeight + "mm"
                        }
                    }
                    return result
                }
            }
        }

        background: Rectangle {
            id: backgroundItem
            border.color: intentSelection.hovered ? UM.Theme.getColor("setting_control_border_highlight") : UM.Theme.getColor("setting_control_border")
            border.width: UM.Theme.getSize("default_lining").width
            radius: UM.Theme.getSize("default_radius").width
            color: UM.Theme.getColor("main_background")
        }

        UM.SimpleButton {
            id: customisedSettings

            visible: Cura.MachineManager.hasUserSettings
            width: UM.Theme.getSize("print_setup_icon").width
            height: UM.Theme.getSize("print_setup_icon").height

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: downArrow.left
            anchors.rightMargin: UM.Theme.getSize("default_margin").width

            color: hovered ? UM.Theme.getColor("setting_control_button_hover") : UM.Theme.getColor("setting_control_button");
            iconSource: UM.Theme.getIcon("StarFilled")

            onClicked: {
                forceActiveFocus();
                Cura.Actions.manageProfiles.trigger()
            }
            onEntered: {
                var content = catalog.i18nc("@tooltip", "Some setting/override values are different from the values stored in the profile.\n\nClick to open the profile manager.")
                base.showTooltip(intent, Qt.point(-UM.Theme.getSize("default_margin").width, 0), content)
            }
            onExited: base.hideTooltip()
        }
        UM.RecolorImage {
            id: downArrow

            source: UM.Theme.getIcon("ChevronSingleDown")
            width: UM.Theme.getSize("standard_arrow").width
            height: UM.Theme.getSize("standard_arrow").height

            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                rightMargin: UM.Theme.getSize("default_margin").width
            }

            color: UM.Theme.getColor("setting_control_button")
        }
    }

    QualitiesWithIntentMenu {
        id: menu
        y: intentSelection.y + intentSelection.height
        x: intentSelection.x
        width: intentSelection.width
    }
}