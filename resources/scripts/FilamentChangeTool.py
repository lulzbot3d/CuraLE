# Copyright (c) 2023 Fargo Additive Manufacturing Equipment 3D, LLC.
# CuraLE is released under the terms of the LGPLv3 or higher.

from PyQt5.QtCore import Qt

from UM.Tool import Tool

class FilamentChangeTool(Tool):
    """
    Provides the tool to trigger a filament change at specific layers
    Useful for color changes
    """

    def __init__(self):
        super().__init__()


    def event(self, event):
        return True

    def getSettingDataString(self):
        return """{
            "name": "Filament Change",
            "key": "FilamentChange",
            "metadata": {},
            "version": 2,
            "settings":
            {
                "layer_number":
                {
                    "label": "Layer",
                    "description": "At what layer should color change occur. This will be before the layer starts printing. Specify multiple color changes with a comma.",
                    "unit": "",
                    "type": "str",
                    "default_value": "1"
                },
                "firmware_config":
                {
                    "label": "Use Firmware Configuration",
                    "description": "Use the settings in your firmware, or customise the parameters of the filament change here.",
                    "type": "bool",
                    "default_value": false
                },
                "initial_retract":
                {
                    "label": "Initial Retraction",
                    "description": "Initial filament retraction distance. The filament will be retracted with this amount before moving the nozzle away from the ongoing print.",
                    "unit": "mm",
                    "type": "float",
                    "default_value": 30.0,
                    "enabled": "not firmware_config"
                },
                "later_retract":
                {
                    "label": "Later Retraction Distance",
                    "description": "Later filament retraction distance for removal. The filament will be retracted all the way out of the printer so that you can change the filament.",
                    "unit": "mm",
                    "type": "float",
                    "default_value": 300.0,
                    "enabled": "not firmware_config"
                },
                "x_position":
                {
                    "label": "X Position",
                    "description": "Extruder X position. The print head will move here for filament change.",
                    "unit": "mm",
                    "type": "float",
                    "default_value": 0,
                    "enabled": "not firmware_config"
                },
                "y_position":
                {
                    "label": "Y Position",
                    "description": "Extruder Y position. The print head will move here for filament change.",
                    "unit": "mm",
                    "type": "float",
                    "default_value": 0,
                    "enabled": "not firmware_config"
                },
                "z_position":
                {
                    "label": "Z Position (relative)",
                    "description": "Extruder relative Z position. Move the print head up for filament change.",
                    "unit": "mm",
                    "type": "float",
                    "default_value": 0,
                    "minimum_value": 0
                },
                "retract_method":
                {
                    "label": "Retract method",
                    "description": "The gcode variant to use for retract.",
                    "type": "enum",
                    "options": {"U": "Marlin (M600 U)", "L": "Reprap (M600 L)"},
                    "default_value": "U",
                    "value": "\\\"L\\\" if machine_gcode_flavor==\\\"RepRap (RepRap)\\\" else \\\"U\\\"",
                    "enabled": "not firmware_config"
                },
                "machine_gcode_flavor":
                {
                    "label": "G-code flavor",
                    "description": "The type of g-code to be generated. This setting is controlled by the script and will not be visible.",
                    "type": "enum",
                    "options":
                    {
                        "RepRap (Marlin/Sprinter)": "Marlin",
                        "RepRap (Volumetric)": "Marlin (Volumetric)",
                        "RepRap (RepRap)": "RepRap",
                        "UltiGCode": "Ultimaker 2",
                        "Griffin": "Griffin",
                        "Makerbot": "Makerbot",
                        "BFB": "Bits from Bytes",
                        "MACH3": "Mach3",
                        "Repetier": "Repetier"
                    },
                    "default_value": "RepRap (Marlin/Sprinter)",
                    "enabled": "false"
                }
            }
        }"""

