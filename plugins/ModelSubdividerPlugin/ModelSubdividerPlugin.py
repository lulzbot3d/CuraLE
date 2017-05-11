# Copyright (c) 2017 Aleph Objects, Inc.
# Cura is released under the terms of the AGPLv3 or higher.

from UM.Application import Application
from UM.Extension import Extension
from UM.Scene.Plane import Plane
from UM.i18n import i18nCatalog
from UM.Operations.AddSceneNodeOperation import AddSceneNodeOperation
from UM.Scene.Selection import Selection
from UM.Logger import Logger
from UM.Scene.SceneNode import SceneNode
from UM.Operations.GroupedOperation import GroupedOperation
from UM.Operations.RemoveSceneNodeOperation import RemoveSceneNodeOperation

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
        operation.push()

    def subdivide(self):
        if Selection.getCount() != 2:
            Logger.log("w", i18n_catalog.i18n("Cannot subdivide: objects != 2"))
            return
        object1 = Selection.getSelectedObject(0)
        object2 = Selection.getSelectedObject(1)
        if type(object1) is SceneNode and type(object2) is Plane:
            obj = object1
            plane = object2
        elif type(object2) is SceneNode and type(object1) is Plane:
            obj = object2
            plane = object1
        else:
            Logger.log("w", i18n_catalog.i18n("Cannot subdivide: object and plane need to be selected"))
            return

        operation = GroupedOperation()
        operation.addOperation(RemoveSceneNodeOperation(plane))
        # operation.addOperation(RemoveSceneNodeOperation(obj))
        # operation.addOperation(AddSceneNodeOperation(obj, obj.getParent()))
        operation.push()
