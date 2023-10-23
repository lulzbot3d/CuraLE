# Copyright (c) 2023 Fargo Additive Manufacturing Equipment 3D, LLC.
# CuraLE is released under the terms of the LGPLv3 or higher.

from . import FilamentChangeTool

def getMetaData():
    return {
        "tool": {
            "name": "Filament Change",
            "description": "Change Filament On Layer",
            "icon": "Spool",
            "tool_panel": "FilamentChangeTool.qml",
            "weight": 21
        }
    }

def register(app):
    return { "tool": FilamentChangeTool.FilamentChangeTool() }
