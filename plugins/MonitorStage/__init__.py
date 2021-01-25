# Copyright (c) 2017 Ultimaker B.V.
# Cura is released under the terms of the LGPLv3 or higher.

from . import MonitorStage

from UM.i18n import i18nCatalog
from PyQt5.QtQml import qmlRegisterSingletonType
from .MonitorStageStorage import MonitorStageStorage

i18n_catalog = i18nCatalog("cura")

def getMetaData():
    return {
        "stage": {
            "name": i18n_catalog.i18nc("@item:inmenu", "Monitor"),
            "weight": 1
        }
    }

def register(app):
    qmlRegisterSingletonType(MonitorStageStorage, "Cura", 1, 0, "MonitorStageStorage",
                             MonitorStageStorage.getInstance)
    return {
        "stage": MonitorStage.MonitorStage()
    }
