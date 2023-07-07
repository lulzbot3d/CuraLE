# Copyright (c) 2023 Fargo Additive Manufacturing Equipment 3D, LLC.
# Cura LE is released under the terms of the LGPLv3 or higher.
# Based off of "InsertAtLayerChange" script

import re

from ..Script import Script

class LulzBioResinScript(Script):
    def __init__(self):
        super().__init__()

    def getSettingDataString(self):
        return """{
            "name": "Bio Resin Light",
            "key": "BioResinLight",
            "metadata": {},
            "version": 2,
            "settings": {}
        }"""

    def execute(self, data):
        gcode_to_add = "\n"
        current_z_height = 0
        for layer in data:
            # Check that a layer is being printed
            lines = layer.split("\n")
            for line in lines:
                z_value = self.getValue(line, "Z")
                if z_value is not None:
                    current_z_height = z_value
                if ";LAYER:" in line:
                    if "0" in line:
                        continue
                    index = data.index(layer)
                    layer = gcode_to_add + layer
                    data[index] = layer
        return data
