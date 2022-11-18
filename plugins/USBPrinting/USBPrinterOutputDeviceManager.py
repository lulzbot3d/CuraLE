# Copyright (c) 2020 Ultimaker B.V.
# Cura is released under the terms of the LGPLv3 or higher.

import time
import serial.tools.list_ports
import platform
from enum import IntEnum
from os import environ
from re import search
from typing import Union
from threading import Thread

from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot, QUrl, pyqtProperty

from UM.Signal import Signal, signalemitter
from UM.OutputDevice.OutputDevicePlugin import OutputDevicePlugin
from UM.i18n import i18nCatalog
from UM.Logger import Logger

from cura.CuraApplication import CuraApplication
from cura.PrinterOutput.PrinterOutputDevice import ConnectionState
from plugins.USBPrinting.LulzFirmwareUpdater import LulzFirmwareUpdater

from . import USBPrinterOutputDevice

i18n_catalog = i18nCatalog("cura")


@signalemitter
class USBPrinterOutputDeviceManager(QObject, OutputDevicePlugin):
    """Manager class that ensures that an USBPrinterOutput device is created for every connected USB printer."""

    addUSBOutputDeviceSignal = Signal()
    progressChanged = pyqtSignal()

    firmwareProgressChanged = pyqtSignal()
    firmwareUpdateStateChanged = pyqtSignal()

    def __init__(self, application, parent = None):
        if USBPrinterOutputDeviceManager.__instance is not None:
            raise RuntimeError("Try to create singleton '%s' more than once" % self.__class__.__name__)
        USBPrinterOutputDeviceManager.__instance = self

        super().__init__(parent = parent)
        self._application = application

        self._serial_port_list = []
        self._usb_output_devices = {}
        self._usb_output_devices_model = None
        self._update_thread = Thread()

        self.createUpdateThread() # Sets up the thread properly

        self._update_thread.setDaemon(True)

        #~~~~ Firmware Updater Variables ~~~~~~~
        self._firmware_file = ""
        self._firmware_progress = 0
        self._firmware_update_state = FirmwareUpdateState.idle

        self._update_firmware_thread = Thread()
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        self._check_updates = False

        self._application.applicationShuttingDown.connect(self.stop)
        # Because the model needs to be created in the same thread as the QMLEngine, we use a signal.
        self.addUSBOutputDeviceSignal.connect(self.addOutputDevice)

        self._application.globalContainerStackChanged.connect(self.updateUSBPrinterOutputDevices)

    # Older code, might still be useful for BOSSA? ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    def getSerialPortList(self, only_list_usb = False):
        """Create a list of serial ports on the system.

        :param only_list_usb: If true, only usb ports are listed
        """
        base_list = []
        try:
            port_list = serial.tools.list_ports.comports()
        except TypeError:  # Bug in PySerial causes a TypeError if port gets disconnected while processing.
            port_list = []
        for port in port_list:
            if not isinstance(port, tuple):
                port = (port.device, port.description, port.hwid)
            if not port[2]:  # HWID may be None if the device is not USB or the system doesn't report the type.
                continue
            if only_list_usb and not port[2].startswith("USB"):
                continue

            # To prevent cura from messing with serial ports of other devices,
            # filter by regular expressions passed in as environment variables.
            # Get possible patterns with python3 -m serial.tools.list_ports -v

            # set CURA_DEVICENAMES=USB[1-9] -> e.g. not matching /dev/ttyUSB0
            pattern = environ.get('CURA_DEVICENAMES')
            if pattern and not search(pattern, port[0]):
                continue

            # set CURA_DEVICETYPES=CP2102 -> match a type of serial converter
            pattern = environ.get('CURA_DEVICETYPES')
            if pattern and not search(pattern, port[1]):
                continue

            # set CURA_DEVICEINFOS=LOCATION=2-1.4 -> match a physical port
            # set CURA_DEVICEINFOS=VID:PID=10C4:EA60 -> match a vendor:product
            pattern = environ.get('CURA_DEVICEINFOS')
            if pattern and not search(pattern, port[2]):
                continue

            base_list += [port[0]]

        return list(base_list)

    def _detectSerialPort(self, bootloader=False):
        import serial.tools.list_ports
        self._serial_port = None
        if platform.system() == "Linux":
            baud_rate = 115200
        else:
            baud_rate = CuraApplication.getInstance().getGlobalContainerStack().getProperty("machine_baudrate", "value")
        if bootloader:
            for port in serial.tools.list_ports.comports():
                if port.vid == 0x03EB:
                    Logger.log("i", "Detected bootloader on %s." % port.device)
                    self._firmware_serial_port = port.device
                    return
        else:
            for port in serial.tools.list_ports.comports():
                if port.vid in [0x03EB, 0x27B1]:
                    Logger.log("i", "Trying to detect 3D printer on %s." % port.device)
                    self._firmware_serial_port = port.device
                    # Let's try to open the serial connection and read Temperature
                    try:
                        serial_connection = serial.Serial(str(self._firmware_serial_port), baud_rate, timeout=3, writeTimeout=10000)
                    except:
                        continue
                    if serial_connection :
                        # We found the serial port, now let's try to write and read from it
                        try:
                            serial_connection.write(b"\n")
                        except serial.SerialException:
                            serial_connection.close()
                            continue
                        serial_connection.close()
                        return
        self._firmware_serial_port = None
        Logger.log("i", "No 3D printers detected")

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # The method updates/reset the USB settings for all connected USB devices
    def updateUSBPrinterOutputDevices(self):
        for device in self._usb_output_devices.values():
            if isinstance(device, USBPrinterOutputDevice.USBPrinterOutputDevice):
                device.resetDeviceSettings()

    def createUpdateThread(self):
        # Sets _update_thread to a new Thread object
        self._update_thread = Thread(target = self._updateThread)

    def start(self):
        # self._check_updates = True
        self._update_thread.start()

    def stop(self, store_data: bool = True):
        self._check_updates = False

    # Method to start searching for and connecting to printers
    @pyqtSlot()
    def pushedConnectButton(self):
        # Set thread to loop, recreate thread and start it
        self._check_updates = True
        if not self._update_thread.is_alive():
            self.createUpdateThread()
            self._update_thread.start()

    # Method to disconnect printers
    @pyqtSlot()
    def pushedDisconnectButton(self):
        self.stop()
        for port, device in self._usb_output_devices.items():
            device.close()
            self._serial_port_list.remove(port)

    # Function to return whether Cura is searching for a printer
    @pyqtSlot()
    def connecting(self):
        return self._check_updates

    def _onConnectionStateChanged(self, serial_port):
        if serial_port not in self._usb_output_devices:
            return

        changed_device = self._usb_output_devices[serial_port]
        if changed_device.connectionState == ConnectionState.Connected:
            self.getOutputDeviceManager().addOutputDevice(changed_device)
        else:
            self.getOutputDeviceManager().removeOutputDevice(serial_port)

    def _updateThread(self):
        tries = 0
        while self._check_updates and tries < 10:
            container_stack = self._application.getGlobalContainerStack()
            if container_stack is None:
                time.sleep(5)
                continue
            port_list = []  # Just an empty list; all USB devices will be removed.
            if container_stack.getMetaDataEntry("supports_usb_connection"):
                machine_file_formats = [file_type.strip() for file_type in container_stack.getMetaDataEntry("file_formats").split(";")]
                if "text/x-gcode" in machine_file_formats:
                    port_list = self.getSerialPortList(only_list_usb=True)
            self._addRemovePorts(port_list)
            time.sleep(2)
            tries += 1
        Logger.log("i", "Update thread stopped")

    def _addRemovePorts(self, serial_ports):
        """Helper to identify serial ports (and scan for them)"""

        # First, find and add all new or changed keys
        for serial_port in list(serial_ports):
            if serial_port not in self._serial_port_list:
                self.addUSBOutputDeviceSignal.emit(serial_port)  # Hack to ensure its created in main thread
                continue
        self._serial_port_list = list(serial_ports)

        for port, device in self._usb_output_devices.items():
            if port not in self._serial_port_list:
                device.close()

    def addOutputDevice(self, serial_port):
        """Because the model needs to be created in the same thread as the QMLEngine, we use a signal."""

        device = USBPrinterOutputDevice.USBPrinterOutputDevice(serial_port)
        device.connectionStateChanged.connect(self._onConnectionStateChanged)
        self._usb_output_devices[serial_port] = device
        device.connect()

    @pyqtSlot(str)
    def updateFirmware(self, firmware_file: Union[str, QUrl]) -> None:
        # the file path could be url-encoded.
        if firmware_file.startswith("file://"):
            self._firmware_file = QUrl(firmware_file).toLocalFile()
        else:
            self._firmware_file = firmware_file

        if self._firmware_file == "":
            self._setFirmwareUpdateState(FirmwareUpdateState.firmware_not_found_error)
            return

        firmware_file_extension = self._firmware_file.split(".")[-1]

        if firmware_file_extension == "hex":
            self._update_firmware_thread = Thread(target=lambda: LulzFirmwareUpdater._updateFirmwareAvr(self), daemon=True, name = "FirmwareUpdateThread")
        elif firmware_file_extension == "bin":
            self._update_firmware_thread = Thread(target=lambda: LulzFirmwareUpdater._updateFirmwareBossapy(self), daemon=True, name = "FirmwareUpdateThread")
        else:
            Logger.log("e", "File type unknown/unsupported" + firmware_file_extension)

        self._setFirmwareUpdateState(FirmwareUpdateState.updating)

        try:
            self._update_firmware_thread.start()
        except RuntimeError:
            Logger.warning("Could not start the update thread, since it's still running!")


    def _updateFirmware(self) -> None:
        raise NotImplementedError("_updateFirmware needs to be implemented")

    def _cleanupAfterUpdate(self) -> None:
        """Cleanup after a successful update"""

        # Clean up for next attempt.
        self._update_firmware_thread = Thread(target=self._updateFirmware, daemon=True, name = "FirmwareUpdateThread")
        self._firmware_file = ""
        self._onFirmwareProgress(100)
        self._setFirmwareUpdateState(FirmwareUpdateState.completed)

    @pyqtProperty(int, notify = firmwareProgressChanged)
    def firmwareProgress(self) -> int:
        return self._firmware_progress

    @pyqtProperty(int, notify=firmwareUpdateStateChanged)
    def firmwareUpdateState(self) -> "FirmwareUpdateState":
        return self._firmware_update_state

    def _setFirmwareUpdateState(self, state: "FirmwareUpdateState") -> None:
        if self._firmware_update_state != state:
            self._firmware_update_state = state
            self.firmwareUpdateStateChanged.emit()

    def _onFirmwareProgress(self, progress: int, max_progress: int = 100) -> None:
        self._firmware_progress = int(progress * 100 / max_progress)   # Convert to scale of 0-100
        self.firmwareProgressChanged.emit()

    __instance = None # type: USBPrinterOutputDeviceManager

    @classmethod
    def getInstance(cls, *args, **kwargs) -> "USBPrinterOutputDeviceManager":
        return cls.__instance


class FirmwareUpdateState(IntEnum):
    idle = 0
    updating = 1
    completed = 2
    unknown_error = 3
    communication_error = 4
    io_error = 5
    firmware_not_found_error = 6