# Copyright (c) 2023 Fargo Additive Manufacturing Equipment 3D, LLC.
# CuraLE is released under the terms of the LGPLv3 or higher.

from . import MultiplyTool

def getMetaData():
    return {
        "tool": {
            "name": "Multiply",
            "description": "Multiply Selected Model",
            "icon": "Multiply.svg",
            "tool_panel": "MultiplyTool.qml",
            "weight": 20
        }
    }

def register(app):
    return { "tool": MultiplyTool.MultiplyTool() }
