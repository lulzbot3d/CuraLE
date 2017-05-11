# Copyright (c) 2017 Aleph Objects, Inc.
# Cura is released under the terms of the AGPLv3 or higher.

from UM.Extension import Extension
from UM.i18n import i18nCatalog

i18n_catalog = i18nCatalog("ModelSubdividerPlugin")


class ModelSubdividerPlugin(Extension):
    def __init__(self):
        super().__init__()
        self.addMenuItem(i18n_catalog.i18n("Create plane"), self.createPlane)
        self.addMenuItem(i18n_catalog.i18n("Subdivide mesh by plane"), self.subdivide)

    def createPlane(self):
        pass

    def subdivide(self):
        pass
