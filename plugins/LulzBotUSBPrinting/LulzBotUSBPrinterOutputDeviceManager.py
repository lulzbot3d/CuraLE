# Copyright (c) 2020 Ultimaker B.V.
# Cura is released under the terms of the LGPLv3 or higher.

import threading
import time
import serial.tools.list_ports
from os import environ
from re import search

from PyQt6.QtCore import QObject, pyqtSignal, pyqtProperty

from UM.Platform import Platform
from UM.Signal import Signal, signalemitter
from UM.Message import Message
from UM.OutputDevice.OutputDevicePlugin import OutputDevicePlugin
from UM.i18n import i18nCatalog
from UM.Logger import Logger

from cura.PrinterOutput.PrinterOutputDevice import ConnectionState

from .LulzBotUSBPrinterOutputDevice import USBPrinterOutputDevice

i18n_catalog = i18nCatalog("cura")


@signalemitter
class LulzBotUSBPrinterOutputDeviceManager(QObject, OutputDevicePlugin):
    """Manager class that ensures that an USBPrinterOutput device is created for every connected USB printer."""

    addUSBOutputDeviceSignal = Signal()
    progressChanged = pyqtSignal()
    removeUSBOutputDeviceSignal = Signal()
    serialListChanged = pyqtSignal()

    def __init__(self, application, parent = None):
        if LulzBotUSBPrinterOutputDeviceManager.__instance is not None:
            raise RuntimeError("Try to create singleton '%s' more than once" % self.__class__.__name__)

        super().__init__(parent = parent)
        USBPrinterOutputDeviceManager.__instance = self

        self._application = application

        self._serial_port_list = []
        self._usb_output_devices = {}
        self._usb_output_devices_model = None
        # self._update_thread = Thread()
        # self.createUpdateThread() # Sets up the thread properly

        self._check_updates = True
        self._port_check_frequency = 3
        # self._update_thread.start()

        self._application.applicationShuttingDown.connect(self.stop)
        # Because the model needs to be created in the same thread as the QMLEngine, we use a signal.
        self.addUSBOutputDeviceSignal.connect(self.addOutputDevice)
        self.removeUSBOutputDeviceSignal.connect(self.removeOutputDevice)

        self._application.globalContainerStackChanged.connect(self.updateUSBPrinterOutputDevices)

    # start and stop methods need to be implemented, but we don't use them.
    def start(self):
        return

    def stop(self, store_data: bool = True):
        return

    def createUpdateThread(self):
        # Sets _update_thread to a new Thread object
        # self._update_thread = Thread(target = self._updateThread)
        # self._update_thread.daemon = True
        return

    # Update thread is the USB printer discovery loop. Gets a list of viable serial ports and hands them to our add/remove ports method.
    def _updateThread(self):
        Logger.log("d", "USB Output Device discovery thread started...")
        while self._check_updates:
            container_stack = self._application.getGlobalContainerStack()
            if container_stack is None:
                time.sleep(3)
                continue
            port_list = []  # Just an empty list; all USB devices will be removed.
            if container_stack.getMetaDataEntry("supports_usb_connection"):
                machine_file_formats = [file_type.strip() for file_type in container_stack.getMetaDataEntry("file_formats").split(";")]
                if "text/x-gcode" in machine_file_formats:
                    # We only limit listing usb on windows is a fix for connecting tty/cu printers on MacOS and Linux
                    port_list = self.getSerialPortList(only_list_usb=Platform.isWindows())
            self._addRemovePorts(port_list)
            time.sleep(self._port_check_frequency)
        Logger.log("d", "USB Output Device discovery update thread stopped.")

    def getSerialPortList(self, only_list_usb = False):
        """Create a list of serial ports on the system.

        :param only_list_usb: If true, only usb ports are listed
        """
        base_list = ["None"]
        required_port = self._application.getGlobalContainerStack().getProperty("machine_port", "value")
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
            if required_port != "AUTO":
                if port[0] != required_port:
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

    def _addRemovePorts(self, serial_ports):
        """Helper to identify serial ports (and scan for them)"""

        serial_ports = list(serial_ports)
        for device in self._usb_output_devices.values():
            if device.getIsFlashing():
                return

        # First, find and add all new or changed keys
        for serial_port in serial_ports:
            if serial_port not in self._serial_port_list:
                Logger.log("d", "Found new serial port: %s, creating output device...", serial_port)
                self.addUSBOutputDeviceSignal.emit(serial_port)  # Hack to ensure its created in main thread
                continue

        # Then, check for missing ports and remove them if they've been missing twice (to account for firmware flashing)
        for serial_port in self._serial_port_list:
            if serial_port not in serial_ports:
                if serial_port in self._usb_output_devices.keys():
                    if self._usb_output_devices[serial_port].getIsFlashing():
                        serial_ports.append(serial_ports)
                        continue
                Logger.log("d", "Serial port disappeared: %s, removing output device...", serial_port)
                self.removeUSBOutputDeviceSignal.emit(serial_port)
                continue
        self._serial_port_list = serial_ports

    def addOutputDevice(self, serial_port):
        """Because the model needs to be created in the same thread as the QMLEngine, we use a signal."""

        device = USBPrinterOutputDevice(serial_port)
        device.connectionStateChanged.connect(self._onConnectionStateChanged)
        self._usb_output_devices[serial_port] = device
        self.getOutputDeviceManager().addOutputDevice(device)
        self.serialListChanged.emit()

    def removeOutputDevice(self, serial_port):
        try:
            device = self._usb_output_devices.pop(serial_port)
            device.close()
            self.getOutputDeviceManager().removeOutputDevice(serial_port)
            self.serialListChanged.emit()
        except KeyError:
            Logger.log("w", "Tried to remove USB device on a port no longer in the list.")
        return

    @pyqtProperty(list)
    def serialPorts(self):
        sanitized_ports = []
        for port in self._serial_port_list:
            if port != "None":
                sanitized_ports.append(port)
        return sanitized_ports

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # The method updates/reset the USB settings for all connected USB devices
    def updateUSBPrinterOutputDevices(self):
        for device in self._usb_output_devices.values():
            if isinstance(device, USBPrinterOutputDevice):
                device.resetDeviceSettings()

    def _onConnectionStateChanged(self, serial_port):
        if serial_port not in self._usb_output_devices:
            return

        changed_device = self._usb_output_devices[serial_port]

        if changed_device.connectionState == ConnectionState.WrongMachine:
            # Should disconnect the device
            wrong_printer_message = Message(
                i18n_catalog.i18nc("@info:status", "Printer found through USB does not match active printer!"),
                title = i18n_catalog.i18nc("@info:title", "Incorrect Printer!"),
                message_type = Message.MessageType.WARNING)
            wrong_printer_message.show()

        elif changed_device.connectionState == ConnectionState.Error:
            error_printer_message = Message(
                i18n_catalog.i18nc("@info:status", "Printer encountered an error, connection closed!"),
                title = i18n_catalog.i18nc("@info:title", "Printer Error!"),
                message_type = Message.MessageType.ERROR)
            error_printer_message.show()
            changed_device.close()

    __instance = None # type: USBPrinterOutputDeviceManager

    @classmethod
    def getInstance(cls, *args, **kwargs) -> "USBPrinterOutputDeviceManager":
        return cls.__instance
