# Copyright (c) 2015 Ultimaker B.V.
# Copyright (c) 2013 David Braam
# Uranium is released under the terms of the AGPLv3 or higher.

from UM.Mesh.MeshReader import MeshReader
from UM.Mesh.MeshBuilder import MeshBuilder
import os
from UM.Scene.SceneNode import SceneNode
from UM.Math.Vector import Vector
from UM.Math.AxisAlignedBox import AxisAlignedBox
from UM.Application import Application

from cura import LayerDataBuilder
from cura import LayerDataDecorator
from cura import LayerPolygon

import numpy


from UM.Job import Job

class GCODEReader(MeshReader):
    def __init__(self):
        super(GCODEReader, self).__init__()
        self._supported_extensions = [".gcode", ".g"]

    def getInt(self, line, code):
        n = line.find(code) + 1
        if n < 1:
            return None
        m = line.find(' ', n)
        m2 = line.find(';', n)
        if m < 0:
            m = m2
        try:
            if m < 0:
                return int(line[n:])
            return int(line[n:m])
        except:
            return None

    def getFloat(self, line, code):
        n = line.find(code) + 1
        if n < 1:
            return None
        m = line.find(' ', n)
        m2 = line.find(';', n)
        if m < 0:
            m = m2
        try:
            if m < 0:
                return float(line[n:])
            return float(line[n:m])
        except:
            return None

    def read(self, file_name):
        scene_node = None

        extension = os.path.splitext(file_name)[1]
        if extension.lower() in self._supported_extensions:
            scene_node = SceneNode()

            # mesh_builder = MeshBuilder()
            # mesh_builder.setFileName(file_name)
            #
            # mesh_builder.addCube(
            #     width=5,
            #     height=5,
            #     depth=5,
            #     center=Vector(0, 2.5, 0)
            # )
            #
            # scene_node.setMeshData(mesh_builder.build())

            # scene_node.getBoundingBox = getBoundingBox
            scene_node.gcode = True
            backend = Application.getInstance().getBackend()
            backend._pauseSlicing = True
            backend.backendStateChange.emit(0)

            file = open(file_name, "r")

            layer_data = LayerDataBuilder.LayerDataBuilder()

            layer_id = 0

            layer_data.addLayer(layer_id)
            this_layer = layer_data.getLayer(layer_id)
            layer_data.setLayerHeight(layer_id, 0)
            layer_data.setLayerThickness(layer_id, 0.1)

            current_extruder = 1
            current_path = []
            current_x = 0
            current_y = 0
            current_z = 0

            def CreatePolygon():
                count = len(current_path)
                line_types = numpy.empty((count-1, 1), numpy.int32)
                line_types[:, 0] = 1
                line_widths = numpy.empty((count-1, 1), numpy.int32)
                line_widths[:, 0] = 1
                points = numpy.empty((count, 3), numpy.float32)
                i = 0
                for point in current_path:
                    points[i, 0] = point[0]
                    points[i, 1] = point[1]
                    points[i, 2] = point[2]
                    i += 1

                this_poly = LayerPolygon.LayerPolygon(layer_data, current_extruder, line_types, points, line_widths)
                this_poly.buildCache()

                this_layer.polygons.append(this_poly)

                current_path.clear()

            # current_path.append([0, 0, 0])
            # current_path.append([10, 10, 10])
            # while file.readable():
            for line in file:
                if len(line) == 0:
                    continue
                if line[0] == ";":
                    continue
                G = self.getInt(line, "G")
                if G:
                    if G == 0 or G == 1:
                        x = self.getFloat(line, "X")
                        y = self.getFloat(line, "Y")
                        z = self.getFloat(line, "Z")
                        e = self.getFloat(line, "E")
                        if x:
                            current_x = x
                        if y:
                            current_y = y
                        if z:
                            current_z = z
                        if e and e > 0:
                            current_path.append([current_x, current_z, -current_y])
                        else:
                            if len(current_path) > 1:
                                CreatePolygon()
                    elif G == 92:
                        x = self.getFloat(line, "X")
                        y = self.getFloat(line, "Y")
                        z = self.getFloat(line, "Z")
                        if x:
                            current_x += x
                        if y:
                            current_y += y
                        if z:
                            current_z += z

            if len(current_path) > 1:
                CreatePolygon()

            layer_mesh = layer_data.build()
            decorator = LayerDataDecorator.LayerDataDecorator()
            decorator.setLayerData(layer_mesh)
            scene_node.addDecorator(decorator)

            scene_node_parent = Application.getInstance().getBuildVolume()
            scene_node.setParent(scene_node_parent)

            mesh_builder = MeshBuilder()
            mesh_builder.setFileName(file_name)

            mesh_builder.addCube(10, 10, 10, Vector(0, -5, 0))

            scene_node.setMeshData(mesh_builder.build())
            scene_node.setPosition(Vector(0,0,0))

            view = Application.getInstance().getController().getActiveView()
            if view.getPluginId() == "LayerView":
                view.resetLayerData()

            #scene_node.setEnabled(False)
            #scene_node.setSelectable(False)

        return scene_node
