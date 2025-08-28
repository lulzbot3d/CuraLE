# Copyright (c) 2020 Ultimaker B.V.
# Cura is released under the terms of the LGPLv3 or higher.

import os
from enum import IntEnum

from UM.i18n import i18nCatalog
from UM.Logger import Logger
from UM.Mesh.MeshWriter import MeshWriter # To get the g-code output.
from UM.Message import Message # Show an error when already printing.
from UM.PluginRegistry import PluginRegistry # To get the g-code output.
from UM.Qt.Duration import DurationFormat

from cura.CuraApplication import CuraApplication
from cura.PrinterOutput.PrinterOutputDevice import PrinterOutputDevice, ConnectionState, ConnectionType
from cura.PrinterOutput.Models.PrinterOutputModel import PrinterOutputModel
from cura.PrinterOutput.Models.PrintJobOutputModel import PrintJobOutputModel
from cura.PrinterOutput.GenericOutputController import GenericOutputController

from .AutoDetectBaudJob import AutoDetectBaudJob
from .KnownBaudJob import KnownBaudJob
from .LulzFirmwareUpdater import LulzFirmwareUpdater

from PyQt6.QtCore import pyqtProperty, pyqtSignal, pyqtSlot, QUrl

from io import StringIO # To write the g-code output.
from queue import Queue
from serial import Serial, SerialException, SerialTimeoutException
from threading import Thread, Event
from time import time
from typing import Union, Optional, List, cast, TYPE_CHECKING

import re
import functools  # Used for reduce

if TYPE_CHECKING:
    from UM.FileHandler.FileHandler import FileHandler
    from UM.Scene.SceneNode import SceneNode

catalog = i18nCatalog("cura")


class USBPrinterOutputDevice(PrinterOutputDevice):

    messageFromPrinter = pyqtSignal(str)
    printersChanged = pyqtSignal()

    def __init__(self, serial_port: str, baud_rate: Optional[int] = None) -> None:
        super().__init__(device_id = "USBPrinterOutputDevice@" + serial_port, connection_type = ConnectionType.NotConnected)
        self.setName(catalog.i18nc("@item:inmenu", "USB Printing"))
        self.setShortDescription(catalog.i18nc("@action:button Preceded by 'Ready to'.", "Print via USB"))
        self.setDescription(catalog.i18nc("@info:tooltip", "Print via USB"))
        self.setIconName("print")

        self._serial = None  # type: Optional[Serial]
        self._serial_port = serial_port
        self._address = serial_port

        self._timeout = 1.5

        # List of gcode lines to be printed
        self._gcode = [] # type: List[str]
        self._gcode_position = 0

        self._use_auto_detect = True

        self._baud_rate = baud_rate

        self._all_baud_rates = [115200, 250000]

        # Instead of using a timer, we really need the update to be as a thread, as reading from serial can block.
        self._update_thread = Thread(target = self._update, daemon = True, name = "USBPrinterConnectionThread")

        self._last_temperature_request = None  # type: Optional[int]
        self._firmware_idle_count = 0

        self._is_printing = False  # A print is being sent.
        self._is_flashing = False  # Firmware is being flashed

        ## Set when print is started in order to check running time.
        self._print_start_time = None  # type: Optional[float]
        self._print_estimated_time = None  # type: Optional[int]
        self._print_progress = 0

        self._accepts_commands = False

        self._paused = False
        self._printer_busy = False  # When printer is preheating and waiting (M190/M109), or when waiting for action on the printer
        self._printer_sd_card_printing = False

        self.setConnectionText(catalog.i18nc("@info:status", "This is the connection text"))

        # Queue for commands that need to be sent.
        self._command_queue = Queue()   # type: Queue
        # Event to indicate that an "ok" was received from the printer after sending a command.
        self._command_received = Event()
        self._command_received.set()

        self._firmware_name_requested = False
        self._firmware_updater = LulzFirmwareUpdater(self)
        self._firmware_data = None

        self._firmware_updater.firmwareUpdating.connect(self.setIsFlashing)
        self.printersChanged.connect(self.printersChanged)

        plugin_path = PluginRegistry.getInstance().getPluginPath("USBPrinting")
        if plugin_path:
            self._monitor_view_qml_path = os.path.join(plugin_path, "MonitorItem.qml")
        else:
            Logger.log("e", "Cannot create Monitor QML view: cannot find plugin path for plugin [USBPrinting]")
            self._monitor_view_qml_path = ""

        # self._onGlobalContainerStackChanged()

        # CuraApplication.getInstance().globalContainerStackChanged.connect(self._onGlobalContainerStackChanged)
        CuraApplication.getInstance().getOnExitCallbackManager().addCallback(self._checkActivePrintingUponAppExit)

        CuraApplication.getInstance().getPreferences().addPreference("usb_printing/enabled", False)

    # This is a callback function that checks if there is any printing in progress via USB when the application tries
    # to exit. If so, it will show a confirmation before
    def _checkActivePrintingUponAppExit(self) -> None:
        application = CuraApplication.getInstance()
        if not self._is_printing:
            # This USB printer is not printing, so we have nothing to do. Call the next callback if exists.
            application.triggerNextExitCheck()
            return

        application.setConfirmExitDialogCallback(self._onConfirmExitDialogResult)
        application.showConfirmExitDialog.emit(catalog.i18nc("@label", "A USB print is in progress, closing Cura LE will stop this print. Are you sure?"))


    def _onConfirmExitDialogResult(self, result: bool) -> None:
        if result:
            application = CuraApplication.getInstance()
            application.triggerNextExitCheck()

    def resetDeviceSettings(self) -> None:
        """Reset USB device settings"""

        self._firmware_name = None

    def ensureSafeToWrite(self) -> bool:

        if CuraApplication.getInstance().getController().getActiveStage() != "MonitorStage":
            CuraApplication.getInstance().getController().setActiveStage("MonitorStage")

        if self._accepts_commands == False:
            message = Message(text = catalog.i18nc("@message",
                                                   "Printer does not currently accept commands. Are you connected?"),
                              title = catalog.i18nc("@message", "Printer Not Connected!"),
                              message_type = Message.MessageType.WARNING)
            message.show()
            return False # Printer not connected
        if self._is_printing:
            message = Message(text = catalog.i18nc("@message",
                                                   "A print is still in progress. Cura LE cannot start another action at this time."),
                              title = catalog.i18nc("@message", "Print in Progress"),
                              message_type = Message.MessageType.ERROR)
            message.show()
            return False # Already printing
        self.writeStarted.emit(self)
        # cancel any ongoing preheat timer before starting a print
        controller = cast(GenericOutputController, self._printers[0].getController())
        controller.stopPreheatTimers()

        return True

    def requestWrite(self, nodes: List["SceneNode"], file_name: Optional[str] = None, limit_mimetypes: bool = False,
                     file_handler: Optional["FileHandler"] = None, filter_by_machine: bool = False, **kwargs) -> None:
        """Request the current scene to be sent to a USB-connected printer.

        :param nodes: A collection of scene nodes to send. This is ignored.
        :param file_name: A suggestion for a file name to write.
        :param filter_by_machine: Whether to filter MIME types by machine. This
               is ignored.
        :param kwargs: Keyword arguments.
        """

        safe = self.ensureSafeToWrite()
        if not safe:
            # We're not clear to print
            return

        CuraApplication.getInstance().getController().setActiveStage("MonitorStage")

        CuraApplication.getInstance().getPreferences().setValue("usb_printing/enabled", True)

        #Find the g-code to print.
        gcode_textio = StringIO()
        gcode_writer = cast(MeshWriter, PluginRegistry.getInstance().getPluginObject("GCodeWriter"))
        success = gcode_writer.write(gcode_textio, None)
        if not success:
            return

        self._printGCode(gcode_textio.getvalue())


    def _printGCode(self, gcode: str):
        """Start a print based on a g-code.

        :param gcode: The g-code to print.
        """
        self._gcode.clear()
        self._paused = False

        self._gcode.extend(gcode.split("\n"))

        # Reset line number. If this is not done, first line is sometimes ignored
        self._gcode.insert(0, "M110")
        self._gcode_position = 0
        self._print_start_time = time()

        self._print_estimated_time = int(CuraApplication.getInstance().getPrintInformation().currentPrintTime.getDisplayString(DurationFormat.Format.Seconds))

        for i in range(0, 4):  # Push first 4 entries before accepting other inputs
            self._sendNextGcodeLine()

        self._is_printing = True
        self.writeFinished.emit(self)

    def _autoDetectFinished(self, job: AutoDetectBaudJob):
        result = job.getResult()
        if result is not None:
            self.setBaudRate(result[0])
            self._serial = result[1]
            self.connect()  # Try to connect (actually create serial, etc)
        else:
            Logger.log("w", "Auto Detect Baud failed.")
            Message(text = catalog.i18nc("@message",
                    "The device on {port} did not respond to any of the baud rates that Cura LE tried. Please check the connection and try again.").format(port=self._serial_port),
                    title = catalog.i18nc("@message", "No Response"),
                    message_type = Message.MessageType.ERROR).show()
            self.setConnectionState(ConnectionState.Timeout)

    def _knownBaudFinished(self, job: KnownBaudJob):
        result = job.getResult()
        if result is not None:
            self._serial = result
            self.connect() # Finish connection process
        else: # Known baud rate didn't work, try auto-detect
            Logger.log("w", "Known Baud Job failed to create a connection.")
            self._baud_rate = "AUTO"
            self.connect()

    def setBaudRate(self, baud_rate: int):
        if baud_rate not in self._all_baud_rates:
            Logger.log("w", "Not updating baudrate to {baud_rate} as it's an unknown baudrate".format(baud_rate=baud_rate))
            return

        self._baud_rate = baud_rate

    @pyqtSlot()
    def connect(self):

        self.setConnectionState(ConnectionState.Connecting)

        self._firmware_name = None  # after each connection ensure that the firmware name is removed
        self._firmware_data = None

        if self._baud_rate is None:
            self._baud_rate = CuraApplication.getInstance().getGlobalContainerStack().getProperty("machine_baudrate", "value")
            Logger.log("d", "Pulling active printer Baud Rate setting: %s", self._baud_rate)

        if self._baud_rate == "AUTO":
            Logger.log("d", "Baud Rate set to AUTO, auto-detecting baud rate...")
            if self._use_auto_detect:
                auto_detect_job = AutoDetectBaudJob(self._serial_port)
                auto_detect_job.start()
                auto_detect_job.finished.connect(self._autoDetectFinished)
            return
        if self._serial == None:
            Logger.log("d", "Starting connection to serial port %s", self._serial_port)
            known_baud_job = KnownBaudJob(self._serial_port, self._baud_rate)
            known_baud_job.start()
            known_baud_job.finished.connect(self._knownBaudFinished)
            return

        firmware_response_status = self._checkFirmware()
        ## Check what the firmware status came back as and whether or not we should ignore it.
        if firmware_response_status is not self.CheckFirmwareStatus.OK:
            overridden = False
            allow_wrong = CuraApplication.getInstance().getPreferences().getValue("cura/allow_connection_to_wrong_machine")

            if firmware_response_status is self.CheckFirmwareStatus.TIMEOUT:
                message = Message(text = catalog.i18nc("@message",
                                "The printer did not respond to the firmware check. Is firmware loaded?"),
                                title = catalog.i18nc("@message", "No Response"),
                                message_type = Message.MessageType.ERROR)

            elif firmware_response_status is self.CheckFirmwareStatus.WRONG_MACHINE:
                message = Message(text = catalog.i18nc("@message",
                                "Firmware reports printer type doesn't match active printer in Cura LE! Make sure your \n\
                                    active printer in Cura LE matches the printer you're trying to connect to and that \
                                    your firmware is up-to-date."),
                                title = catalog.i18nc("@message", "Wrong Machine!"),
                                message_type = Message.MessageType.ERROR)
                if allow_wrong: overridden = True

            elif firmware_response_status is self.CheckFirmwareStatus.WRONG_TOOLHEAD:
                message = Message(text = catalog.i18nc("@message",
                                "The printer reports having a different Tool Head than the active printer in Cura LE! \n If you're \
                                    confident your selection matches, you can ignore this error by going to Preferences -> Configure Cura \
                                    and selecting \"Allow Connection to Wrong Printers\""),
                                title = catalog.i18nc("@message", "Wrong Tool Head!"),
                                message_type = Message.MessageType.WARNING)
                if allow_wrong: overridden = True

            elif firmware_response_status is self.CheckFirmwareStatus.FIRMWARE_OUTDATED:
                overridden = True
                message = Message(text = catalog.i18nc("@message",
                                "Printer appears to have outdated firmware."),
                                title = catalog.i18nc("@message", "Old Firmware"),
                                message_type = Message.MessageType.WARNING)

            elif firmware_response_status is self.CheckFirmwareStatus.COMMUNICATION_ERROR:
                message = Message(text = catalog.i18nc("@message",
                                "There was an error when attempting to communicate with the printer. Check the cable connection"),
                                title = catalog.i18nc("@message", "Communication Error!"),
                                message_type = Message.MessageType.ERROR)

            else:
                message = Message(text = catalog.i18nc("@message",
                                "Unknown CheckFirmwareStatus state!"),
                                title = catalog.i18nc("@message", "Oh No! If you got this message, please contact support and get us \
                                                      some logs because this isn't supposed to happen!"),
                                message_type = Message.MessageType.ERROR)

            message.show()
            # Ignore it if it's minor or if the user has elected to
            if not overridden:
                self.close()
                return
        self.setConnectionState(ConnectionState.Connected)
        self._setAcceptsCommands(True)
        self._update_thread.start()

    @pyqtSlot()
    def close(self):
        super().close()

        Logger.log("d", "Close called on device %s", self._serial_port)

        self._setAcceptsCommands(False)
        self.cancelPrint()

        if self._serial is not None:
            self._serial.close()

        # Re-create the thread so it can be started again later.
        self._update_thread = Thread(target=self._update, daemon=True, name = "USBPrinterConnectionThread")
        self._serial = None

    def _update(self):
        ### This is the main connection loop
        while self._connection_state == ConnectionState.Connected and self._serial is not None:
            try:
                line = self._serial.readline()
                decoded_line = line.decode()
                if decoded_line != "":
                    self.messageFromPrinter.emit(decoded_line.strip('\n'))
                    ## might want to save these somewhere at some point, could be handy.
            except SerialException:
                Logger.log("e", "Encountered serial exception! Closing connection.")
                self.close()
                self.setConnectionState(ConnectionState.Error)
                break
            except TypeError:
                Logger.log("w", "TypeError encountered.")


            if b"//action:" in line:
                if b"out_of_filament" in line:
                    Logger.log("i", "Out of Filament reported by printer")
                    self.pausePrint()

                if b"pause" in line:
                    Logger.log("i", "Pause request from printer")
                    self.pausePrint()

                if b"resume" in line:
                    Logger.log("i", "Resume request from printer")
                    self.resumePrint()

                if b"cancel" in line:
                    Logger.log("i", "Cancel request from printer")
                    self.cancelPrint()

                if b"disconnect" in line:
                    self.close()
                    self.setConnectionState(ConnectionState.Closed)
                    Logger.log("i", "Printer requested disconnect!")
                    break

                if b"poweroff" in line:
                    self.close()
                    self.setConnectionState(ConnectionState.Error)
                    Logger.log("w", "Printer signaled poweroff!!")
                    break

            if line.startswith(b"Error:"):
                # Oh YEAH, consistency.
                # Marlin reports a MIN/MAX temp error as "Error:x\n: Extruder switched off. MAXTEMP triggered !\n"
                # But a bed temp error is reported as "Error: Temperature heated bed switched off. MAXTEMP triggered !!"
                # So we can have an extra newline in the most common case. Awesome work people.
                if re.match(b"Error:[0-9]\n", line):
                    line = line.rstrip() + self._serial.readline().decode()
                    Logger.log("w", "Printer sent a numerical error message!")

                # Skip the communication errors, as those get corrected.
                if b"Extruder switched off" in line or b"Temperature heated bed switched off" in line or b"Something is wrong, please turn off the printer." in line:
                    Logger.log("w", "Printer error, closing connection")
                    self.close()
                    self.setConnectionState(ConnectionState.Error)

            # M105 commands (report temperature) are effectively used to keep the connection alive
            if self._last_temperature_request is None or time() > self._last_temperature_request + self._timeout:
                # Timeout, or no request has been sent at all.
                if not self._printer_busy: # Don't flood the printer with temperature requests while it is busy
                    self.sendCommand("M105")
                    self._last_temperature_request = time()

            if re.search(br"[B|T\d*]: ?\d+\.?\d*", line):  # Temperature message. 'T:' for extruder and 'B:' for bed
                extruder_temperature_matches = re.findall(br"T(\d*): ?(\d+\.?\d*)\s*\/?(\d+\.?\d*)?", line)
                # Update all temperature values
                matched_extruder_nrs = []
                for match in extruder_temperature_matches:
                    extruder_nr = 0
                    if match[0] != b"":
                        extruder_nr = int(match[0])

                    if extruder_nr in matched_extruder_nrs:
                        continue
                    matched_extruder_nrs.append(extruder_nr)

                    if extruder_nr >= len(self._printers[0].extruders):
                        Logger.log("w", "Printer reports more temperatures than the number of configured extruders")
                        continue

                    extruder = self._printers[0].extruders[extruder_nr]
                    if match[1]:
                        extruder.updateHotendTemperature(float(match[1]))
                    if match[2]:
                        extruder.updateTargetHotendTemperature(float(match[2]))

                bed_temperature_matches = re.findall(br"B: ?(\d+\.?\d*)\s*\/?(\d+\.?\d*)?", line)
                if bed_temperature_matches:
                    match = bed_temperature_matches[0]
                    if match[0]:
                        self._printers[0].updateBedTemperature(float(match[0]))
                    if match[1]:
                        self._printers[0].updateTargetBedTemperature(float(match[1]))

            if line == b"":
                # An empty line means that the firmware is idle
                # Multiple empty lines probably means that the firmware and Cura are waiting
                # for each other due to a missed "ok", so we keep track of empty lines
                if self._firmware_idle_count >= 2:
                    # For now I'll give it three strikes but honestly this is probably excessive
                    # If we haven't gotten a response in this long the connection is probably dead.
                    Logger.log("w", "Printer connection timeout! Connection lost.")
                    self.close()
                    self.setConnectionState(ConnectionState.Timeout)
                    break
                else:
                    self._firmware_idle_count += 1
            else:
                self._firmware_idle_count = 0

            if line.startswith(b"ok") or self._firmware_idle_count > 1:
                self._printer_busy = False

                self._command_received.set()
                if not self._command_queue.empty():
                    self._sendCommand(self._command_queue.get())
                elif self._is_printing:
                    if self._paused:
                        pass  # Nothing to do!
                    else:
                        self._sendNextGcodeLine()

            if line.startswith(b"echo:busy:"):
                self._printer_busy = True

            if self._is_printing:
                if line.startswith(b'!!'):
                    Logger.log('e', "Printer signals fatal error. Cancelling print. {}".format(line))
                    self.cancelPrint()
                elif line.lower().startswith(b"resend") or line.startswith(b"rs"):
                    # A resend can be requested either by Resend, resend or rs.
                    try:
                        self._gcode_position = int(line.replace(b"N:", b" ").replace(b"N", b" ").replace(b":", b" ").split()[-1])
                    except:
                        if line.startswith(b"rs"):
                            # In some cases of the RS command it needs to be handled differently.
                            self._gcode_position = int(line.split()[1])
                else:
                    # Set progress
                    curr_prog = round(self.activePrinter.activePrintJob.progress * 100)
                    if curr_prog != self._print_progress:
                        self._print_progress = curr_prog
                        if self._print_progress != 0:
                            time_remaining = round(self.activePrinter.activePrintJob.timeRemaining / 60)
                            comp_cmd = "M73 P" + str(self._print_progress) + " R" + str(time_remaining)
                            self.sendCommand(comp_cmd)
        # This is outside the loop. Might be good to have a catch here if the loop broke unexpectedly
        Logger.log("d", "Printer connection loop stopped.")

    def sendCommand(self, command: Union[str, bytes]):
        """Send a command to printer."""

        if not self._command_received.is_set():
            self._command_queue.put(command)
        else:
            self._sendCommand(command)

    def _sendCommand(self, command: Union[str, bytes]):
        if self._serial is None or (self._connection_state != ConnectionState.Connected and self._connection_state != ConnectionState.Connecting):
            return

        new_command = cast(bytes, command) if type(command) is bytes else cast(str, command).encode() # type: bytes
        if not new_command.endswith(b"\n"):
            new_command += b"\n"
        try:
            self._command_received.clear()
            self._serial.write(new_command)
        except SerialTimeoutException:
            Logger.log("w", "Timeout when sending command to printer via USB.")
            self._command_received.set()
        except SerialException:
            Logger.logException("w", "An unexpected exception occurred while writing to the serial.")
            self.setConnectionState(ConnectionState.Error)

######### Firmware Checks and Handling #########
    class CheckFirmwareStatus(IntEnum):
        OK = 0
        TIMEOUT = 1
        WRONG_MACHINE = 2
        WRONG_TOOLHEAD = 3
        FIRMWARE_OUTDATED = 4
        COMMUNICATION_ERROR = 5


    def _checkFirmware(self):
        reply = b""
        try:
            self._sendCommand("M115")
            last_sent = time()
            timeout = time() + 5.5
            reply = self._serial.readline()
            while b"FIRMWARE_NAME" not in reply and time() < timeout:
                if (time() - last_sent) > 1:
                    self._sendCommand("M115")
                    last_sent = time()
                reply = self._serial.readline()
        except AttributeError:
            Logger.log("w", "Tried to check firmware of a non-existant serial device. Device may have been disconnected.")
        except SerialException:
            Logger.logException("w", "An unexpected exception occurred while reading from serial!")


        if b"FIRMWARE_NAME" not in reply:
            Logger.log("w", "Printer did not return firmware name")
            self.setConnectionState(ConnectionState.Timeout)
            return self.CheckFirmwareStatus.TIMEOUT

        try:
            firmware_string = reply.decode()
        except UnicodeDecodeError:
            # This can occur if the response is a jumbled mess but "FIRMWARE_NAME" manages to survive
            Logger.log("w", "Failed to decode response from serial. Response may be corrupted.")
            self.setConnectionState(ConnectionState.Error)
            return self.CheckFirmwareStatus.COMMUNICATION_ERROR
        self._setFirmwareData(firmware_string)
        values = self._firmware_data

        global_container_stack = CuraApplication.getInstance().getGlobalContainerStack()

        class CheckValueStatus(IntEnum):
            OK = 0
            MISSING_VALUE_IN_REPLY = 1
            WRONG_VALUE = 2
            MISSING_VALUE_IN_DEFINITION = 3


        def checkValue(fw_key, profile_key, exact_match = False, search_in_properties = False):
            expected_value = global_container_stack.getProperty(profile_key, "value") if search_in_properties else\
                global_container_stack.getMetaDataEntry(profile_key, None)
            if fw_key == "FIRMWARE_VERSION":
                expected_value = expected_value.split("-")[0]
            if expected_value is None:
                Logger.log("d", "Missing %s in profile. Skipping check." % profile_key)
                return CheckValueStatus.MISSING_VALUE_IN_DEFINITION
            elif not fw_key in values:
                Logger.log("d", "Missing %s in firmware string: %s" % (fw_key, firmware_string))
                return CheckValueStatus.MISSING_VALUE_IN_REPLY
            elif exact_match and values[fw_key] != expected_value:
                Logger.log("e", "Expected that %s was %s, but got %s instead" % (fw_key, expected_value, values[fw_key]))
                return CheckValueStatus.WRONG_VALUE
            elif not exact_match and values[fw_key].find(expected_value) < 0:
                Logger.log("e", "Expected that %s contained %s, but got %s instead" % (fw_key, expected_value, values[fw_key]))
                return CheckValueStatus.WRONG_VALUE
            return CheckValueStatus.OK

        list_to_check = [
            {
                "reply_key": "MACHINE_TYPE",
                "definition_key": "firmware_machine_type",
                "exact_match": True,
                "search_in_properties": True,
                "on_fail": self.CheckFirmwareStatus.WRONG_MACHINE
            },
            {
                "reply_key": "EXTRUDER_TYPE",
                "definition_key": "firmware_toolhead_name",
                "on_fail": self.CheckFirmwareStatus.WRONG_TOOLHEAD
            },
            {
                "reply_key": "FIRMWARE_VERSION",
                "definition_key": "firmware_latest_version",
                "on_fail": self.CheckFirmwareStatus.FIRMWARE_OUTDATED
            }
        ]
        if not global_container_stack.getProperty("machine_has_lcd", "value"):
            list_to_check[1]["definition_key"] = "firmware_toolhead_name_no_lcd"
            list_to_check[2]["definition_key"] = "firmware_no_lcd_latest_version"
        if global_container_stack.getProperty("machine_has_bltouch", "value"):
            if not global_container_stack.getMetaDataEntry("bltouch_is_standard"):
                list_to_check[2]["definition_key"] = "firmware_bltouch_latest_version"


        for option in list_to_check:
            result = checkValue(option["reply_key"], option["definition_key"], option.get("exact_match", False), option.get("search_in_properties", False))
            if result != CheckValueStatus.OK:
                if result == CheckValueStatus.MISSING_VALUE_IN_DEFINITION:
                    pass
                elif result == CheckValueStatus.MISSING_VALUE_IN_REPLY:
                    return self.CheckFirmwareStatus.FIRMWARE_OUTDATED
                else:
                    return option["on_fail"]

        return self.CheckFirmwareStatus.OK

    def _setFirmwareName(self, name):
        new_name = re.findall(r"FIRMWARE_NAME:([^\s]+)", str(name))
        if new_name:
            self._firmware_name = new_name[0]
            Logger.log("i", "USB output device Firmware name: %s", self._firmware_name)
        else:
            self._firmware_name = "Unknown"
            Logger.log("i", "Unknown USB output device Firmware name: %s", str(name))

    def _setFirmwareData(self, data):
        data_dict = {m[0] : m[1] for m in re.findall(r"([A-Z_]+)\:(.*?)(?= [A-Z_]+\:|$)", data)}
        if data_dict:
            self._firmware_data = data_dict
            Logger.log("i", "Firmware data collected and stored")
        else:
            Logger.log("No valid firmware data found! What did the printer return?")

    def getFirmwareName(self):
        return self._firmware_name

    def getFirmwareVersion(self):
        if self._firmware_data and "FIRMWARE_VERSION" in self._firmware_data:
            return self._firmware_data["FIRMWARE_VERSION"]
        return catalog.i18nc("@info:status", "Connect for Info")

    @pyqtSlot(str)
    def updateFirmware(self, firmware_file: Union[str, QUrl]) -> None:
        if not self._firmware_updater:
            return
        self.setIsFlashing(True)
        self._firmware_updater.updateFirmware(firmware_file)

    def setIsFlashing(self, value: bool) -> None:
        self._is_flashing = value

    def getIsFlashing(self) -> bool:
        return self._is_flashing

    ########### PRINTER COMMANDS ############

    def pausePrint(self):
        self._paused = True

    def resumePrint(self):
        self._paused = False
        self._sendNextGcodeLine() #Send one line of g-code next so that we'll trigger an "ok" response loop even if we're not polling temperatures.

    def cancelPrint(self):
        self._gcode_position = 0
        self._gcode.clear()
        self._printers[0].updateActivePrintJob(None)
        self._is_printing = False
        self._paused = False

        # Turn off temperatures, fan and steppers
        self._sendCommand("M140 S0")
        self._sendCommand("M104 S0")
        self._sendCommand("M107")

        # We're gonna go to the park position
        # Seems like a safe bet to not run into whatever's on the build plate
        self._sendCommand("G27")

    def _printGCode(self, gcode: str):
        """Start a print based on a g-code.

        :param gcode: The g-code to print.
        """
        self._gcode.clear()
        self._paused = False

        self._gcode.extend(gcode.split("\n"))

        # Reset line number. If this is not done, first line is sometimes ignored
        self._gcode.insert(0, "M110")
        self._gcode_position = 0
        self._print_start_time = time()

        self._print_estimated_time = int(CuraApplication.getInstance().getPrintInformation().currentPrintTime.getDisplayString(DurationFormat.Format.Seconds))

        for i in range(0, 4):  # Push first 4 entries before accepting other inputs
            self._sendNextGcodeLine()

        self._is_printing = True
        self.writeFinished.emit(self)

    def _sendNextGcodeLine(self):
        """
        Send the next line of g-code, at the current `_gcode_position`, via a
        serial port to the printer.

        If the print is done, this sets `_is_printing` to `False` as well.
        """
        try:
            line = self._gcode[self._gcode_position]
        except IndexError:  # End of print, or print got cancelled.
            self._printers[0].updateActivePrintJob(None)
            self._is_printing = False
            return

        if ";" in line:
            line = line[:line.find(";")]

        line = line.strip()
 
        # Don't send empty lines. But we do have to send something, so send M105 instead.
        # Don't send the M0 or M1 to the machine, as M0 and M1 are handled as an LCD menu pause.
        if line == "" or line == "M0" or line == "M1":
            line = "M105"

        checksum = functools.reduce(lambda x, y: x ^ y, map(ord, "N%d%s" % (self._gcode_position, line)))

        self._sendCommand("N%d%s*%d" % (self._gcode_position, line, checksum))

        print_job = self._printers[0].activePrintJob
        try:
            progress = self._gcode_position / len(self._gcode)
        except ZeroDivisionError:
            # There is nothing to send!
            if print_job is not None:
                print_job.updateState("error")
            return

        elapsed_time = int(time() - self._print_start_time)

        if print_job is None:
            controller = GenericOutputController(self)
            controller.setCanUpdateFirmware(False)
            print_job = PrintJobOutputModel(output_controller = controller, name = CuraApplication.getInstance().getPrintInformation().jobName)
            print_job.updateState("printing")
            self._printers[0].updateActivePrintJob(print_job)

        print_job.updateTimeElapsed(elapsed_time)
        estimated_time = self._print_estimated_time
        if progress > .1:
            estimated_time = int(self._print_estimated_time * (1 - progress) + elapsed_time)
        print_job.updateTimeTotal(estimated_time)

        self._gcode_position += 1

    # LulzBot Predefined Commands Dependencies
    @pyqtProperty(bool, notify = printersChanged)
    def supportWipeNozzle(self):
        return self._supportWipeNozzle()

    def _supportWipeNozzle(self):
        code = CuraApplication.getInstance().getGlobalContainerStack().getProperty("machine_wipe_gcode", "value")
        if not code or len(code) == 0:
            return False
        return True

    @pyqtSlot()
    def wipeNozzle(self):
        return self._wipeNozzle()

    def _wipeNozzle(self):
        code = CuraApplication.getInstance().getGlobalContainerStack().getProperty("machine_wipe_gcode", "value")
        if not code or len(code) == 0:
            self.log("w", "This device doesn't support wiping")
            message = Message(text = catalog.i18nc("@message",
                                                   "The currently connected printer does not support Nozzle Wiping."),
                              title = catalog.i18nc("@message", "Print in Progress"),
                              message_type = Message.MessageType.ERROR)
            message.show()
            return
        safe = self.ensureSafeToWrite()
        if not safe:
            # We can't wipe, there's probably already a print in progress
            return
        code = code.replace("{material_soften_temperature}", str(CuraApplication.getInstance().getGlobalContainerStack().getProperty("material_soften_temperature", "value")))#.split("\n")
        self.writeStarted.emit(self)
        self._printGCode(code)

    @pyqtProperty(bool, notify = printersChanged)
    def supportLevelXAxis(self):
        return self._supportLevelXAxis()

    def _supportLevelXAxis(self):
        code = CuraApplication.getInstance().getGlobalContainerStack().getProperty("machine_level_x_axis_gcode", "value")
        if not code or len(code) == 0:
            return False
        return True

    @pyqtSlot()
    def levelXAxis(self):
        return self._levelXAxis()

    def _levelXAxis(self):
        code = CuraApplication.getInstance().getGlobalContainerStack().getProperty("machine_level_x_axis_gcode", "value")
        if not code or len(code) == 0:
            self.log("w", "This device doesn't support x axis levelling")
            message = Message(text = catalog.i18nc("@message",
                                                   "The currently connected printer does not support X Axis Leveling."),
                              title = catalog.i18nc("@message", "Print in Progress"),
                              message_type = Message.MessageType.ERROR)
            message.show()
            return
        safe = self.ensureSafeToWrite()
        if not safe:
            # We can't level, there's probably already a print in progress
            return
        # code = code.split("\n")
        self.writeStarted.emit(self)
        self._printGCode(code)


    ####################################################

    # def _onGlobalContainerStackChanged(self):
    #     if self._serial is not None:
    #         self.close()
    #     container_stack = CuraApplication.getInstance().getGlobalContainerStack()
    #     if container_stack is None:
    #         return
    #     num_extruders = container_stack.getProperty("machine_extruder_count", "value")
    #     # Ensure that a printer is created.
    #     controller = GenericOutputController(self)
    #     controller.setCanUpdateFirmware(True)
    #     self._printers = [PrinterOutputModel(output_controller = controller, number_of_extruders = num_extruders)]
    #     self._printers[0].updateName(container_stack.getName())
