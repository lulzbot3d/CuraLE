# Copyright (c) 2023 Fargo Additive Manufacturing Equipment 3D, LLC.
# CuraLE is released under the terms of the LGPLv3 or higher.

from PyQt6.QtCore import Qt

from UM.Tool import Tool

class MultiplyTool(Tool):
    """Provides the tool to scale meshes and groups"""

    def __init__(self):
        super().__init__()


    def event(self, event):
        return True

