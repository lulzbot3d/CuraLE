# Copyright (c) 2023 Fargo Additive Manufacturing Equipment 3D, LLC.
# CuraLE is released under the terms of the LGPLv3 or higher.

import base64

from UM.Application import Application
from UM.Logger import Logger

from cura.Snapshot import Snapshot
import cura.CuraApplication

from PyQt5.QtCore import QBuffer

class ThumbnailGenerator:
    """Generates thumbnails that mainsail uses"""

    def __init__(self):

        self._valid_printers = ["mini 3", "core xy"]
        self._current_printer = None

        Application.getInstance().getOutputDeviceManager().writeStarted.connect(self.generateThumbnails)
        Application.getInstance().globalContainerStackChanged.connect(self._onGlobalContainerStackChanged)

        self._onGlobalContainerStackChanged()

    def _onGlobalContainerStackChanged(self):
        self._current_printer = Application.getInstance().getGlobalContainerStack().getId()


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
            if printer in self._current_printer.lower():
                generate = True

        if not generate:
            return

        # Create snapshot
        def create_snapshot(width, height):
            snapshot = None
            Logger.log("d", "Creating thumbnail image...")
            try:
                snapshot = Snapshot.snapshot(width, height)
            except Exception:
                Logger.logException("w", "Failed to create snapshot image")
                return
            return snapshot

        # Encode snapshot
        def encode_snapshot(raw_snapshot):
            encoded_snapshot = None
            Logger.log("d", "Encoding thumbnail image...")
            try:
                thumbnail_buffer = QBuffer()
                thumbnail_buffer.open(QBuffer.ReadWrite)
                thumbnail_image = raw_snapshot
                thumbnail_image.save(thumbnail_buffer, "PNG")
                base64_bytes = base64.b64encode(thumbnail_buffer.data())
                encoded_snapshot = base64_bytes.decode('ascii')
                thumbnail_buffer.close()
            except Exception:
                Logger.logException("w", "Failed to encode snapshot image")
                return
            return encoded_snapshot

        # Convert snapshot to gcode
        def convert_snap_to_gcode(encoded_snapshot, width, height):
            gcode = []
            encoded_snapshot_length = len(encoded_snapshot)
            gcode.append(";")
            gcode.append("; thumbnail begin {} {} {}".format(
                width, height, encoded_snapshot_length))

            chunk_size = 78
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

        # Insert snapshot gcode into provided gcode data
        for layer in gcode_list:
                layer_index = gcode_list.index(layer)
                lines = gcode_list[layer_index].split("\n")
                for line in lines:
                    if line.startswith(";Generated with Cura"):
                        line_index = lines.index(line)
                        insert_index = line_index
                        for gcode in gcodes:
                            insert_index = insert_index + 1
                            lines[insert_index:insert_index] = gcode
                        break

                final_lines = "\n".join(lines)
                gcode_list[layer_index] = final_lines


        return gcode_list