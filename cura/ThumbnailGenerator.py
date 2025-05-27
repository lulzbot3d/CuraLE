# Copyright (c) 2023 Fargo Additive Manufacturing Equipment 3D, LLC.
# CuraLE is released under the terms of the LGPLv3 or higher.

import base64

from UM.Application import Application
from UM.Logger import Logger

from cura.Snapshot import Snapshot
import cura.CuraApplication

from PyQt6.QtCore import QBuffer

class ThumbnailGenerator:
    """Generates thumbnails that mainsail uses"""

    def __init__(self):

        self._valid_printers = ["mini 3", "core xy"]
        self._current_printer = ""

        Application.getInstance().getOutputDeviceManager().writeStarted.connect(self.generateThumbnails)
        Application.getInstance().globalContainerStackChanged.connect(self._onGlobalContainerStackChanged)

        self._onGlobalContainerStackChanged()

    def _onGlobalContainerStackChanged(self):
        global_stack = Application.getInstance().getGlobalContainerStack()
        if global_stack:
            self._current_printer = global_stack.getId().lower()
        else:
            self._current_printer = ""


    def generateThumbnails(self, output_device):
        """Function takes gcode data and returns it having inserted a snapshot thumbnail"""

        scene = Application.getInstance().getController().getScene()
        # If the scene does not have a gcode, do nothing
        if not hasattr(scene, "gcode_dict"):
            return
        gcode_dict = getattr(scene, "gcode_dict")
        if not gcode_dict:
            return

        # get gcode list for the active build plate
        active_build_plate_id = cura.CuraApplication.CuraApplication.getInstance().getMultiBuildPlateModel().activeBuildPlate
        gcode_list = gcode_dict[active_build_plate_id]
        if not gcode_list:
            return

        if "; thumbnail begin" in gcode_list[0]:
            return

        generate = False
        for printer in self._valid_printers:
            if printer in self._current_printer:
                generate = True

        if not generate:
            return

        # Create snapshot
        def create_snapshot(width, height):
            Logger.log("d", "Creating thumbnail image...")
            try:
                return Snapshot.snapshot(width, height)
            except Exception:
                Logger.logException("w", "Failed to create snapshot image")

        # Encode snapshot
        def encode_snapshot(raw_snapshot):
            Logger.log("d", "Encoding thumbnail image...")
            try:
                thumbnail_buffer = QBuffer()
                thumbnail_buffer.open(QBuffer.OpenModeFlag.ReadWrite)
                thumbnail_image = raw_snapshot
                thumbnail_image.save(thumbnail_buffer, "PNG")
                base64_bytes = base64.b64encode(thumbnail_buffer.data())
                base64_message = base64_bytes.decode('ascii')
                thumbnail_buffer.close()
                return base64_message
            except Exception:
                Logger.logException("w", "Failed to encode snapshot image")

        # Convert snapshot to gcode
        def convert_snap_to_gcode(encoded_snapshot, width, height, chunk_size=78):
            gcode = []
            encoded_snapshot_length = len(encoded_snapshot)
            gcode.append(";")
            gcode.append("; thumbnail begin {}x{} {}".format(
                width, height, encoded_snapshot_length))

            chunks = ["; {}".format(encoded_snapshot[i:i+chunk_size])
                    for i in range(0, len(encoded_snapshot), chunk_size)]
            gcode.extend(chunks)

            gcode.append("; thumbnail end")
            gcode.append(";")
            gcode.append("")

            return gcode

        required_sizes = [32, 300]
        gcodes = []

        for size in required_sizes:
            snap = create_snapshot(size, size)
            snap_bytes = encode_snapshot(snap)
            gcodes.append(convert_snap_to_gcode(snap_bytes, size, size))

        # Insert snapshot gcode at end of provided gcode data
        layer_index = -1
        lines = gcode_list[layer_index].split("\n")
        for line in lines:
            if ";End of Gcode" in line:
                line_index = lines.index(line)
                insert_index = line_index
                for gcode in gcodes:
                    insert_index = insert_index + 1
                    lines[insert_index:insert_index] = gcode
                break

        final_lines = "\n".join(lines)
        gcode_list[layer_index] = final_lines


        return gcode_list