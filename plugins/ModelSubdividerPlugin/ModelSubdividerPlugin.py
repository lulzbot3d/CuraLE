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
from UM.Operations.TranslateOperation import TranslateOperation
from UM.Mesh.MeshBuilder import MeshBuilder
import numpy
import math
import time

i18n_catalog = i18nCatalog("ModelSubdividerPlugin")


class IntersectionType:
    Point = 0
    Segment = 1
    Edge = 2
    Face = 3
    PointAndSegment = 4


class ModelSubdividerPlugin(Extension):
    epsilon = 1e-4

    def __init__(self):
        super().__init__()
        self.addMenuItem(i18n_catalog.i18n("Create Plane"), self.createPlane)
        self.addMenuItem(i18n_catalog.i18n("Subdivide Mesh by Plane"), self.subdivide)

    def createPlane(self):
        plane = Plane()
        scene = Application.getInstance().getController().getScene()
        operation = AddSceneNodeOperation(plane, scene.getRoot())
        operation.push()

    def subdivide(self):
        if Selection.getCount() != 2:
            Logger.log("w", i18n_catalog.i18n("Cannot subdivide: number of selected objects is not equal 2. Plane and object need to be selected. Current selected objects: %i") % Selection.getCount())
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
            Logger.log("w", i18n_catalog.i18n("Cannot subdivide: object and plane need to be selected. Current selection: %s and %s") % (str(object1), str(object2)))
            return

        result = self._subdivide(obj, plane)
        if type(result) is tuple:
            operation = GroupedOperation()
            operation.addOperation(RemoveSceneNodeOperation(plane))
            operation.addOperation(RemoveSceneNodeOperation(obj))
            operation.addOperation(AddSceneNodeOperation(result[0], obj.getParent()))
            operation.addOperation(TranslateOperation(result[0], obj.getPosition()))
            if len(result) == 2:
                operation.addOperation(AddSceneNodeOperation(result[1], obj.getParent()))
                operation.addOperation(TranslateOperation(result[1], obj.getPosition()))
            operation.push()
        else:
            Logger.log("w", i18n_catalog.i18n("Cannot subdivide: Internal error"))

    def _subdivide(self, mesh, plane):
        start_time = time.time()
        plane_mesh_data = plane.getMeshData()
        plane_vertices = plane_mesh_data.getVertices()
        plane_face = [plane_vertices[0], plane_vertices[1], plane_vertices[2]]
        builders = [MeshBuilder(), MeshBuilder()]
        mesh_data = mesh.getMeshData()
        vertices = mesh_data.getVertices()
        indices = mesh_data.getIndices()
        faces = []
        if indices:
            for index_array in indices:
                faces.append([vertices[index_array[0]], vertices[index_array[1]], vertices[index_array[2]]])
        else:
            for i in range(0, len(vertices), 3):
                faces.append([vertices[i], vertices[i+1], vertices[i+2]])
        for f in faces:
            intersection_type = self.check_intersection_with_triangle(plane_face, f)
            if intersection_type is None or (intersection_type is not None and intersection_type[0] in [IntersectionType.Point, IntersectionType.Edge]):
                side = self.check_plane_side(plane_face, f)
                if side is not None:
                    self.add_face_to_builder(builders[side], f)
                else:
                    Logger.log("w", "Invalid face detected: " + str(f))
            elif intersection_type[0] == IntersectionType.Face:
                self.add_face_to_builder(builders[0], f)
                self.add_face_to_builder(builders[1], f)
            elif intersection_type[0] == IntersectionType.Segment:
                new_faces = self.split_triangle(f, intersection_type[1])
                for new_face in new_faces:
                    self.add_face_to_builder(builders[self.check_plane_side(plane_face, new_face)], new_face)
            elif intersection_type[0] == IntersectionType.PointAndSegment:
                new_faces = self.split_triangle_in_one_segment(f, intersection_type[1])
                for new_face in new_faces:
                    self.add_face_to_builder(builders[self.check_plane_side(plane_face, new_face)], new_face)
        nodes = [SceneNode(), SceneNode()]
        for n in range(len(nodes)):
            builders[n].calculateNormals()
            nodes[n].setMeshData(builders[n].build())
            nodes[n].setSelectable(True)
            nodes[n].setScale(mesh.getScale())
        Logger.log("w", i18n_catalog.i18n("Subdivision took %f seconds") % (time.time()-start_time))
        return nodes[0], nodes[1]

    def split_triangle(self, face, intersection):
        intersection_points = [intersection[0][0], intersection[1][0]]
        intersection_indices = [intersection[0][1], intersection[1][1]]
        new_faces = []
        common_index = 0
        for i in intersection_indices[0]:
            for i2 in intersection_indices[1]:
                if i == i2:
                    common_index = i
        new_faces.append([face[common_index], intersection_points[0], intersection_points[1]])
        other_index = common_index + 1 if common_index < 2 else 0
        new_faces.append([face[other_index], intersection_points[0], intersection_points[1]])
        third_index = other_index + 1 if other_index < 2 else 0
        third_point = None
        for i in range(len(intersection_indices)):
            if intersection_indices[i][0] == common_index and intersection_indices[i][1] == third_index or \
                    intersection_indices[i][1] == common_index and intersection_indices[i][0] == third_index:
                third_point = intersection_points[i]
                break
        new_faces.append([face[other_index], face[third_index], third_point])
        return new_faces

    def split_triangle_in_one_segment(self, face, intersection):
        point = intersection[0]
        intersection_point = intersection[1][0]
        intersection_indices = [intersection[1][1][0], intersection[1][1][1]]
        new_faces = []
        new_faces.append([point, intersection_point, face[intersection_indices[0]]])
        new_faces.append([point, face[intersection_indices[1]], intersection_point])
        return new_faces

    def add_face_to_builder(self, builder, face):
        builder.addFaceByPoints(face[0][0], face[0][1], face[0][2],
                                face[1][0], face[1][1], face[1][2],
                                face[2][0], face[2][1], face[2][2])

    def vector_length(self, vector):
        return math.sqrt(vector[0]**2+vector[1]**2+vector[2]**2)

    def check_plane_side(self, plane_face, face):
        n = numpy.cross(plane_face[1] - plane_face[0], plane_face[2] - plane_face[0])
        n /= numpy.linalg.norm(n)
        vn = [plane_face[0] - face[0], plane_face[0] - face[1], plane_face[0] - face[2]]
        dn = [(1 if numpy.inner(n, vn[0]) >= 0 else -1), (1 if numpy.inner(n, vn[1]) >= 0 else -1), (1 if numpy.inner(n, vn[2]) >= 0 else -1)]
        v = [face[0] - plane_face[0], face[1] - plane_face[0], face[2] - plane_face[0]]
        d = [self.vector_length(numpy.multiply(n, v[0])) * dn[0], self.vector_length(numpy.multiply(n, v[1])) * dn[1], self.vector_length(numpy.multiply(n, v[2])) * dn[2]]
        points_front = 0
        points_back = 0
        for i in range(3):
            if d[i] > self.epsilon:
                points_front += 1
            elif d[i] < -self.epsilon:
                points_back += 1
        if points_front > 0 and points_back > 0:
            return None
        return 0 if points_front > points_back else 1

    def distance_between_points(self, point1, point2):
        return math.sqrt((point1[0]-point2[0])**2+(point1[1]-point2[1])**2+(point1[2]-point2[2])**2)

    def is_point_in_plane(self, plane_face, point):
        n = numpy.cross(plane_face[1] - plane_face[0], plane_face[2] - plane_face[0])
        n /= numpy.linalg.norm(n)
        v = point - plane_face[0]
        d = self.vector_length(numpy.multiply(n, v))
        if math.fabs(d) <= self.epsilon:
            return True
        return False

    def check_intersection_with_triangle(self, plane_face, face):
        intersection_points = []
        for i in range(3):
            if self.is_point_in_plane(plane_face, face[i]):
                intersection_points.append(i)
        if len(intersection_points) == 1:
            if self.check_plane_side(plane_face, face) is not None:
                return IntersectionType.Point,
            else:
                ind = list(range(3))
                ind.remove(intersection_points[0])
                segment = [face[ind[0]], face[ind[1]]]
                point = self.check_intersection_with_segment(plane_face, segment)
                if point is not None:
                    intersection_points.append([point, [ind[0], ind[1]]])
                    intersection_points[0] = face[intersection_points[0]]
                    return IntersectionType.PointAndSegment, intersection_points
        elif len(intersection_points) == 2:
            return IntersectionType.Edge,
        elif len(intersection_points) == 3:
            return IntersectionType.Face, face

        for i in range(3):
            i2 = i + 1 if i < 2 else 0
            segment = [face[i], face[i2]]
            point = self.check_intersection_with_segment(plane_face, segment)
            if point is not None:
                intersection_points.append([point, [i, i2]])
        if len(intersection_points) == 2:
            return IntersectionType.Segment, intersection_points
        return None

    def check_intersection_with_segment(self, plane_face, segment):
        n = numpy.cross(plane_face[1] - plane_face[0], plane_face[2] - plane_face[0])
        v = plane_face[0] - segment[0]
        d = numpy.inner(n, v)
        w = segment[1] - segment[0]
        e = numpy.inner(n, w)
        if math.fabs(e) > self.epsilon:
            o = segment[0] + w * d / e
            if numpy.inner(segment[0] - o, segment[1] - o) <= 0:
                return o
        return None
