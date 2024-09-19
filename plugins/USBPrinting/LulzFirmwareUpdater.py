# Copyright (c) 2022 FAME 3D
# Cura LE is released under the terms of the LGPLv3 or higher.

from enum import IntEnum
from serial import SerialException
from serial.tools import list_ports
from threading import Thread
from time import sleep
import platform

from PyQt6.QtCore import pyqtSignal

from UM.Logger import Logger

from cura.CuraApplication import CuraApplication
from cura.PrinterOutput.FirmwareUpdater import FirmwareUpdater, FirmwareUpdateState

from .avr_isp import stk500v2, intelHex
from .bossapy import bossa

MYPY = False
if MYPY:
    from cura.PrinterOutput.PrinterOutputDevice import PrinterOutputDevice

class LulzFirmwareUpdater(FirmwareUpdater):

    firmwareUpdating = pyqtSignal(bool)

    def __init__(self, output_device: "PrinterOutputDevice") -> None:
        super().__init__(output_device)
        self._firmware_serial_port = self._output_device._serial_port

        # Override FirmwareUpdateState for our purposes without modifying the original
        updateStateList = [(enum.name, int(enum.value)) for enum in FirmwareUpdateState]
        self.FirmwareUpdateState = IntEnum("FirmwareUpdateState", updateStateList + [("starting_update", len(updateStateList)), ("waiting", len(updateStateList) + 1)])

    def _updateFirmware(self) -> None:

        Logger.log("i", "Update Firmware Thread Started!")
        self._setFirmwareUpdateState(self.FirmwareUpdateState.starting_update)
        self._onFirmwareProgress(-1)

        firmware_file_extension = self._firmware_file.split(".")[-1]

        if firmware_file_extension == "hex":
            self._updateFirmwareAvr()
        elif firmware_file_extension == "bin":
            self._updateFirmwareBossapy()
        else:
            Logger.log("e", "File type unknown/unsupported" + firmware_file_extension)
            self._setFirmwareUpdateState(self.FirmwareUpdateState.firmware_not_found_error)
            self._cleanupAfterFailure()

        Logger.log("i", "Update Firmware Thread Closing...")
        self.firmwareUpdating.emit(False)
        return

    def _updateFirmwareAvr(self) -> None:
        try:
            hex_file = intelHex.readHex(self._firmware_file)
            assert len(hex_file) > 0
        except (FileNotFoundError, AssertionError):
            Logger.log("e", "Unable to read provided hex file. Could not update firmware.")
            self._setFirmwareUpdateState(self.FirmwareUpdateState.firmware_not_found_error)
            self._cleanupAfterFailure()
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
            self._setFirmwareUpdateState(self.FirmwareUpdateState.communication_error)
            self._cleanupAfterFailure()
            return

        # Give programmer some time to connect. Might need more in some cases, but this worked in all tested cases.
        sleep(1)

        if not programmer.isConnected():
            Logger.log("e", "Unable to connect with serial. Could not update firmware")
            self._setFirmwareUpdateState(self.FirmwareUpdateState.communication_error)
            self._cleanupAfterFailure()
        try:
            self._setFirmwareUpdateState(self.FirmwareUpdateState.updating)
            programmer.programChip(hex_file)
        except SerialException as e:
            Logger.log("e", "A serial port exception occurred during firmware update: %s" % e)
            self._setFirmwareUpdateState(self.FirmwareUpdateState.io_error)
            self._cleanupAfterFailure()
            return
        except Exception as e:
            Logger.log("e", "An unknown exception occurred during firmware update: %s" % e)
            self._setFirmwareUpdateState(self.FirmwareUpdateState.unknown_error)
            self._cleanupAfterFailure()
            return

        programmer.close()

        self._cleanupAfterUpdate()

    def _updateFirmwareBossapy(self) -> None:

        Logger.log("i", "Starting Bossa firmware update...")

        Logger.log("i", "Loading BIN firmware file: " + self._firmware_file)

        # Ensure that other connections are closed.
        if self._output_device.isConnected():
            self._output_device.close()

        programmer = bossa.BOSSA()
        programmer.progress_callback = self._onFirmwareProgress

        try:
            Logger.log("i", "Resetting CPU for Bossa bootloader access")
            programmer.reset(self._firmware_serial_port)
        # If for some reason you attempt to flash too soon after a printer has started,
        # it may fail to connect to serial on first attempt. Waiting a few seconds seems
        # to be all it takes to fix this issue.
        except Exception as e:
            Logger.log("w", "Programmer reset failure: {0}".format(e))
            Logger.log("d", "Serial may not be ready yet, will try again in 12 seconds.")
            self._setFirmwareUpdateState(self.FirmwareUpdateState.waiting)
            # 12 seconds should be long enough if they literally attempt to flash it again nearly instantly
            sleep(12)
            self._setFirmwareUpdateState(self.FirmwareUpdateState.starting_update)
            try:
                programmer.reset(self._firmware_serial_port)
            except Exception as e:
                Logger.log("e", "Second programmer reset failure: {0}".format(e))
                self._setFirmwareUpdateState(self.FirmwareUpdateState.communication_error)
                programmer.close()
                self._cleanupAfterFailure()
                return

        # During the programmer reset, Windows in particular really likes to switch
        # which port number the printer is located on, so our firmware updater loses it!
        try:
            Logger.log("i", "CPU reset success, attempting programmer connection...")
            programmer.connect(self._firmware_serial_port)
        except Exception:
            programmer.close()
            Logger.log("w", "Programmer connection failure, rescanning for printer...")
            new_port = self._relocateMovedPort()
            if new_port:
                Logger.log("d", "Checking new port: " + new_port)
            else:
                Logger.log("w", "Didn't find a new port")
            try:
                programmer.connect(new_port)
            except Exception as e:
                Logger.log("e", "Programmer connection failure with new port!: {0}".format(e))
                programmer.close()
                pass

        # Give programmer some time to connect. Might need more in some cases, but this worked in all tested cases.
        sleep(1)

        if not programmer.isConnected():
            Logger.log("e", "Unable to connect with serial. Could not update firmware")
            self._setFirmwareUpdateState(self.FirmwareUpdateState.communication_error)
            self._onFirmwareProgress(0)
            self._cleanupAfterFailure()
            return
        try:
            self._setFirmwareUpdateState(self.FirmwareUpdateState.updating)
            programmer.flash_firmware(self._firmware_file)
        except SerialException as e:
            Logger.log("e", "A serial port exception occurred during firmware update: {0}".format(e))
            self._setFirmwareUpdateState(self.FirmwareUpdateState.io_error)
            self._cleanupAfterFailure()
            return
        except Exception as e:
            Logger.log("e", "An unknown exception occurred during firmware update: {0}".format(e))
            self._setFirmwareUpdateState(self.FirmwareUpdateState.unknown_error)
            self._cleanupAfterFailure()
            return

        Logger.log('i', "Bossa firmware update complete!")

        programmer.close()

        self._cleanupAfterUpdate()

    def _relocateMovedPort(self) -> str:
        located_pro = ""
        try:
            ports = list_ports.comports()
            Logger.log("d", "Found %s port(s) to check" % len(ports))
        except TypeError:
            Logger.log("w", "No other ports found...")
            ports = []
        except Exception:
            Logger.log("e", "Encountered an unknown exception in _relocateMovedPort!")
            return located_pro
        for port in ports:
            if not isinstance(port, tuple):
                port = (port.device, port.description, port.hwid)
            if "Bossa Program Port" in port[1]: # Windows might actually be able to identify it
                Logger.log("d", "Found a port claiming to be Bossa!")
                return port[0]
            if "VID:PID=03EB:6124" in port[2]: # This is the board within TAZ Pro printers
                Logger.log("d", "Found a port with the correct board identifiers!")
                located_pro = port[0]
        return located_pro

    def _cleanupAfterFailure(self) -> None:
        self._update_firmware_thread = Thread(target=self._updateFirmware, daemon=True, name = "FirmwareUpdateThread")
        self._firmware_file = ""
        self._onFirmwareProgress(0)
