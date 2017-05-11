# Copyright (c) 2017 Aleph Objects, Inc.
# Cura is released under the terms of the AGPLv3 or higher.

from UM.Application import Application
from UM.Extension import Extension
from UM.Scene.Plane import Plane
from UM.i18n import i18nCatalog
from UM.Operations.AddSceneNodeOperation import AddSceneNodeOperation

i18n_catalog = i18nCatalog("ModelSubdividerPlugin")


class ModelSubdividerPlugin(Extension):
    def __init__(self):
        super().__init__()
        self.addMenuItem(i18n_catalog.i18n("Create plane"), self.createPlane)
        self.addMenuItem(i18n_catalog.i18n("Subdivide mesh by plane"), self.subdivide)

    def createPlane(self):
        plane = Plane()
        scene = Application.getInstance().getController().getScene()
        operation = AddSceneNodeOperation(plane, scene.getRoot())
        Application.getInstance().getOperationStack().push(operation)

    def subdivide(self):
        pass
