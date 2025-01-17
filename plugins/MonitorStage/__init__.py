# Copyright (c) 2017 Ultimaker B.V.
# Cura is released under the terms of the LGPLv3 or higher.

from PyQt6.QtQml import qmlRegisterSingletonType

from . import MonitorStage
from .MonitorStageStorage import MonitorStageStorage


from UM.i18n import i18nCatalog
i18n_catalog = i18nCatalog("cura")


def getMetaData():
    return {
        "stage": {
            "name": i18n_catalog.i18nc("@item:inmenu", "Monitor"),
            "weight": 30
        }
    }


def register(app):
    qmlRegisterSingletonType(MonitorStageStorage, "Cura", 1, 0, MonitorStageStorage.getInstance, "MonitorStageStorage")
    return {
        "stage": MonitorStage.MonitorStage()
    }
