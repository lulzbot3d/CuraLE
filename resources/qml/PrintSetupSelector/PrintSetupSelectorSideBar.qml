// Copyright (c) 2018 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3

import UM 1.2 as UM
import Cura 1.0 as Cura

Component {

    Item {

        Rectangle {
            color: UM.Theme.getColor("main_background")
            anchors.right: parent.right
            width: parent.width * 0.25
            anchors.top: parent.top
            anchors.bottom: parent.bottom

        }
    }
}