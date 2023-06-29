# Copyright (c) 2023 Fargo Additive Manufacturing Equipment 3D, LLC.
# Cura LE is released under the terms of the LGPLv3 or higher.
# Based off of "InsertAtLayerChange" script

from ..Script import Script

class LulzBioResinScript(Script):
    def __init__(self):
        super().__init__()

    def getSettingDataString(self):
        return """{
            "name": "Bio Resin Light",
            "key": "BioResinLight",
            "metadata": {},
            "version": 2
        }"""

    def execute(self, data):
        gcode_to_add = "\n"
        for layer in data:
            # Check that a layer is being printed
            lines = layer.split("\n")
            for line in lines:
                if ";LAYER:" in line:
                    index = data.index(layer)
                    layer = layer + gcode_to_add
                    data[index] = layer
                    break
        return data
