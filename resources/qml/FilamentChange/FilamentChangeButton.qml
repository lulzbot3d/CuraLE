// Copyright (c) 2023 Fargo Additive Manufacturing Equipment 3D, LLC
// Cura LE is released under the terms of the LGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 2.3

import UM 1.2 as UM
import Cura 1.0 as Cura

Cura.ToolbarButton {
    id: base

    text: "Filament Change"

    toolItem: Cura.FilamentChangeIcon {
        iconVariant: "default"
    }
}
