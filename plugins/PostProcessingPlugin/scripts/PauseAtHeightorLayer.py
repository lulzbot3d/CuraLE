# PauseAtHeightorLayer script - Pause at a given height (in mm or layers)

# Modified by Brad Morgan, brad-morgan@comcast.net

## Cloned from PauseAtHeight.py (Note: this can replace it by changing PauseAtHeightorLayer back to PauseAtHeight
## Added choice between height or layer to pause at (from TweakAtZ.py V5.1.1)
## Added some logging (most is commented out)
## Removed adjusting by layer 0 z so that a height in mm pauses closer to that height.
## Added current temperature search so that a pause without standby or resume temperatures might actually resume printing
## Added tracking of relative and absolute modes (G90, G91, M82, M83)
## Added a pause (G4) after moving the filament around to allow for manual nozzle cleaning (continues after pause, ready or not)

from ..Script import Script
import re
# from cura.Settings.ExtruderManager import ExtruderManager
from UM.Logger import Logger

class PauseAtHeightorLayer(Script):
    def __init__(self):
        super().__init__()

    def getSettingDataString(self):
        return """{
            "name":"Pause at height or layer",
            "key": "PauseAtHeightorLayer",
            "metadata": {},
            "version": 2,
            "settings":
            {
                "trigger":
                {
                    "label": "Trigger",
                    "description": "Trigger at height or at layer no.",
                    "type": "enum",
                    "options": {"height":"Height","layer_no":"Layer No."},
                    "default_value": "height"
                },
                "pause_height":
                {
                    "label": "Pause Height",
                    "description": "At what height should the pause occur",
                    "unit": "mm",
                    "type": "float",
                    "default_value": 5.0,
                     "enabled": "trigger == 'height'"
                },
                "pause_layer":
                {
                    "label": "Pause Layer",
                    "description": "At what layer should the pause occur",
                    "unit": "",
                    "type": "int",
                    "default_value": 1,
                    "enabled": "trigger == 'layer_no'"
                },
                "head_park_x":
                {
                    "label": "Park Print Head X",
                    "description": "What X location does the head move to when pausing.",
                    "unit": "mm",
                    "type": "float",
                    "default_value": 190
                },
                "head_park_y":
                {
                    "label": "Park Print Head Y",
                    "description": "What Y location does the head move to when pausing.",
                    "unit": "mm",
                    "type": "float",
                    "default_value": 190
                },
                "retraction_amount":
                {
                    "label": "Retraction",
                    "description": "How much filament must be retracted at pause.",
                    "unit": "mm",
                    "type": "float",
                    "default_value": 0
                },
                "retraction_speed":
                {
                    "label": "Retraction Speed",
                    "description": "How fast to retract the filament.",
                    "unit": "mm/s",
                    "type": "float",
                    "default_value": 25
                },
                "extrude_amount":
                {
                    "label": "Extrude Amount",
                    "description": "How much filament should be extruded after pause. This is needed when doing a material change on Ultimaker2's to compensate for the retraction after the change. In that case 128+ is recommended.",
                    "unit": "mm",
                    "type": "float",
                    "default_value": 0
                },
                "extrude_speed":
                {
                    "label": "Extrude Speed",
                    "description": "How fast to extrude the material after pause.",
                    "unit": "mm/s",
                    "type": "float",
                    "default_value": 3.3333
                },
                "pause_time":
                {
                    "label": "Pause Time",
                    "description": "How long to wait after extra extrude. This might be needed to manually clean the nozzle.",
                    "unit": "seconds",
                    "type": "float",
                    "default_value": 0.0
                },
                "redo_layers":
                {
                    "label": "Redo Layers",
                    "description": "Redo a number of previous layers after a pause to increases adhesion.",
                    "unit": "layers",
                    "type": "int",
                    "default_value": 0
                },
                "standby_temperature":
                {
                    "label": "Standby Temperature",
                    "description": "Change the temperature during the pause",
                    "unit": "°C",
                    "type": "int",
                    "default_value": 0
                },
                "resume_temperature":
                {
                    "label": "Resume Temperature",
                    "description": "Change the temperature after the pause",
                    "unit": "°C",
                    "type": "int",
                    "default_value": 0
                }
            }
        }"""

    def execute(self, data: list):

        """data is a list. Each index contains a layer"""

        x = 0.
        y = 0.
        current_z = 0.
        pause_layer = -10000
        pause_height = 10000.0
        layers_started = False
        current_temperature = 0
        xyz_absolute = True
        e_absolute = True
        if self.getSettingValueByKey("trigger") == "layer_no":
            pause_layer = int(self.getSettingValueByKey("pause_layer"))
            pause_by = "L"
        else:
            pause_height = self.getSettingValueByKey("pause_height")
            pause_by = "H"
        # Logger.log("d", "pause_by = %s, pause_layer = %i, pause_height = %f", pause_by, pause_layer, pause_height)
        park_x = self.getSettingValueByKey("head_park_x")
        park_y = self.getSettingValueByKey("head_park_y")
        retraction_amount = self.getSettingValueByKey("retraction_amount")
        retraction_speed = self.getSettingValueByKey("retraction_speed")
        extrude_amount = self.getSettingValueByKey("extrude_amount")
        extrude_speed = self.getSettingValueByKey("extrude_speed")
        pause_time = self.getSettingValueByKey("pause_time")
        redo_layers = self.getSettingValueByKey("redo_layers")
        standby_temperature = self.getSettingValueByKey("standby_temperature")
        resume_temperature = self.getSettingValueByKey("resume_temperature")

        # T = ExtruderManager.getInstance().getActiveExtruderStack().getProperty("material_print_temperature", "value")
        # with open("out.txt", "w") as f:
            # f.write(T)

        for layer in data:
            index = data.index(layer)
            lines = layer.split("\n")
            lineno = 0
            for line in lines:
                lineno += 1
                if ";LAYER:0" in line:
                    layers_started = True
                    current_layer = 0
                    continue

                if self.getValue(line, 'G') == 90:
                    Logger.log("d", "Got one: index = %i, lineno = %i, line = %s", index, lineno, line)
                    xyz_absolute = True
                    e_absolute = True

                if self.getValue(line, 'G') == 91:
                    Logger.log("d", "Got one: index = %i, lineno = %i, line = %s", index, lineno, line)
                    xyz_absolute = False
                    e_absolute = False

                if self.getValue(line, 'M') == 82 and not ";pauseAt" in line:
                    Logger.log("d", "Got one: index = %i, lineno = %i, line = %s", index, lineno, line)
                    e_absolute = True

                if self.getValue(line, 'M') == 83 and not ";pauseAt" in line:
                    Logger.log("d", "Got one: index = %i, lineno = %i, line = %s", index, lineno, line)
                    e_absolute = False

                if self.getValue(line, 'M') == 104 or self.getValue(line, 'M') == 109:
                    current_temperature = self.getValue(line, 'S')
                    if current_temperature is None:
                        current_temperature = self.getValue(line, 'R')

                if not layers_started:
                    continue

                if ";LAYER:" in line:
                    subPart = line[line.find(";LAYER:") + len(";LAYER:"):]
                    m = re.search("^[+-]?[0-9]+\.?[0-9]*", subPart)
                    current_layer = float(m.group(0))

                if self.getValue(line, 'G') == 1 or self.getValue(line, 'G') == 0:
                    if xyz_absolute:
                        current_z = self.getValue(line, 'Z')
                    else:
                        current_z = current_z + self.getValue(line, 'Z')

                    x = self.getValue(line, 'X', x)
                    y = self.getValue(line, 'Y', y)
                    if current_z is not None:
                        # Logger.log("d", "Look for: pause_by = %s, pause_layer = %i, pause_height = %f, current_layer = %i, current_z = %f", pause_by, pause_layer, pause_height, current_layer, current_z)
                        if (pause_by == "L" and current_layer == pause_layer) or (pause_by == "H" and current_z >= pause_height):
                            Logger.log("d", "Got one: index = %i, lineno = %i, pause_by = %s, pause_layer = %i, pause_height = %f, current_layer = %i, current_z = %f", index, lineno, pause_by, pause_layer, pause_height, current_layer, current_z)
                            if e_absolute:
                                index = data.index(layer)
                                prevLayer = data[index - 1]
                                prevLines = prevLayer.split("\n")
                                current_e = 0.
                                for prevLine in reversed(prevLines):
                                    current_e = self.getValue(prevLine, 'E', 0)
                                    if current_e != 0:
                                        break

                            # include a number of previous layers
                            for i in range(1, redo_layers + 1):
                                prevLayer = data[index - i]
                                layer = prevLayer + layer

                            prepend_gcode = ";TYPE:CUSTOM\n"
                            prepend_gcode += ";added code by post processing\n"
                            prepend_gcode += ";script: PauseAtHeightorLayer.py\n"
                            prepend_gcode += ";current layer: %i \n" % current_layer
                            prepend_gcode += ";current z: %f \n" % current_z
                            prepend_gcode += ";pause_by: %s \n" % pause_by
                            if current_temperature is not None:
                                prepend_gcode += ";current_temperature: %i \n" % current_temperature
                            if not xyz_absolute:
                                prepend_gcode += ";XYZ values are relative\n"
                            if not e_absolute:
                                prepend_gcode += ";E values are relative\n"

                            # Retract the filament
                            if e_absolute:
                                prepend_gcode += "M83 ;Set E relative\n"
                            if retraction_amount != 0:
                                prepend_gcode += "G1 E-%f F%f\n" % (retraction_amount, retraction_speed * 60)

                            # Move the head away
                            if xyz_absolute:
                                prepend_gcode += "G1 Z%f F300\n" % (current_z + 1)
                                prepend_gcode += "G1 X%f Y%f F9000\n" % (park_x, park_y)
                                if current_z < 15:
                                    prepend_gcode += "G1 Z15 F300\n"
                            else:
                                prepend_gcode += "G1 Z+1 F300\n"
                                prepend_gcode += "G1 X%f Y%f F9000\n" % (park_x, park_y) # This is relative move

                            # Disable the E steppers
                            prepend_gcode += "M18 E\n"

                            # Set extruder standby temperature
                            prepend_gcode += "M104 S%i ; standby temperature\n" % (standby_temperature)

                            # Wait till the user continues printing
                            prepend_gcode += "M0 ; Do the actual pause\n"

                            # Set extruder resume temperature
                            if resume_temperature != 0 or current_temperature is None:
                                prepend_gcode += "M109 S%i ; resume temperature\n" % (resume_temperature)
                            else:
                                prepend_gcode += "M109 S%i ; resume previous temperature\n" % (current_temperature)

                            # Push the filament back
                            if retraction_amount != 0:
                                prepend_gcode += "G1 E%f F%f\n" % (retraction_amount, retraction_speed * 60)

                            # Optionally extrude more material
                            if extrude_amount != 0:
                                prepend_gcode += "G1 E%f F%f\n" % (extrude_amount, extrude_speed * 60)

                            # Optionally wait for manual nozzle clean (continue after delay, ready or not)
                            if pause_time != 0:
                                prepend_gcode += "G4 P%f\n" % (pause_time * 1000)

                            # Retract filament again, this properly primes the nozzle when changing filament.
                            if retraction_amount != 0:
                                prepend_gcode += "G1 E-%f F%f\n" % (retraction_amount, retraction_speed * 60)

                            # Move the head back
                            if xyz_absolute:
                                prepend_gcode += "G1 Z%f F300\n" % (current_z + 1)
                                prepend_gcode += "G1 X%f Y%f F9000\n" % (x, y)
                            else:
                                prepend_gcode += "G1 Z-1 F300\n"
                                prepend_gcode += "G1 X%f Y%f F9000\n" % (-park_x, -park_y) # This is relative move

                            # Push the filament back again
                            if retraction_amount != 0:
                                prepend_gcode += "G1 E%f F%f\n" % (retraction_amount, retraction_speed * 60)

                            # restore previous E absolute and reset extrude value to pre pause value
                            if e_absolute:
                                prepend_gcode += "M82 ;Set E absolute\n"
                                prepend_gcode += "G92 E%f\n" % (current_e)

                            layer = prepend_gcode + layer

                            # Override the data of this layer with the modified data
                            data[index] = layer
                            return data
                        break
        return data
