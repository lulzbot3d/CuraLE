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
from UM.Mesh.MeshBuilder import MeshBuilder
import numpy
import math

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

        result = self._subdivide(obj, plane)
        if type(result) is tuple:
            operation = GroupedOperation()
            operation.addOperation(RemoveSceneNodeOperation(plane))
            operation.addOperation(RemoveSceneNodeOperation(obj))
            operation.addOperation(AddSceneNodeOperation(result[0], obj.getParent()))
            if len(result) == 2:
                operation.addOperation(AddSceneNodeOperation(result[1], obj.getParent()))
            operation.push()
        else:
            Logger.log("w", i18n_catalog.i18n("Cannot subdivide"))

    def _subdivide(self, mesh, plane):
        plane_mesh_data = plane.getMeshData()
        plane_vertices = plane_mesh_data.getVertices()
        plane_face = [plane_vertices[0], plane_vertices[1], plane_vertices[2]]
        builders = [MeshBuilder(), MeshBuilder()]
        mesh_data = mesh.getMeshData()
        vertices = mesh_data.getVertices()
        indices = mesh_data.getIndices()
        faces = []
        for i in range(0, len(indices), 3):
            faces.append([vertices[indices[i]], vertices[indices[i + 1]], vertices[indices[i + 2]]])
        intersected_faces = []
        for f in faces:
            intersected = False
            for i in range(3):
                i2 = i + 1 if i < 2 else 0
                segment = [f[i], f[i2]]
                if self.cross(plane_face, segment):
                    intersected = True
                    break
            if intersected:
                intersected_faces.append(f)
        print(intersected_faces)
        return mesh,

    def cross(self, plane_face, segment):
        epsilon = 1e-4
        n = numpy.cross(plane_face[1] - plane_face[0], plane_face[2] - plane_face[0])
        v = plane_face[0] - segment[0]
        d = numpy.inner(n, v)
        w = segment[1] - segment[0]
        e = numpy.inner(n, w)
        if math.fabs(e) > epsilon:
            o = segment[0] + w * d / e
            if numpy.inner(segment[0] - o, segment[1] - o) <= 0:
                return True
        return False
