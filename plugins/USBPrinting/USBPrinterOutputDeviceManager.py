# Copyright (c) 2020 Ultimaker B.V.
# Cura is released under the terms of the LGPLv3 or higher.

from multiprocessing.connection import Connection
import time
import serial.tools.list_ports
import platform
from os import environ
from re import search
from threading import Thread

from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot, QUrl, pyqtProperty

from UM.Signal import Signal, signalemitter
from UM.Message import Message
from UM.OutputDevice.OutputDevicePlugin import OutputDevicePlugin
from UM.i18n import i18nCatalog
from UM.Logger import Logger

from cura.CuraApplication import CuraApplication
from cura.PrinterOutput.PrinterOutputDevice import ConnectionState

from .USBPrinterOutputDevice import USBPrinterOutputDevice

i18n_catalog = i18nCatalog("cura")

@signalemitter
class USBPrinterOutputDeviceManager(QObject, OutputDevicePlugin):
    """Manager class that ensures that an USBPrinterOutput device is created for every connected USB printer."""

    addUSBOutputDeviceSignal = Signal()
    removeUSBOutputDeviceSignal = Signal()

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
        self._check_updates = True
        self._update_thread.start()

        self._application.applicationShuttingDown.connect(self.stop)

        # Because the model needs to be created in the same thread as the QMLEngine, we use a signal.
        self.addUSBOutputDeviceSignal.connect(self.addOutputDevice)
        self.removeUSBOutputDeviceSignal.connect(self.removeOutputDevice)

        self._application.globalContainerStackChanged.connect(self.updateUSBPrinterOutputDevices)

    def getSerialPortList(self, only_list_usb = False):
        """Create a list of serial ports on the system.

        :param only_list_usb: If true, only usb ports are listed
        """
        base_list = ["None"]
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

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # The method updates/reset the USB settings for all connected USB devices
    def updateUSBPrinterOutputDevices(self):
        for device in self._usb_output_devices.values():
            if isinstance(device, USBPrinterOutputDevice):
                device.resetDeviceSettings()

    def createUpdateThread(self):
        # Sets _update_thread to a new Thread object
        self._update_thread = Thread(target = self._updateThread)
        self._update_thread.setDaemon(True)

    def start(self):
        return

    def stop(self, store_data: bool = True):
        # self._check_updates = False
        return

    # Method to start searching for and connecting to printers
    @pyqtSlot()
    def pushedConnectButton(self):
        return

    # Method to disconnect printers
    # Ooh, this should probably exist as part of the actual devices, since I think we could actually do multiple connections potentially
    @pyqtSlot()
    def pushedDisconnectButton(self):
        for port, device in self._usb_output_devices.items():
            device.close()

    def _onConnectionStateChanged(self, serial_port):
        if serial_port not in self._usb_output_devices:
            return

        changed_device = self._usb_output_devices[serial_port]
        if changed_device.connectionState == ConnectionState.Connected:
            self.getOutputDeviceManager().addOutputDevice(changed_device)

        elif changed_device.connectionState == ConnectionState.WrongMachine:
            self.pushedDisconnectButton()
            wrong_printer_message = Message(
                i18n_catalog.i18nc("@info:status", "Printer found through USB does not match active printer!"),
                title = i18n_catalog.i18nc("@info:title", "Incorrect Printer!"),
                message_type = Message.MessageType.WARNING)
            wrong_printer_message.show()

        elif changed_device.connectionState == ConnectionState.Error:
            self.pushedDisconnectButton()
            error_printer_message = Message(
                i18n_catalog.i18nc("@info:status", "Printer encountered an error, connection closed!"),
                title = i18n_catalog.i18nc("@info:title", "Printer Error!"),
                message_type = Message.MessageType.ERROR)
            error_printer_message.show()

        else:
            self.getOutputDeviceManager().removeOutputDevice(serial_port)

    def _updateThread(self):
        Logger.log("d", "USBPrinterOutputDevice update thread started...")
        while self._check_updates:
            container_stack = self._application.getGlobalContainerStack()
            if container_stack is None:
                time.sleep(3)
                continue
            port_list = []  # Just an empty list; all USB devices will be removed.
            if container_stack.getMetaDataEntry("supports_usb_connection"):
                machine_file_formats = [file_type.strip() for file_type in container_stack.getMetaDataEntry("file_formats").split(";")]
                if "text/x-gcode" in machine_file_formats:
                    port_list = self.getSerialPortList(only_list_usb=True)
            self._addRemovePorts(port_list)
            time.sleep(2)
        Logger.log("d", "USBPrinterOutputDevice update thread stopped.")

    def _addRemovePorts(self, serial_ports):
        """Helper to identify serial ports (and scan for them)"""

        # First, find and add all new or changed keys
        for serial_port in list(serial_ports):
            if serial_port not in self._serial_port_list:
                Logger.log("d", "Found new serial port: %s, creating output device...", serial_port)
                self.addUSBOutputDeviceSignal.emit(serial_port)  # Hack to ensure its created in main thread
                continue
        for serial_port in self._serial_port_list:
            if serial_port not in list(serial_ports):
                Logger.log("d", "Serial port disappeared: %s, removing output device...", serial_port)
                self.removeUSBOutputDeviceSignal.emit(serial_port)
        self._serial_port_list = list(serial_ports)

        for port, device in self._usb_output_devices.items():
            if port not in self._serial_port_list:
                device.close()


    def addOutputDevice(self, serial_port):
        """Because the model needs to be created in the same thread as the QMLEngine, we use a signal."""

        device = USBPrinterOutputDevice(serial_port)
        device.connectionStateChanged.connect(self._onConnectionStateChanged)
        self._usb_output_devices[serial_port] = device
        self.getOutputDeviceManager().addOutputDevice(device)

    def removeOutputDevice(self, serial_port):

        # device = self._usb_output_devices.pop(serial_port)
        # device.close()
        # self.getOutputDeviceManager().removeOutputDevice(serial_port)
        return

    __instance = None # type: USBPrinterOutputDeviceManager

    @classmethod
    def getInstance(cls, *args, **kwargs) -> "USBPrinterOutputDeviceManager":
        return cls.__instance
