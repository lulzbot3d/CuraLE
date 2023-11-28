// Copyright (c) 2023 Fargo Additive Manufacturing Equipment 3D, LLC
// Cura LE is released under the terms of the LGPLv3 or higher.

import QtQuick 2.11
import QtQuick.Controls 1.1
import UM 1.2 as UM
import Cura 1.0 as Cura

Item {
    id: filamentChangeIconItem

    implicitWidth: UM.Theme.getSize("extruder_icon").width
    implicitHeight: UM.Theme.getSize("extruder_icon").height

    property bool checked: true
    property alias iconSize: mainIcon.sourceSize
    property string iconVariant: "default"

    Item {
        id: icon
        anchors.fill: parent

        property int changeLayerCount: {
            let layers = provider.properties.value;
            let layer_count = 0;
            if (layers) {
                layer_count = layers.split(",").length;
            };
            return layer_count;
        }

        UM.RecolorImage {
            id: mainIcon
            anchors.fill: parent
            sourceSize: UM.Theme.getSize("extruder_icon", iconVariant)
            color: UM.Theme.getColor("icon")

            source: UM.Theme.getIcon("Spool")
        }

        Cura.NotificationIcon {
            id: activeFilamentChangeIcon
            visible: icon.changeLayerCount > 0
            anchors {
                horizontalCenter: parent.right
                verticalCenter: parent.top
            }

            labelText: icon.changeLayerCount
        }
    }

    UM.SettingPropertyProvider {
        id: provider
        containerStackId: Cura.FilamentChangeManager.currentStackId
        key: "layer_number"
        watchedProperties: [ "value" ]
    }
}
