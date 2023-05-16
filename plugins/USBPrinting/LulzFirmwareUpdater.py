# Copyright (c) 2022 FAME 3D
# Cura is released under the terms of the LGPLv3 or higher.

from UM.Logger import Logger

from cura.CuraApplication import CuraApplication
from cura.PrinterOutput.FirmwareUpdater import FirmwareUpdater, FirmwareUpdateState

from .avr_isp import stk500v2, intelHex
from .bossapy import bossa
from serial import SerialException

from time import sleep
import platform

MYPY = False
if MYPY:
    from cura.PrinterOutput.PrinterOutputDevice import PrinterOutputDevice


class LulzFirmwareUpdater(FirmwareUpdater):
    def __init__(self, output_device: "PrinterOutputDevice") -> None:
        super().__init__(output_device)
        self._firmware_serial_port = self._output_device._serial_port

    def _updateFirmwareAvr(self) -> None:
        try:
            hex_file = intelHex.readHex(self._firmware_file)
            assert len(hex_file) > 0
        except (FileNotFoundError, AssertionError):
            Logger.log("e", "Unable to read provided hex file. Could not update firmware.")
            self._setFirmwareUpdateState(FirmwareUpdateState.firmware_not_found_error)
            return

        programmer = stk500v2.Stk500v2()
        programmer.progress_callback = self._onFirmwareProgress

        # Ensure that other connections are closed.
        if self._output_device.isConnected():
            self._output_device.close()

        try:
            programmer.connect(self._firmware_serial_port)
        except:
            programmer.close()
            Logger.logException("e", "Failed to update firmware")
            self._setFirmwareUpdateState(FirmwareUpdateState.communication_error)
            return

        # Give programmer some time to connect. Might need more in some cases, but this worked in all tested cases.
        sleep(1)

        if not programmer.isConnected():
            Logger.log("e", "Unable to connect with serial. Could not update firmware")
            self._setFirmwareUpdateState(FirmwareUpdateState.communication_error)
        try:
            programmer.programChip(hex_file)
        except SerialException as e:
            Logger.log("e", "A serial port exception occurred during firmware update: %s" % e)
            self._setFirmwareUpdateState(FirmwareUpdateState.io_error)
            return
        except Exception as e:
            Logger.log("e", "An unknown exception occurred during firmware update: %s" % e)
            self._setFirmwareUpdateState(FirmwareUpdateState.unknown_error)
            return

        programmer.close()

        self._cleanupAfterUpdate()

    def _updateFirmwareBossapy(self) -> None:

        Logger.log("i", "Loading BIN firmware file: " + self._firmware_file)

        # Ensure that other connections are closed.
        if self._output_device.isConnected():
            self._output_device.close()

        programmer = bossa.BOSSA()
        programmer.progress_callback = self._onFirmwareProgress

        try:
            programmer.reset(self._firmware_serial_port)
        except Exception:
            Logger.log("e", "Programmer reset failure")
            programmer.close()
            pass

        try:
            programmer.connect(self._firmware_serial_port)
        except Exception:
            programmer.close()
            Logger.log("e", "Programmer connection failure")
            self._detectSerialPort(bootloader=True)
            try:
                programmer.connect(self._firmware_serial_port)
            except Exception:
                Logger.log("e", "Programmer connection failure with bootloader=True")
                programmer.close()
                pass

        # Give programmer some time to connect. Might need more in some cases, but this worked in all tested cases.
        sleep(1)

        if not programmer.isConnected():
            Logger.log("e", "Unable to connect with serial. Could not update firmware")
            self._setFirmwareUpdateState(FirmwareUpdateState.communication_error)
        try:
            programmer.flash_firmware(self._firmware_file)
        except SerialException as e:
            Logger.log("e", "A serial port exception occurred during firmware update: %s" % e)
            self._setFirmwareUpdateState(FirmwareUpdateState.io_error)
            return
        except Exception as e:
            Logger.log("e", "An unknown exception occurred during firmware update: %s" % e)
            self._setFirmwareUpdateState(FirmwareUpdateState.unknown_error)
            return

        programmer.close()

        self._cleanupAfterUpdate()