# Copyright (c) 2017 Ultimaker B.V.
# Uranium is released under the terms of the AGPLv3 or higher.

import UM.Settings.Models.SettingVisibilityHandler

class MaterialSettingsVisibilityHandler(UM.Settings.Models.SettingVisibilityHandler.SettingVisibilityHandler):
    def __init__(self, parent = None, *args, **kwargs):
        super().__init__(parent = parent, *args, **kwargs)

        material_settings = {
            "material_soften_temperature",
            "material_probe_temperature",
            "material_wipe_temperature",
            "default_material_print_temperature",
            "material_bed_temperature",
            "material_part_removal_temperature",
            "material_standby_temperature",
            "cool_fan_speed",
            "retraction_amount",
            "retraction_speed",
        }

        self.setVisible(material_settings)
