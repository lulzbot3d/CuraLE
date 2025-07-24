# Copyright (c) 2015 Ultimaker B.V.
# Uranium is released under the terms of the LGPLv3 or higher.

from . import FilamentChangeTool
# from . import FilamentChangeHandler
from PyQt6.QtQml import qmlRegisterType

from UM.i18n import i18nCatalog
i18n_catalog = i18nCatalog("cura")

def getMetaData():
    # return {
    #     "tool": {
    #         "name": i18n_catalog.i18nc("@label", "Filament Change"),
    #         "description": i18n_catalog.i18nc("@info:tooltip", "Configure Per Model Settings"),
    #         "icon": "ChangeFilament",
    #         "tool_panel": "FilamentChangePanel.qml",
    #         "weight": 3
    #     },
    # }
    return {}

def register(app):
    # qmlRegisterType(FilamentChangeTool.FilamentChangeTool, "Cura", 1, 0,
    #                 "FilamentChangeTool")
    # return { "tool": FilamentChangeTool.FilamentChangeTool() }
    return {}