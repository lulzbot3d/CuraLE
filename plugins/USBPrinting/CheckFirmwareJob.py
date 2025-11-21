# Copyright (c) 2025 Fargo Additive Manufacturing Equipment 3D, LLC
# Cura LE is released under the terms of the LGPLv3 or higher.

from enum import IntEnum
from time import time, sleep
from serial import Serial, SerialException

from UM.Job import Job
from UM.Logger import Logger

from cura.CuraApplication import CuraApplication


#   An async job that checks the details of the firmware response to an M105 command
class CheckFirmwareJob(Job):
    def __init__(self, firmware_values: dict[str]) -> None:
        super().__init__()
        self._firmware_values = firmware_values
        self._global_container_stack = CuraApplication.getInstance().getGlobalContainerStack()
        self._list_to_check = [
            {
                "reply_key": "MACHINE_TYPE",
                "definition_key": "associated_firmware_names",
                "on_fail": CheckFirmwareStatus.WRONG_MACHINE
            },
            {
                "reply_key": "EXTRUDER_TYPE",
                "definition_key": "associated_firmware_tool_heads",
                "on_fail": CheckFirmwareStatus.WRONG_TOOLHEAD
            },
            {
                "reply_key": "FIRMWARE_VERSION",
                "definition_key": "lulzbot_firmware_version",
                "on_fail": CheckFirmwareStatus.FIRMWARE_OUTDATED
            }
        ]

    def run(self) -> None:

        self.setResult(CheckFirmwareStatus.OK)

        if not self._global_container_stack.getProperty("machine_has_lcd", "value"):
            self._list_to_check[1]["definition_key"] = "firmware_toolhead_name_no_lcd"
            self._list_to_check[2]["definition_key"] = "firmware_no_lcd_latest_version"
        if self._global_container_stack.getProperty("machine_has_bltouch", "value"):
            if not self._global_container_stack.getMetaDataEntry("bltouch_is_standard"):
                self._list_to_check[2]["definition_key"] = "firmware_bltouch_latest_version"


        for option in self._list_to_check:
            result = self.checkValue(option["reply_key"], option["definition_key"], option.get("exact_match", False), option.get("search_in_properties", False))
            if result != CheckValueStatus.OK:
                if result == CheckValueStatus.MISSING_VALUE_IN_DEFINITION:
                    pass
                elif result == CheckValueStatus.MISSING_VALUE_IN_REPLY:
                    # return CheckFirmwareStatus.FIRMWARE_OUTDATED
                    # self.setResult(CheckFirmwareStatus.FIRMWARE_OUTDATED)
                    pass
                else:
                    # self.setResult(option["on_fail"])
                    pass

        return

    def checkValue(self, fw_key, profile_key, exact_match = False, search_in_properties = False):
        # Get the expected value from the active printer definition
        if search_in_properties:
            expected_value = self._global_container_stack.getProperty(profile_key, "value")
        else:
            expected_value = self._global_container_stack.getMetaDataEntry(profile_key, None)

        # Perform the check
        if fw_key == "FIRMWARE_VERSION":
            expected_value = expected_value.split("-")[0]
        if expected_value is None:
            Logger.log("d", "Missing %s in profile. Skipping check." % profile_key)
            return CheckValueStatus.MISSING_VALUE_IN_DEFINITION
        elif not fw_key in self._firmware_values:
            Logger.log("d", "Missing %s in firmware string: %s" % (fw_key, self._firmware_string))
            return CheckValueStatus.MISSING_VALUE_IN_REPLY
        elif exact_match and self._firmware_values[fw_key] != expected_value:
            Logger.log("e", "Expected that %s was %s, but got %s instead" % (fw_key, expected_value, self._firmware_values[fw_key]))
            return CheckValueStatus.WRONG_VALUE
        elif not exact_match and self._firmware_values[fw_key].find(expected_value) < 0:
            Logger.log("e", "Expected that %s contained %s, but got %s instead" % (fw_key, expected_value, self._firmware_values[fw_key]))
            return CheckValueStatus.WRONG_VALUE
        return CheckValueStatus.OK


class CheckFirmwareStatus(IntEnum):
    OK = 0
    TIMEOUT = 1
    WRONG_MACHINE = 2
    WRONG_TOOLHEAD = 3
    FIRMWARE_OUTDATED = 4
    COMMUNICATION_ERROR = 5


class CheckValueStatus(IntEnum):
    OK = 0
    MISSING_VALUE_IN_REPLY = 1
    WRONG_VALUE = 2
    MISSING_VALUE_IN_DEFINITION = 3