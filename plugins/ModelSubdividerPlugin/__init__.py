# Copyright (c) 2017 Aleph Objects, Inc.
# Cura is released under the terms of the AGPLv3 or higher.

from . import ModelSubdividerPlugin

from UM.i18n import i18nCatalog
i18n_catalog = i18nCatalog("cura")

def getMetaData():
    return {
        "plugin": {
            "name": i18n_catalog.i18nc("@label", "Model Subdivider Plugin (Experimental)"),
            "author": "Victor Larchenko",
            "version": "1.0",
            "description": i18n_catalog.i18nc("@info:whatsthis", "Allows subdividing meshes in cura."),
            "api": 3
        }
    }

def register(app):
    return {"extension": ModelSubdividerPlugin.ModelSubdividerPlugin()}
