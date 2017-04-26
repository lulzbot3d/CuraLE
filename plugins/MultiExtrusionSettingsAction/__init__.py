# Copyright (c) 2017 Alephobjects

from . import MultiExtrusionSettingsAction

from UM.i18n import i18nCatalog
catalog = i18nCatalog("cura")

def getMetaData():
    return {
        "plugin": {
            "name": catalog.i18nc("@label", "Multi Extrusion Settings action"),
            "author": "alephobjects",
            "version": "1.0",
            "description": catalog.i18nc("@info:whatsthis", "Provides a way to change extruders settings (such as nozzle size, etc)"),
            "api": 3
        }
    }

def register(app):
    return { "machine_action": MultiExtrusionSettingsAction.MultiExtrusionSettingsAction() }
