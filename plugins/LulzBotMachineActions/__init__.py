from . import ChangeToolHead

from UM.i18n import i18nCatalog
catalog = i18nCatalog("cura")

def getMetaData():
    return {
        "plugin": {
            "name": catalog.i18nc("@label", "LulzBot machine actions"),
            "author": "Aleph Objects Inc",
            "version": "1.0",
            "description": catalog.i18nc("@info:whatsthis", "Provides machine actions for LulzBot machines"),
            "api": 3
        }
    }

def register(app):
    return { "machine_action": [ChangeToolHead.ChangeToolHeadMachineAction()]}
