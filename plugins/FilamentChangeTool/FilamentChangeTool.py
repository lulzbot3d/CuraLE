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

