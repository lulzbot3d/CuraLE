# Copyright (c) 2020 Ultimaker B.V.
# Cura is released under the terms of the LGPLv3 or higher.

from .avr_isp import stk500v2, ispBase, intelHex
import serial   # type: ignore
import threading
import time
import queue
import re
import functools

from UM.i18n import i18nCatalog
from UM.Logger import Logger
from UM.Mesh.MeshWriter import MeshWriter #To get the g-code output.
from UM.Message import Message #Show an error when already printing.
from UM.PluginRegistry import PluginRegistry #To get the g-code output.
from UM.Qt.Duration import DurationFormat

from cura.CuraApplication import CuraApplication
from cura.PrinterOutput.PrinterOutputDevice import PrinterOutputDevice, ConnectionState, ConnectionType
from cura.PrinterOutput.Models.PrinterOutputModel import PrinterOutputModel
from cura.PrinterOutput.Models.PrintJobOutputModel import PrintJobOutputModel
from cura.PrinterOutput.GenericOutputController import GenericOutputController

from .AutoDetectBaudJob import AutoDetectBaudJob
from .AvrFirmwareUpdater import AvrFirmwareUpdater

from io import StringIO #To write the g-code output.
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
    def __init__(self, serial_port: str, baud_rate: Optional[int] = None) -> None:
        super().__init__(serial_port, connection_type = ConnectionType.UsbConnection)
        self.setName(catalog.i18nc("@item:inmenu", "USB printing"))
        self.setShortDescription(catalog.i18nc("@action:button Preceded by 'Ready to'.", "Print via USB"))
        self.setDescription(catalog.i18nc("@info:tooltip", "Print via USB"))
        self.setIconName("print")
        self.setConnectionText(catalog.i18nc("@info:status", "Connected via USB"))

        self._serial = None  # type: Optional[Serial]
        self._serial_port = serial_port
        self._address = serial_port

        self._connect_thread = threading.Thread(target = self._connect)
        self._connect_thread.daemon = True

        self._end_stop_thread = None
        self._poll_endstop = False

        # The baud checking is done by sending a number of m105 commands to the printer and waiting for a readable
        # response. If the baudrate is correct, this should make sense, else we get giberish.
        self._required_responses_auto_baud = 3

        self._listen_thread = threading.Thread(target=self._listen)
        self._listen_thread.daemon = True

        self._update_firmware_thread = threading.Thread(target= self._updateFirmware)
        self._update_firmware_thread.daemon = True
        self.firmwareUpdateComplete.connect(self._onFirmwareUpdateComplete)

        self._heatup_wait_start_time = time.time()

        self.jobStateChanged.connect(self._onJobStateChanged)

        ## Queue for commands that need to be send. Used when command is sent when a print is active.
        self._command_queue = queue.Queue()

        self._is_printing = False
        self._is_paused = False

        ## Set when print is started in order to check running time.
        self._print_start_time = None
        self._print_estimated_time = None

        ## Keep track where in the provided g-code the print is
        self._gcode_position = 0

        # List of gcode lines to be printed
        self._gcode = []

        # Check if endstops are ever pressed (used for first run)
        self._x_min_endstop_pressed = False
        self._y_min_endstop_pressed = False
        self._z_min_endstop_pressed = False

        self._x_max_endstop_pressed = False
        self._y_max_endstop_pressed = False
        self._z_max_endstop_pressed = False

        # In order to keep the connection alive we request the temperature every so often from a different extruder.
        # This index is the extruder we requested data from the last time.
        self._temperature_requested_extruder_index = 0

        self._current_z = 0

        self._updating_firmware = False

        self._firmware_file_name = None
        self._firmware_update_finished = False

        self._error_message = None
        self._error_code = 0

    onError = pyqtSignal()

    firmwareUpdateComplete = pyqtSignal()
    firmwareUpdateChange = pyqtSignal()

    endstopStateChanged = pyqtSignal(str ,bool, arguments = ["key","state"])

    def _setTargetBedTemperature(self, temperature):
        Logger.log("d", "Setting bed temperature to %s", temperature)
        self._sendCommand("M140 S%s" % temperature)

    def _setTargetHotendTemperature(self, index, temperature):
        Logger.log("d", "Setting hotend %s temperature to %s", index, temperature)
        self._sendCommand("M104 T%s S%s" % (index, temperature))

    def _setHeadPosition(self, x, y , z, speed):
        self._sendCommand("G0 X%s Y%s Z%s F%s" % (x, y, z, speed))

    def _setHeadX(self, x, speed):
        self._sendCommand("G0 X%s F%s" % (x, speed))

    def _setHeadY(self, y, speed):
        self._sendCommand("G0 Y%s F%s" % (y, speed))

    def _setHeadZ(self, z, speed):
        self._sendCommand("G0 Y%s F%s" % (z, speed))

    def _homeHead(self):
        self._sendCommand("G28 X")
        self._sendCommand("G28 Y")

    def _homeBed(self):
        self._sendCommand("G28 Z")

    ##  Updates the target bed temperature from the printer, and emit a signal if it was changed.
    #
    #   /param temperature The new target temperature of the bed.
    #   /return boolean, True if the temperature was changed, false if the new temperature has the same value as the already stored temperature
    def _updateTargetBedTemperature(self, temperature):
        if self._target_bed_temperature == temperature:
            return False
        self._target_bed_temperature = temperature
        self.targetBedTemperatureChanged.emit()
        return True

    ##  Updates the target hotend temperature from the printer, and emit a signal if it was changed.
    #
    #   /param index The index of the hotend.
    #   /param temperature The new target temperature of the hotend.
    #   /return boolean, True if the temperature was changed, false if the new temperature has the same value as the already stored temperature
    def _updateTargetHotendTemperature(self, index, temperature):
        if self._target_hotend_temperatures[index] == temperature:
            return False
        self._target_hotend_temperatures[index] = temperature
        self.targetHotendTemperaturesChanged.emit()
        return True

    ##  A name for the device.
    @pyqtProperty(str, constant = True)
    def name(self):
        return self.getName()

    ##  The address of the device.
    @pyqtProperty(str, constant = True)
    def address(self):
        return self._serial_port

    def startPrint(self):
        self.writeStarted.emit(self)
        active_build_plate_id = Application.getInstance().getBuildPlateModel().activeBuildPlate
        gcode_dict = getattr(Application.getInstance().getController().getScene(), "gcode_dict")
        gcode_list = gcode_dict[active_build_plate_id]

        self._updateJobState("printing")
        self.printGCode(gcode_list)

    def _moveHead(self, x, y, z, speed):
        self._sendCommand("G91")
        self._sendCommand("G0 X%s Y%s Z%s F%s" % (x, y, z, speed))
        self._sendCommand("G90")

    ##  Start a print based on a g-code.
    #   \param gcode_list List with gcode (strings).
    def printGCode(self, gcode_list):
        Logger.log("d", "Started printing g-code")
        if self._progress or self._connection_state != ConnectionState.connected:
            self._error_message = Message(catalog.i18nc("@info:status", "Unable to start a new job because the printer is busy or not connected."), title = catalog.i18nc("@info:title", "Printer Unavailable"))
            self._error_message.show()
            Logger.log("d", "Printer is busy or not connected, aborting print")
            self.writeError.emit(self)
            return

        self._gcode.clear()
        for layer in gcode_list:
            self._gcode.extend(layer.split("\n"))

        # Reset line number. If this is not done, first line is sometimes ignored
        self._gcode.insert(0, "M110")
        self._gcode_position = 0
        self._is_printing = True
        self._print_start_time = time.time()

        for i in range(0, 4):  # Push first 4 entries before accepting other inputs
            self._sendNextGcodeLine()

        self._is_printing = True
        self.writeFinished.emit(self)

    ##  Get the serial port string of this connection.
    #   \return serial port
    def getSerialPort(self):
        return self._serial_port

    ##  Try to connect the serial. This simply starts the thread, which runs _connect.
    def connect(self):
        if not self._updating_firmware and not self._connect_thread.isAlive():
            self._connect_thread.start()

    ##  Private function (threaded) that actually uploads the firmware.
    def _updateFirmware(self):
        Logger.log("d", "Attempting to update firmware")
        self._error_code = 0
        self.setProgress(0, 100)
        self._firmware_update_finished = False

        if self._connection_state != ConnectionState.closed:
            self.close()
        hex_file = intelHex.readHex(self._firmware_file_name)

        if len(hex_file) == 0:
            Logger.log("e", "Unable to read provided hex file. Could not update firmware")
            self._updateFirmwareFailedMissingFirmware()
            return

        programmer = stk500v2.Stk500v2()
        programmer.progress_callback = self.setProgress

        try:
            programmer.connect(self._serial_port)
        except Exception:
            programmer.close()
            pass

        # Give programmer some time to connect. Might need more in some cases, but this worked in all tested cases.
        time.sleep(1)

        if not programmer.isConnected():
            Logger.log("e", "Unable to connect with serial. Could not update firmware")
            self._updateFirmwareFailedCommunicationError()
            return
        if self._serial is None:
            try:
                self._serial = Serial(str(self._serial_port), self._baud_rate, timeout=self._timeout, writeTimeout=self._timeout)
            except SerialException:
                Logger.warning("An exception occurred while trying to create serial connection.")
                return
            except OSError as e:
                Logger.warning("The serial device is suddenly unavailable while trying to create a serial connection: {err}".format(err = str(e)))
                return
        CuraApplication.getInstance().globalContainerStackChanged.connect(self._onGlobalContainerStackChanged)
        self._onGlobalContainerStackChanged()
        self.setConnectionState(ConnectionState.Connected)
        self._update_thread.start()

        self._updating_firmware = True

        try:
            programmer.programChip(hex_file)
            self._updating_firmware = False
        except serial.SerialException as e:
            Logger.log("e", "SerialException while trying to update firmware: <%s>" %(repr(e)))
            self._updateFirmwareFailedIOError()
            return
        except Exception as e:
            Logger.log("e", "Exception while trying to update firmware: <%s>" %(repr(e)))
            self._updateFirmwareFailedUnknown()
            return
        programmer.close()

        self._updateFirmwareCompletedSucessfully()
        return

    ##  Private function which makes sure that firmware update process has failed by missing firmware
    def _updateFirmwareFailedMissingFirmware(self):
        return self._updateFirmwareFailedCommon(4)

    ##  Private function which makes sure that firmware update process has failed by an IO error
    def _updateFirmwareFailedIOError(self):
        return self._updateFirmwareFailedCommon(3)

    ##  Private function which makes sure that firmware update process has failed by a communication problem
    def _updateFirmwareFailedCommunicationError(self):
        return self._updateFirmwareFailedCommon(2)

    ##  Private function which makes sure that firmware update process has failed by an unknown error
    def _updateFirmwareFailedUnknown(self):
        return self._updateFirmwareFailedCommon(1)

    ##  Private common function which makes sure that firmware update process has completed/ended with a set progress state
    def _updateFirmwareFailedCommon(self, code):
        if not code:
            raise Exception("Error code not set!")

        self._error_code = code

        self._firmware_update_finished = True
        self.resetFirmwareUpdate(update_has_finished = True)
        self.progressChanged.emit()
        self.firmwareUpdateComplete.emit()

        return

    ##  Private function which makes sure that firmware update process has successfully completed
    def _updateFirmwareCompletedSucessfully(self):
        self.setProgress(100, 100)
        self._firmware_update_finished = True
        self.resetFirmwareUpdate(update_has_finished = True)
        self.firmwareUpdateComplete.emit()

        return

    ##  Upload new firmware to machine
    #   \param filename full path of firmware file to be uploaded
    def updateFirmware(self, file_name):
        Logger.log("i", "Updating firmware of %s using %s", self._serial_port, file_name)
        self._firmware_file_name = file_name
        self._update_firmware_thread.start()

    @property
    def firmwareUpdateFinished(self):
        return self._firmware_update_finished

    def resetFirmwareUpdate(self, update_has_finished = False):
        self._firmware_update_finished = update_has_finished
        self.firmwareUpdateChange.emit()

    @pyqtSlot()
    def startPollEndstop(self):
        if not self._poll_endstop:
            self._poll_endstop = True
            if self._end_stop_thread is None:
                self._end_stop_thread = threading.Thread(target=self._pollEndStop)
                self._end_stop_thread.daemon = True
            self._end_stop_thread.start()

    @pyqtSlot()
    def stopPollEndstop(self):
        self._poll_endstop = False
        self._end_stop_thread = None

    def _pollEndStop(self):
        while self._connection_state == ConnectionState.connected and self._poll_endstop:
            self.sendCommand("M119")
            time.sleep(0.5)

    ##  Private connect function run by thread. Can be started by calling connect.
    def _connect(self):
        Logger.log("d", "Attempting to connect to %s", self._serial_port)
        self.setConnectionState(ConnectionState.connecting)
        programmer = stk500v2.Stk500v2()
        try:
            programmer.connect(self._serial_port) # Connect with the serial, if this succeeds, it's an arduino based usb device.
            self._serial = programmer.leaveISP()
        except ispBase.IspError as e:
            programmer.close()
            Logger.log("i", "Could not establish connection on %s: %s. Device is not arduino based." %(self._serial_port,str(e)))
        except Exception as e:
            programmer.close()
            Logger.log("i", "Could not establish connection on %s, unknown reasons.  Device is not arduino based." % self._serial_port)

        # If the programmer connected, we know its an atmega based version.
        # Not all that useful, but it does give some debugging information.
        for baud_rate in self._getBaudrateList(): # Cycle all baud rates (auto detect)
            Logger.log("d", "Attempting to connect to printer with serial %s on baud rate %s", self._serial_port, baud_rate)
            if self._serial is None:
                try:
                    self._serial = serial.Serial(str(self._serial_port), baud_rate, timeout = 3, writeTimeout = 10000)
                    time.sleep(10)
                except serial.SerialException:
                    Logger.log("d", "Could not open port %s" % self._serial_port)
                    continue
            else:
                if not self.setBaudRate(baud_rate):
                    continue  # Could not set the baud rate, go to the next

            time.sleep(1.5) # Ensure that we are not talking to the bootloader. 1.5 seconds seems to be the magic number
            sucesfull_responses = 0
            timeout_time = time.time() + 5
            self._serial.write(b"\n")
            self._sendCommand("M105")  # Request temperature, as this should (if baudrate is correct) result in a command with "T:" in it
            while timeout_time > time.time():
                line = self._readline()
                if line is None:
                    Logger.log("d", "No response from serial connection received.")
                    # Something went wrong with reading, could be that close was called.
                    self.setConnectionState(ConnectionState.closed)
                    return

                if b"T:" in line:
                    Logger.log("d", "Correct response for auto-baudrate detection received.")
                    self._serial.timeout = 0.5
                    sucesfull_responses += 1
                    if sucesfull_responses >= self._required_responses_auto_baud:
                        self._serial.timeout = 2 # Reset serial timeout
                        self.setConnectionState(ConnectionState.connected)
                        self._listen_thread.start()  # Start listening
                        Logger.log("i", "Established printer connection on port %s" % self._serial_port)
                        return

                self._sendCommand("M105")  # Send M105 as long as we are listening, otherwise we end up in an undefined state

        Logger.log("e", "Baud rate detection for %s failed", self._serial_port)
        self.close()  # Unable to connect, wrap up.
        self.setConnectionState(ConnectionState.closed)

    ##  Set the baud rate of the serial. This can cause exceptions, but we simply want to ignore those.
    def setBaudRate(self, baud_rate):
        try:
            self._serial.baudrate = baud_rate
            return True
        except Exception as e:
            return False

    ##  Close the printer connection
    def close(self):
        Logger.log("d", "Closing the USB printer connection.")
        if self._connect_thread.isAlive():
            try:
                self._connect_thread.join()
            except Exception as e:
                Logger.log("d", "PrinterConnection.close: %s (expected)", e)
                pass # This should work, but it does fail sometimes for some reason

        self._connect_thread = threading.Thread(target = self._connect)
        self._connect_thread.daemon = True

        self.setConnectionState(ConnectionState.closed)
        if self._serial is not None:
            try:
                self._listen_thread.join()
            except:
                pass
            if self._serial is not None:    # Avoid a race condition when a thread can change the value of self._serial to None
                self._serial.close()

        self._listen_thread = threading.Thread(target = self._listen)
        self._listen_thread.daemon = True
        self._serial = None

    ##  Directly send the command, withouth checking connection state (eg; printing).
    #   \param cmd string with g-code
    def _sendCommand(self, cmd):
        if self._serial is None:
            return

        if "M109" in cmd or "M190" in cmd:
            self._heatup_wait_start_time = time.time()

        try:
            command = (cmd + "\n").encode()
            self._serial.write(b"\n")
            self._serial.write(command)
        except serial.SerialTimeoutException:
            Logger.log("w","Serial timeout while writing to serial port, trying again.")
            try:
                time.sleep(0.5)
                self._serial.write((cmd + "\n").encode())
            except Exception as e:
                Logger.log("e","Unexpected error while writing serial port %s " % e)
                self._setErrorState("Unexpected error while writing serial port %s " % e)
                self.close()
        except Exception as e:
            Logger.log("e","Unexpected error while writing serial port %s" % e)
            self._setErrorState("Unexpected error while writing serial port %s " % e)
            self.close()

    ##  Send a command to printer.
    #   \param cmd string with g-code
    def sendCommand(self, cmd):
        if self._progress:
            self._command_queue.put(cmd)
        elif self._connection_state == ConnectionState.connected:
            self._sendCommand(cmd)

                    if extruder_nr >= len(self._printers[0].extruders):
                        Logger.log("w", "Printer reports more temperatures than the number of configured extruders")
                        continue

                    extruder = self._printers[0].extruders[extruder_nr]
                    if match[1]:
                        extruder.updateHotendTemperature(float(match[1]))
                    if match[2]:
                        extruder.updateTargetHotendTemperature(float(match[2]))

                bed_temperature_matches = re.findall(b"B: ?(\d+\.?\d*)\s*\/?(\d+\.?\d*)?", line)
                if bed_temperature_matches:
                    match = bed_temperature_matches[0]
                    if match[0]:
                        self._printers[0].updateBedTemperature(float(match[0]))
                    if match[1]:
                        self._printers[0].updateTargetBedTemperature(float(match[1]))

        self.setJobName(file_name)
        self._print_estimated_time = int(Application.getInstance().getPrintInformation().currentPrintTime.getDisplayString(DurationFormat.Format.Seconds))

        Application.getInstance().getController().setActiveStage("MonitorStage")
        self.startPrint()

    def _setEndstopState(self, endstop_key, value):
        if endstop_key == b"x_min":
            if self._x_min_endstop_pressed != value:
                self.endstopStateChanged.emit("x_min", value)
            self._x_min_endstop_pressed = value
        elif endstop_key == b"y_min":
            if self._y_min_endstop_pressed != value:
                self.endstopStateChanged.emit("y_min", value)
            self._y_min_endstop_pressed = value
        elif endstop_key == b"z_min":
            if self._z_min_endstop_pressed != value:
                self.endstopStateChanged.emit("z_min", value)
            self._z_min_endstop_pressed = value

    ##  Listen thread function.
    def _listen(self):
        Logger.log("i", "Printer connection listen thread started for %s" % self._serial_port)
        container_stack = Application.getInstance().getGlobalContainerStack()
        temperature_request_timeout = time.time()
        ok_timeout = time.time()
        while self._connection_state == ConnectionState.connected:
            line = self._readline()
            if line is None:
                break  # None is only returned when something went wrong. Stop listening

            if time.time() > temperature_request_timeout:
                if self._num_extruders > 1:
                    self._temperature_requested_extruder_index = (self._temperature_requested_extruder_index + 1) % self._num_extruders
                    self.sendCommand("M105 T%d" % (self._temperature_requested_extruder_index))
                else:
                    self.sendCommand("M105")
                temperature_request_timeout = time.time() + 5

            if line.startswith(b"Error:"):
                # Oh YEAH, consistency.
                # Marlin reports a MIN/MAX temp error as "Error:x\n: Extruder switched off. MAXTEMP triggered !\n"
                # But a bed temp error is reported as "Error: Temperature heated bed switched off. MAXTEMP triggered !!"
                # So we can have an extra newline in the most common case. Awesome work people.
                if re.match(b"Error:[0-9]\n", line):
                    line = line.rstrip() + self._readline()

                # Skip the communication errors, as those get corrected.
                if b"Extruder switched off" in line or b"Temperature heated bed switched off" in line or b"Something is wrong, please turn off the printer." in line:
                    if not self.hasError():
                        self._setErrorState(line[6:])

            elif b" T:" in line or line.startswith(b"T:"):  # Temperature message
                temperature_matches = re.findall(b"T(\d*): ?([\d\.]+) ?\/?([\d\.]+)?", line)
                temperature_set = False
                try:
                    for match in temperature_matches:
                        if match[0]:
                            extruder_nr = int(match[0])
                            if extruder_nr >= container_stack.getProperty("machine_extruder_count", "value"):
                                continue
                            if match[1]:
                                self._setHotendTemperature(extruder_nr, float(match[1]))
                                temperature_set = True
                            if match[2]:
                                self._updateTargetHotendTemperature(extruder_nr, float(match[2]))
                        else:
                            requested_temperatures = match
                    if not temperature_set and requested_temperatures:
                        if requested_temperatures[1]:
                            self._setHotendTemperature(self._temperature_requested_extruder_index, float(requested_temperatures[1]))
                        if requested_temperatures[2]:
                            self._updateTargetHotendTemperature(self._temperature_requested_extruder_index, float(requested_temperatures[2]))
                except:
                    Logger.log("w", "Could not parse hotend temperatures from response: %s", line)
                # Check if there's also a bed temperature
                temperature_matches = re.findall(b"B: ?([\d\.]+) ?\/?([\d\.]+)?", line)
                if container_stack.getProperty("machine_heated_bed", "value") and len(temperature_matches) > 0:
                    match = temperature_matches[0]
                    try:
                        if match[0]:
                            self._setBedTemperature(float(match[0]))
                        if match[1]:
                            self._updateTargetBedTemperature(float(match[1]))
                    except:
                        Logger.log("w", "Could not parse bed temperature from response: %s", line)

            elif b"_min" in line or b"_max" in line:
                tag, value = line.split(b":", 1)
                self._setEndstopState(tag,(b"H" in value or b"TRIGGERED" in value))

            if self._is_printing:
                if line == b"" and time.time() > ok_timeout:
                    line = b"ok"  # Force a timeout (basically, send next command)

                if b"ok" in line:
                    ok_timeout = time.time() + 5
                    if not self._command_queue.empty():
                        self._sendCommand(self._command_queue.get())
                    elif self._is_paused:
                        line = b""  # Force getting temperature as keep alive
                    else:
                        self._sendNextGcodeLine()
                elif b"resend" in line.lower() or b"rs" in line:  # Because a resend can be asked with "resend" and "rs"
                    try:
                        Logger.log("d", "Got a resend response")
                        self._gcode_position = int(line.replace(b"N:",b" ").replace(b"N",b" ").replace(b":",b" ").split()[-1])
                    except:
                        if b"rs" in line:
                            self._gcode_position = int(line.split()[1])

            # Request the temperature on comm timeout (every 2 seconds) when we are not printing.)
            if line == b"":
                if self._num_extruders > 1:
                    self._temperature_requested_extruder_index = (self._temperature_requested_extruder_index + 1) % self._num_extruders
                    self.sendCommand("M105 T%d" % self._temperature_requested_extruder_index)
                else:
                    self.sendCommand("M105")

        Logger.log("i", "Printer connection listen thread stopped for %s" % self._serial_port)

    ##  Send next Gcode in the gcode list
    def _sendNextGcodeLine(self):
        if self._gcode_position >= len(self._gcode):
            return
        line = self._gcode[self._gcode_position]

        if ";" in line:
            line = line[:line.find(";")]
        line = line.strip()

        # Don't send empty lines. But we do have to send something, so send
        # m105 instead.
        # Don't send the M0 or M1 to the machine, as M0 and M1 are handled as
        # an LCD menu pause.
        if line == "" or line == "M0" or line == "M1":
            line = "M105"
        try:
            if ("G0" in line or "G1" in line) and "Z" in line:
                z = float(re.search("Z([0-9\.]*)", line).group(1))
                if self._current_z != z:
                    self._current_z = z
        except Exception as e:
            Logger.log("e", "Unexpected error with printer connection, could not parse current Z: %s: %s" % (e, line))
            self._setErrorState("Unexpected error: %s" %e)
        checksum = functools.reduce(lambda x,y: x^y, map(ord, "N%d%s" % (self._gcode_position, line)))

        self._sendCommand("N%d%s*%d" % (self._gcode_position, line, checksum))

        progress = (self._gcode_position / len(self._gcode))

        elapsed_time = int(time.time() - self._print_start_time)
        self.setTimeElapsed(elapsed_time)
        estimated_time = self._print_estimated_time
        if progress > .1:
            estimated_time = self._print_estimated_time * (1-progress) + elapsed_time
        self.setTimeTotal(estimated_time)

        self._gcode_position += 1
        self.setProgress(progress * 100)
        self.progressChanged.emit()

    ##  Set the state of the print.
    #   Sent from the print monitor
    def _setJobState(self, job_state):
        if job_state == "pause":
            self._is_paused = True
            self._updateJobState("paused")
        elif job_state == "print":
            self._is_paused = False
            self._updateJobState("printing")
        elif job_state == "abort":
            self.cancelPrint()

    def _onJobStateChanged(self):
        # clear the job name & times when printing is done or aborted
        if self._job_state == "ready":
            self.setJobName("")
            self.setTimeElapsed(0)
            self.setTimeTotal(0)

    ##  Set the progress of the print.
    #   It will be normalized (based on max_progress) to range 0 - 100
    def setProgress(self, progress, max_progress = 100):
        self._progress = (progress / max_progress) * 100  # Convert to scale of 0-100
        if self._progress == 100:
            # Printing is done, reset progress
            self._gcode_position = 0
            self.setProgress(0)
            self._is_printing = False
            self._is_paused = False
            self._updateJobState("ready")
        self.progressChanged.emit()

    ##  Cancel the current print. Printer connection wil continue to listen.
    def cancelPrint(self):
        self._gcode_position = 0
        self.setProgress(0)
        self._gcode = []

        # Turn off temperatures, fan and steppers
        self._sendCommand("M140 S0")
        self._sendCommand("M104 S0")
        self._sendCommand("M107")
        # Home XY to prevent nozzle resting on aborted print
        # Don't home bed because it may crash the printhead into the print on printers that home on the bottom
        self.homeHead()
        self._sendCommand("M84")
        self._is_printing = False
        self._is_paused = False
        self._updateJobState("ready")
        Application.getInstance().getController().setActiveStage("PrepareStage")

    ##  Check if the process did not encounter an error yet.
    def hasError(self):
        return self._error_state is not None

    ##  private read line used by printer connection to listen for data on serial port.
    def _readline(self):
        if self._serial is None:
            return None
        try:
            ret = self._serial.readline()
        except Exception as e:
            Logger.log("e", "Unexpected error while reading serial port. %s" % e)
            self._setErrorState("Printer has been disconnected")
            self.close()
            return None
        return ret

    ##  Create a list of baud rates at which we can communicate.
    #   \return list of int
    def _getBaudrateList(self):
        ret = [115200, 250000, 230400, 57600, 38400, 19200, 9600]
        return ret

    def _onFirmwareUpdateComplete(self):
        self._update_firmware_thread.join()
        self._update_firmware_thread = threading.Thread(target = self._updateFirmware)
        self._update_firmware_thread.daemon = True

        self.connect()

    ##  Pre-heats the heated bed of the printer, if it has one.
    #
    #   \param temperature The temperature to heat the bed to, in degrees
    #   Celsius.
    #   \param duration How long the bed should stay warm, in seconds. This is
    #   ignored because there is no g-code to set this.
    @pyqtSlot(float, float)
    def preheatBed(self, temperature, duration):
        Logger.log("i", "Pre-heating the bed to %i degrees.", temperature)
        self._setTargetBedTemperature(temperature)
        self.preheatBedRemainingTimeChanged.emit()

    ##  Cancels pre-heating the heated bed of the printer.
    #
    #   If the bed is not pre-heated, nothing happens.
    @pyqtSlot()
    def cancelPreheatBed(self):
        Logger.log("i", "Cancelling pre-heating of the bed.")
        self._setTargetBedTemperature(0)
        self.preheatBedRemainingTimeChanged.emit()

#################################################################################
#                               ConnectThread                                   #
#################################################################################
class ConnectThread:
    def __init__(self, parent):
        # TODO: Any access to the parent object from the ConnectThread is
        # potentially not thread-safe and ought to be reviewed at some point.
        self._parent = parent

        self._thread = threading.Thread(target = self._connect_func)
        self._thread.daemon = True

        self._write_requested = False

        # The baud checking is done by sending a number of m105 commands to the printer and waiting for a readable
        # response. If the baudrate is correct, this should make sense, else we get giberish.
        self._required_responses_auto_baud = 3

    def start(self):
        return  self._thread.start()

    def isAlive(self):
        return  self._thread.isAlive()

    def wrapup(self):
        if self._thread.isAlive():
            try:
                # TODO: to avoid waiting indefinitely, notify the thread that it needs
                # to return immediatly.
                self._thread.join()
            except Exception as e:
                self._parent.log("d", "PrinterConnection.close: %s (expected)", e)
                pass # This should work, but it does fail sometimes for some reason

    def setAutoStartOnConnect(self, value):
        self._write_requested = value

    ##  Create a list of baud rates at which we can communicate.
    #   \return list of int
    def _getBaudrateList(self):
        ret = [250000, 115200, 57600, 38400, 19200, 9600]
        return ret

    ##  private read line used by ConnectThread to listen for data on serial port.
    def _readline(self):
        if self._parent._serial is None:
            return None
        try:
            ret = self._parent._serial.readline()
        except Exception as e:
            self._parent.log("e", "Unexpected error while reading serial port. %s" % e)
            self._parent._setErrorState("Printer has been disconnected")
            self._parent.close()
            return None
        return ret

    ##  Directly send the command, withouth checking connection state (eg; printing).
    #   \param cmd string with g-code
    def _sendCommand(self, cmd):
        if self._parent._serial is None:
            return

        try:
            command = (cmd + "\n").encode()
            self._parent._serial.write(b"\n")
            self._parent._serial.write(command)
        except serial.SerialTimeoutException:
            self._parent.log("w","Serial timeout while writing to serial port, trying again.")
            try:
                time.sleep(0.5)
                self._parent._serial.write((cmd + "\n").encode())
            except Exception as e:
                self._parent.log("e","Unexpected error while writing serial port %s " % e)
                self._parent._setErrorState("Unexpected error while writing serial port %s " % e)
                self._parent.close()
        except Exception as e:
            self._parent.log("e","Unexpected error while writing serial port %s" % e)
            self._parent._setErrorState("Unexpected error while writing serial port %s " % e)
            self._parent.close()

    ##  Private connect function run by thread. Can be started by calling connect.
    def _connect_func(self):
        port = Application.getInstance().getGlobalContainerStack().getProperty("machine_port", "value")
        if port != "AUTO":
            self._parent._serial_port = port
            self._parent._autodetect_port = False

        self._parent.log("d", "Attempting to connect to %s", self._parent._serial_port)
        self._parent.setConnectionState(ConnectionState.connecting)

        if self._parent._autodetect_port:
            self._parent.setConnectionText(catalog.i18nc("@info:status", "Scanning available serial ports for printers"))
            self._parent._detectSerialPort()
            if self._parent._serial_port == None:
                ## Do not return from function right away, first set the right state
                self._parent.setConnectionText(catalog.i18nc("@info:status", "Failed to find a printer via USB"))
                self._parent.log("e", "Failed to find a printer via USB")
                self._parent.close()  # Unable to connect, wrap up the parent thread.
                self._parent.setConnectionState(ConnectionState.closed)
                return
        else:
            self._parent.setConnectionText(catalog.i18nc("@info:status", "Connecting to USB device"))

        baud_rate = Application.getInstance().getGlobalContainerStack().getProperty("machine_baudrate", "value")
        if baud_rate != "AUTO":
            self._parent.setConnectionText(catalog.i18nc("@info:status", "Connecting"))
            self._parent.log("d", "Attempting to connect to printer with serial %s on baud rate %s", self._parent._serial_port, baud_rate)
            if self._parent._serial is None:
                try:
                    self._parent._serial = serial.Serial(str(self._parent._serial_port), baud_rate, timeout=3, writeTimeout=10000)
                    # 10 seconds is too much to sleep?
                    time.sleep(1)
                except serial.SerialException:
                    self._parent.log("e", "Could not open port %s" % self._parent._serial_port)
                    self._parent.log("e", "Failed to open USB serial")
                    self._parent.close()  # Unable to connect, wrap up the parent thread.
                    self._parent.setConnectionState(ConnectionState.closed)
                    return
            else:
                self._parent.setBaudRate(baud_rate)

            time.sleep(1.5)
            timeout_time = time.time() + 5
            self._parent._serial.write(b"\n")
            self._sendCommand("M105")
            while timeout_time > time.time():
                line = self._readline()
                if line is None:
                    self._onNoResponseReceived()
                    return

                if b"T:" in line:
                    self._parent.log("d", "Correct response for connection")
                    self._parent._serial.timeout = 2  # Reset serial timeout
                    self._onConnectionSucceeded()
                    return

            sucesfull_responses = 0
            timeout_time = time.time() + 5
            self._parent._serial.write(b"\n")
            self._sendCommand("M105")  # Request temperature, as this should (if baudrate is correct) result in a command with "T:" in it
            while timeout_time > time.time():
                line = self._readline()
                if line is None:
                    _onNoResponseReceived()
                    return

                if b"T:" in line:
                    self._parent.log("d", "Correct response for auto-baudrate detection received.")
                    self._parent._serial.timeout = 0.5
                    sucesfull_responses += 1
                    if sucesfull_responses >= self._required_responses_auto_baud:
                        self._parent._serial.timeout = 2 # Reset serial timeout
                        self._onConnectionSucceeded()
                        return

                self._sendCommand("M105")  # Send M105 as long as we are listening, otherwise we end up in an undefined state

        self._parent.log("e", "Can't connect to printer on %s", self._parent._serial_port)
        self._parent.close()  # Unable to connect, wrap up.
        self._parent.setConnectionState(ConnectionState.closed)
        self._parent.setConnectionText(catalog.i18nc("@info:status", "Can't connect to printer"))
        self._parent._serial_port = None

    class CheckFirmwareStatus(Enum):
        OK = 0
        TIMEOUT = 1
        WRONG_MACHINE = 2
        WRONG_TOOLHEAD = 3
        FIRMWARE_OUTDATED = 4

    def _checkFirmware(self):
        self._sendCommand("\nM115")
        timeout = time.time() + 2
        reply = self._readline()
        while b"FIRMWARE_NAME" not in reply and time.time() < timeout:
            reply = self._readline()

        if b"FIRMWARE_NAME" not in reply:
            return self.CheckFirmwareStatus.TIMEOUT

        firmware_string = reply.decode()
        values = {m[0] : m[1] for m in re.findall("([A-Z_]+)\:(.*?)(?= [A-Z_]+\:|$)", firmware_string)}

        self._parent._connection_data = values
        self._parent.connectionDataChanged.emit()

        global_container_stack = Application.getInstance().getGlobalContainerStack()

        class CheckValueStatus(Enum):
            OK = 0
            MISSING_VALUE_IN_REPLY = 1
            WRONG_VALUE = 2
            MISSING_VALUE_IN_DEFINITION = 3

        def checkValue(fw_key, profile_key, exact_match = True, search_in_properties = False):
            expected_value = global_container_stack.getProperty(profile_key, "value") if search_in_properties else\
                global_container_stack.getMetaDataEntry(profile_key, None)
            if expected_value is None:
                self._parent.log("d", "Missing %s in profile. Skipping check." % profile_key)
                return CheckValueStatus.MISSING_VALUE_IN_DEFINITION
            elif not fw_key in values:
                self._parent.log("d", "Missing %s in firmware string: %s" % (fw_key, firmware_string))
                return CheckValueStatus.MISSING_VALUE_IN_REPLY
            elif exact_match and values[fw_key] != expected_value:
                self._parent.log("e", "Expected that %s was %s, but got %s instead" % (fw_key, expected_value, values[fw_key]))
                return CheckValueStatus.WRONG_VALUE
            elif not exact_match and not values[fw_key].search(expected_value):
                self._parent.log("e", "Expected that %s contained %s, but got %s instead" % (fw_key, expected_value, values[fw_key]))
                return CheckValueStatus.WRONG_VALUE
            return CheckValueStatus.OK

        list_to_check = [
            {
                "reply_key": "MACHINE_TYPE",
                "definition_key": "firmware_machine_type",
                "on_fail": self.CheckFirmwareStatus.WRONG_MACHINE,
                "search_in_properties": True
            },
            {
                "reply_key": "EXTRUDER_TYPE",
                "definition_key": "firmware_toolhead_name",
                "on_fail": self.CheckFirmwareStatus.WRONG_TOOLHEAD
            },
            {
                "reply_key": "FIRMWARE_VERSION",
                "definition_key": "firmware_last_version",
                "on_fail": self.CheckFirmwareStatus.FIRMWARE_OUTDATED
            }
        ]
        for option in list_to_check:
            result = checkValue(option["reply_key"], option["definition_key"], option.get("exact_match", True), option.get("search_in_properties", False))
            if result != CheckValueStatus.OK:
                if result == CheckValueStatus.MISSING_VALUE_IN_DEFINITION:
                    pass
                elif result == CheckValueStatus.MISSING_VALUE_IN_REPLY:
                    return self.CheckFirmwareStatus.FIRMWARE_OUTDATED
                else:
                    return option["on_fail"]

        return self.CheckFirmwareStatus.OK

    def _onNoResponseReceived(self):
        self._parent.log("d", "No response from serial connection received.")
        # Something went wrong with reading, could be that close was called.
        self._parent.close()  # Unable to connect, wrap up.
        self._parent.setConnectionState(ConnectionState.closed)
        self._parent.setConnectionText(catalog.i18nc("@info:status", "Connection to USB device failed"))
        self._parent._serial_port = None

    def _onConnectionSucceeded(self):
        def showWarning(self, shortMsg, longMsg):
            self._parent.log("d", shortMsg)
            self._parent._error_message = Message(catalog.i18nc("@info:status", longMsg), dismissable=True, lifetime=None)
            self._parent._error_message.show()
        check_firmware_status = self._checkFirmware()
        if check_firmware_status == self.CheckFirmwareStatus.FIRMWARE_OUTDATED:
            showWarning(self, "Installed firmware is outdated", "New printer firmware is available. Use \"Settings -> Printer -> Manage Printers... -> Upgrade Firmware\" to upgrade.")
        elif check_firmware_status == self.CheckFirmwareStatus.WRONG_MACHINE:
            allow_connecction = Preferences.getInstance().getValue("cura/allow_connection_to_wrong_machine")
            if not allow_connecction:
                showWarning(self, "Wrong machine detected.", "Wrong printer detected, starting a print with the incorrect printer selected may damage your printer. You can disable this check in application settings")
                self._parent.close()  # Unable to connect, wrap up.
                self._parent.setConnectionState(ConnectionState.closed)
                return
            else:
                showWarning(self, "Wrong machine detected.",
                            "Wrong printer detected, starting a print with the incorrect printer selected may damage your printer.")
        elif check_firmware_status == self.CheckFirmwareStatus.WRONG_TOOLHEAD:
            self._parent.log("d", "Tried to connect to machine with wrong toolhead")
            showWarning(self, "Wrong toolhead detected.", "Wrong toolhead detected. Please change this if it is not what you want.")
            #self._parent.close()  # Unable to connect, wrap up.
            #self._parent.setConnectionState(ConnectionState.closed)
            Application.getInstance().getMachineManager().toolheadChanged.emit()
            #return
        elif check_firmware_status == self.CheckFirmwareStatus.TIMEOUT:
            showWarning(self, "Connection timeout.", "Failed to determine installed firmware version.")
        self._parent.setConnectionText(catalog.i18nc("@info:status", "Connected via USB"))
        self._parent.setConnectionState(ConnectionState.connected)

        if self._parent.eeprom_update:
            self._sendCommand("M502")
            self._sendCommand("M500")
            self._parent.log("d", "Tried to update EEPROM")
            self._parent.eeprom_update = False

        self._parent._print_thread.start()  # Start listening
        self._parent.log("i", "Established printer connection on port %s" % self._parent._serial_port)
        if check_firmware_status == self.CheckFirmwareStatus.OK:
            if self._write_requested:
                self._parent.startPrint()
            self._write_requested = False

#################################################################################
#                            UpdateFirmwareThread                               #
#################################################################################

class UpdateFirmwareThread:
    def __init__(self, parent):
        # TODO: Any access to the parent object from the UpdateFirmwareThread is
        # potentially not thread-safe and ought to be reviewed at some point.
        self._parent = parent

        self._thread = threading.Thread(target= self._update_firmware_func)
        self._thread.daemon = True
        self._parent.firmwareUpdateComplete.connect(self._onFirmwareUpdateComplete)

        self._updating_firmware = False

        self._firmware_file_name = None
        self._firmware_update_finished = False

    def startFirmwareUpdate(self, file_name):
        self._parent.log("i", "Updating firmware of %s using %s", self._parent._serial_port, file_name)
        self._firmware_file_name = file_name
        self._thread.start()

    def _onFirmwareUpdateComplete(self):
        self._thread.join()
        self._thread = threading.Thread(target = self._update_firmware_func)
        self._thread.daemon = True

        self._parent.connect()


    ##  Private function (threaded) that actually uploads the firmware.
    def _update_firmware_func(self):
        self._parent.log("d", "Attempting to update firmware")
        self._parent._error_code = 0
        self._parent.setProgress(0, 100)
        self._firmware_update_finished = False

        if self._parent._connection_state != ConnectionState.closed:
            self._parent.close()
        port = Application.getInstance().getGlobalContainerStack().getProperty("machine_port", "value")
        if port != "AUTO":
            self._parent._serial_port = port
        else:
            self._parent._detectSerialPort()

        if self._firmware_file_name.endswith('.hex'):
            ## We're loading HEX file
            self._parent.log("i", "Loading HEX firmware file" + self._firmware_file_name)
            try:
                hex_file = intelHex.readHex(self._firmware_file_name)
            except FileNotFoundError:
                self._parent.log("e", "Unable to find hex file. Could not update firmware")
                self._updateFirmwareFailedMissingFirmware()
                return

            if len(hex_file) == 0:
                self._parent.log("e", "Unable to read provided hex file. Could not update firmware")
                self._updateFirmwareFailedMissingFirmware()
                return

            programmer = stk500v2.Stk500v2()
            programmer.progress_callback = self._parent.setProgress

            try:
                programmer.connect(self._parent._serial_port)
            except Exception:
                programmer.close()
                pass

            # Give programmer some time to connect. Might need more in some cases, but this worked in all tested cases.
            time.sleep(1)

            if not programmer.isConnected():
                self._parent.log("e", "Unable to connect with serial. Could not update firmware")
                self._updateFirmwareFailedCommunicationError()
                return

            self._updating_firmware = True

            try:
                programmer.programChip(hex_file)
                self._updating_firmware = False
            except serial.SerialException as e:
                self._parent.log("e", "SerialException while trying to update firmware: <%s>" %(repr(e)))
                self._updateFirmwareFailedIOError()
                return
            except Exception as e:
                self._parent.log("e", "Exception while trying to update firmware: <%s>" %(repr(e)))
                self._updateFirmwareFailedUnknown()
                return
            programmer.close()
        elif self._firmware_file_name.endswith('.bin'):
            ##--> We're loading a BIN file
            self._parent.log("i", "Loading BIN firmware file: " + self._firmware_file_name)

            programmer = bossa.BOSSA()
            programmer.progress_callback = self._parent.setProgress

            try:
                programmer.reset(self._parent._serial_port)
            except Exception:
                programmer.close()
                pass

            try:
                programmer.connect(self._parent._serial_port)
            except Exception:
                programmer.close()
                self._parent._detectSerialPort(bootloader=True)
                try:
                    programmer.connect(self._parent._serial_port)
                except Exception:
                    programmer.close()
                    pass

            # Give programmer some time to connect. Might need more in some cases, but this worked in all tested cases.
            time.sleep(1)

            if not programmer.isConnected():
                self._parent.log("e", "Unable to connect with serial. Could not update firmware")
                self._updateFirmwareFailedCommunicationError()
                return

            self._updating_firmware = True

            try:
                programmer.flash_firmware(self._firmware_file_name)
                self._updating_firmware = False
            except serial.SerialException as e:
                self._parent.log("e", "SerialException while trying to update firmware: <%s>" %(repr(e)))
                self._updateFirmwareFailedIOError()
                return
            except Exception as e:
                self._parent.log("e", "Exception while trying to update firmware: <%s>" %(repr(e)))
                self._updateFirmwareFailedUnknown()
                return

            programmer.close()
        else:
            self._parent.log("e", "Unknown extension for firmware: " + self._firmware_file_name)
            self._updateFirmwareFailedUnknown()
            return

        self._updateFirmwareCompletedSucessfully()
        self._parent._serial_port = None
        return

    ##  Private function which makes sure that firmware update process has failed by missing firmware
    def _updateFirmwareFailedMissingFirmware(self):
        return self._updateFirmwareFailedCommon(4)

    ##  Private function which makes sure that firmware update process has failed by an IO error
    def _updateFirmwareFailedIOError(self):
        return self._updateFirmwareFailedCommon(3)

    ##  Private function which makes sure that firmware update process has failed by a communication problem
    def _updateFirmwareFailedCommunicationError(self):
        return self._updateFirmwareFailedCommon(2)

    ##  Private function which makes sure that firmware update process has failed by an unknown error
    def _updateFirmwareFailedUnknown(self):
        return self._updateFirmwareFailedCommon(1)

    ##  Private common function which makes sure that firmware update process has completed/ended with a set progress state
    def _updateFirmwareFailedCommon(self, code):
        if not code:
            raise Exception("Error code not set!")

        self._parent._error_code = code

        self._firmware_update_finished = True
        self._parent.firmwareUpdateChange.emit()
        self._parent.progressChanged.emit()
        self._parent.firmwareUpdateComplete.emit()

        return

    ##  Private function which makes sure that firmware update process has successfully completed
    def _updateFirmwareCompletedSucessfully(self):
        self._parent.setProgress(100, 100)
        self._firmware_update_finished = True
        self._parent.firmwareUpdateChange.emit()
        self._parent.firmwareUpdateComplete.emit()

        return

#################################################################################
#                                 PrintThread                                   #
#################################################################################

class PrintThread:
    def __init__(self, parent):
        # TODO: Any access to the parent object from the PrintThread is
        # potentially not thread-safe and ought to be reviewed at some point.
        self._parent = parent

        # Queue for commands that are sent while a print is active.
        self._command_queue = queue.Queue()

        # List of gcode lines to be printed
        self._gcode = []
        self._gcode_position = 0

        # Information needed to restart a paused print
        self._pauseState = None

        # Set to True to flush MarlinSerialProtocol buffers in thread
        self._flushBuffers = False

        # Set when print is started in order to check running time.
        self._print_start_time = None
        self._backend_print_time = None

        # Lock object for syncronizing accesses to self._gcode and other
        # variables which are shared between the UI thread and the
        # _print_thread thread.
        self._mutex = threading.Lock()

        # Event for when commands are added to self._command_queue
        self._commandAvailable = threading.Event();

        # Create the thread object

        self._thread = threading.Thread(target=self._print_func)
        self._thread.daemon = True

    def start(self):
        self._thread.start()

    def join(self):
        self._thread.join()

    def printGCode(self, gcode_list):
        self._mutex.acquire();
        self._gcode.clear()
        for layer in gcode_list:
            self._gcode.extend(layer.strip("\n").split("\n"))
        self._gcode_position = 0
        self._print_start_time_100 = None
        self._print_start_time = time.time()
        self._flushBuffers = True
        self._pauseState = None
        self._mutex.release();

    def cancelPrint(self):
        self._mutex.acquire();
        self._gcode = []
        while not self._command_queue.empty():
            self._command_queue.get()
        self._gcode_position = 0
        self._flushBuffers = True
        self._pauseState = None
        self._mutex.release();

    def _isHeaterCommand(self, cmd):
        """Checks whether we have a M109 or M190"""
        return cmd.startswith("M109") or cmd.startswith("M190")

    def _isInfiniteWait(self, cmd):
        """Sending a heater command with a temperature of zero will lead to an infinite wait"""
        if self._isHeaterCommand(cmd):
            search = re.search("[RS](-?[0-9\.]+)", cmd)
            return True if search and int(search.group(1)) == 0 else False
        else:
            return False

    def _parseTemperature(self, line, label, current_setter, target_setter):
        """Marlin reports current and target temperatures as 'T0:100.00 /100.00'.
           This extracts the temps and calls setter functions with the values."""
        m = re.search(b"%s: *([0-9\.]*)(?: */([0-9\.]*))?" % label, line)
        try:
            if m and m.group(1):
                current_setter(float(m.group(1)))
            if m and m.group(2):
                target_setter(float(m.group(2)))
        except ValueError:
            pass

    def sendCommand(self, cmd):
        """Sends a command to the printer. This command will take
           precedence over commands that are being send via printGCode"""
        if self._isInfiniteWait(cmd):
            return
        self._command_queue.put(cmd)
        self._commandAvailable.set()

    def _print_func(self):
        self._parent.log("i", "Printer connection listen thread started for %s" % self._parent._serial_port)

        try:
            self._backend_print_time = Application.getInstance().getPrintInformation().currentPrintTime.totalSeconds
        except:
            self._parent.log("w", "Failed to access PrintTime, setting it to zero")
            self._backend_print_time = 0
            pass

        # Wrap a MarlinSerialProtocol object around the serial port
        # for serial error correction.
        def onResendCallback(line):
            self._parent.log("i", "USBPrinterOutputDevice: Resending from: %d" % (line))

        try:
            serial_proto = MarlinSerialProtocol(self._parent._serial, onResendCallback)
        except Exception as e:
            self._parent.log("e", "Unexpected error while accessing marlin protocol. %s" % e)
            self._parent._setErrorState("Printer has been disconnected")
            self._parent.close()

        temperature_request_timeout = time.time()
        while self._parent._connection_state == ConnectionState.connected:

            self._mutex.acquire()
            if self._flushBuffers:
                serial_proto.sendCmdEmergency("M108")
                serial_proto.restart()
                self._flushBuffers = False

            isPrinting = (     self._parent._is_printing and
                           not self._parent._is_paused and
                               self._pauseState is None)
            self._mutex.release()

            try:
                # If we are printing, and Marlin can receive data, then send
                # the next line (unless there are immediate commands queued up)
                if serial_proto.clearToSend() and isPrinting and not self._commandAvailable.isSet():
                    line = self._getNextGcodeLine(serial_proto)
                    if line:
                        serial_proto.sendCmdReliable(line)

                # If we are printing, wait on data from the serial port;
                # otherwise wait for interactive commands when the serial
                # port is idle. This allows us to be most responsive to
                # whatever action is currently taking place
                if isPrinting:
                    line = serial_proto.readline(True)
                    iteractiveCmdAvailable = self._commandAvailable.isSet()
                else:
                    line = serial_proto.readline(False)
                    if line == b"":
                        iteractiveCmdAvailable = self._commandAvailable.wait(2)
                    else:
                        iteractiveCmdAvailable = self._commandAvailable.isSet()

                if  iteractiveCmdAvailable:
                    self._mutex.acquire()
                    cmd = self._command_queue.get()
                    if self._command_queue.empty():
                        self._commandAvailable.clear()
                    self._mutex.release()
                    serial_proto.sendCmdUnreliable(cmd)

                if isPrinting and (self._gcode_position > 1) and (b"start" in line):
                    self._parent.log("e", "The printer has restarted or lost power.")
                    self.cancelPrint()
                    self._parent._printingStopped()
                    self._parent.setProgress(0)
                    self._parent.close()
                    self._parent._error_message = Message(catalog.i18nc("@info:status", "The printer has restarted or lost power."), 0, True, None, 2)
                    self._parent._error_message.show()
                    break

            except Exception as e:
                self._parent.log("e", "Unexpected error while accessing serial port. %s" % e)
                self._parent._setErrorState("Printer has been disconnected")
                self._parent.close()
                break

            if line is None:
                break  # None is only returned when something went wrong. Stop listening

            if (b"//action:probe_failed" in line) or (b"PROBE FAIL CLEAN NOZZLE" in line):
                self._parent.errorFromPrinter.emit( "Wipe nozzle failed." )
                self._parent.log("d", "---------------PROBE FAIL CLEAN NOZZLE" )
                self._parent._error_message = Message(catalog.i18nc("@info:status", "Wipe nozzle failed, clean nozzle and reconnect printer."))
                self._parent._error_message.show()
                self._parent._setErrorState("Wipe nozzle failed")
                self._parent.close()
                break

            if b"//action:" in line:
                if b"out_of_filament" in line:
                    self._parent._error_message = Message(catalog.i18nc("@info:status", "Filament run out or filament jam."))
                    self._parent._error_message.show()

                if b"pause" in line:
                    self._parent._pausePrint()

                if b"resume" in line:
                    self._parent._resumePrint()

                if b"cancel" in line:
                    self._parent.cancelPrint()

                if b"disconnect" in line:
                    self._parent.close()

            if b"Z Offset " in line:
                value = line.split(b":")
                if len(value) == 3:
                    self._parent._ZOffset = float( value[2] )

            # If we keep getting a temperature_request_timeout, it likely
            # means that Marlin does not support AUTO_REPORT_TEMPERATURES,
            # in which case we must poll.
            if serial_proto.marlinBufferCapacity() > 1 and time.time() > temperature_request_timeout:
                self._parent.log("d", "Requesting temperature auto-update")
                serial_proto.sendCmdUnreliable("M155 S3")
                serial_proto.sendCmdUnreliable("M105")
                temperature_request_timeout = time.time() + 5

            if line.startswith(b"Error:"):
                #if b"PROBE FAIL CLEAN NOZZLE" in line:
                #   self._error_message = Message(catalog.i18nc("@info:status", "Wipe nozzle failed."))
                #   self._error_message.show()
                #   QMessageBox.critical(None, "Error wiping nozzle", "Probe fail clean nozzle"

                # Oh YEAH, consistency.
                # Marlin reports a MIN/MAX temp error as "Error:x\n: Extruder switched off. MAXTEMP triggered !\n"
                # But a bed temp error is reported as "Error: Temperature heated bed switched off. MAXTEMP triggered !!"
                # So we can have an extra newline in the most common case. Awesome work people.
                if re.match(b"Error:[0-9]\n", line):
                    line = line.rstrip() + serial_proto.readline()

                # Skip the communication errors, as those get corrected.
                if b"Extruder switched off" in line or b"Temperature heated bed switched off" in line or b"Something is wrong, please turn off the printer." in line:
                    if not self._parent.hasError():
                        self._parent._setErrorState(line[6:])

            if b"_min" in line or b"_max" in line:
                tag, value = line.split(b":", 1)
                self._parent._setEndstopState(tag,(b"H" in value or b"TRIGGERED" in value))

            if b"T:" in line:
                temperature_request_timeout = time.time() + 5
                # We got a temperature report line. If we have a dual extruder,
                # Marlin reports temperatures independently as T0: and T1:,
                # otherwise look for T:. Bed temperatures will be reported as B:
                if b" T0:" in line and b" T1:" in line:
                    if self._parent._num_extruders != 2:
                        self._parent._num_extruders = 2
                        PrinterOutputDevice._setNumberOfExtruders(self._parent, self._parent._num_extruders)
                    self._parseTemperature(line, b"T0",
                        lambda x: self._parent._setHotendTemperature(0,x),
                        lambda x: self._parent._emitTargetHotendTemperatureChanged(0,x)
                    )
                    self._parseTemperature(line, b"T1",
                        lambda x: self._parent._setHotendTemperature(1,x),
                        lambda x: self._parent._emitTargetHotendTemperatureChanged(1,x)
                    )
                else:
                    if self._parent._num_extruders != 1:
                        self._parent._num_extruders = 1
                        PrinterOutputDevice._setNumberOfExtruders(self._parent, self._parent._num_extruders)
                    self._parseTemperature(line, b"T",
                        lambda x: self._parent._setHotendTemperature(0,x),
                        lambda x: self._parent._emitTargetHotendTemperatureChanged(0,x)
                    )
                if b"B:" in line:  # Check if it's a bed temperature
                    self._parseTemperature(line, b"B",
                        lambda x: self._parent._setBedTemperature(x),
                        lambda x: self._parent._emitTargetBedTemperatureChanged(x)
                    )

            if line not in [b"", b"ok\n"]:
                self._parent.log("i", line.decode("latin-1").replace("\n", ""))

        self._parent.log("i", "Printer connection listen thread stopped for %s" % self._parent._serial_port)

    ##  Gets the next Gcode in the gcode list
    def _getNextGcodeLine(self,serial_proto):
        self._mutex.acquire();
        gcodeLen  = len(self._gcode)
        line = self._gcode[self._gcode_position]
        self._mutex.release();

        if self._gcode_position >= gcodeLen:
            return

        self._gcode_position += 1

        # Update the progress only every 100 gcode lines to prevent overwhelming things.
        if self._gcode_position % 100 == 0 or self._gcode_position == gcodeLen:
            progress = self._gcode_position / gcodeLen
            if progress > 0:
                elapsed = time.time() - self._print_start_time
                total = elapsed + self._backend_print_time * (1 - progress)
                self._parent.setTimeTotal(total)
                self._parent.setTimeElapsed(elapsed)
                self._parent.setProgress(progress * 100)
                self._parent.progressChanged.emit()
                # Also inform Marlin of the print progress
                if progress == 100:
                    serial_proto.sendCmdUnreliable("M73 P0")
                else:
                    serial_proto.sendCmdUnreliable("M73 P" + str(int(progress * 100)))

        # Don't send the M0 or M1 to the machine, as M0 and M1 are handled as
        # an LCD menu pause.
        if re.match('\s*M[01]\\b', line):
            # Don't send the M0 or M1 to the machine, as M0 and M1 are handled as an LCD menu pause.
            self._parent.log("d", "Encountered M0 or M1, pausing print" )
            self._parent._setJobState("pause")
            line = False

        return line

    class PauseState:
        def __init__(self):
            self.x = None
            self.y = None
            self.z = None
            self.f = None
            self.e = None
            self.retraction = None

    def _findLastPosition(self):
        """Runs backwards through GCODE lines that were already sent until
        the last complete position is determined, return False otherwise"""
        pos = self.PauseState()
        axis_re = re.compile('([XYZEF])(-?[0-9\.]+)')
        self._mutex.acquire()
        for i in range(self._gcode_position - 1, 0, -1):
            line = self._gcode[i].upper()
            if ('G0' in line or 'G1' in line):
                for a, v in re.findall(axis_re, line):
                    if a == 'X' and pos.x is None:
                        pos.x = float(v)
                    if a == 'Y' and pos.y is None:
                        pos.y = float(v)
                    if a == 'Z' and pos.z is None:
                        pos.z = float(v)
                    if a == 'E' and pos.e is None:
                        pos.e = float(v)
                    if a == 'F' and pos.f is None:
                        pos.f = float(v)
                if (pos.x is not None and
                    pos.y is not None and
                    pos.z is not None and
                    pos.f is not None and
                    pos.e is not None):
                    break
        self._mutex.release()
        if pos.x is None or pos.y is None or pos.z is None:
            return None
        return pos

    def pause(self, machine_width, machine_depth, machine_height, retract_amount):
        """Pauses the print in progress, lifting the head, parking and retracting.
           Also used to park the head after a print stops."""
        parkX  = machine_width  - 10
        parkY  = machine_depth  - 10
        maxZ   = machine_height - 10
        raiseZ = 10.0

        # Prior to enqueuing the head motion commands, set
        # _pauseState as this will block the PrintThread.

        pos = self._findLastPosition()
        self._mutex.acquire()
        if pos:
            self._pauseState = pos
            self._pauseState.retraction = retract_amount
        else:
            # Pause with unknown position.
            self._pauseState = True
        self._mutex.release()

        if retract_amount > 0:
            # Set E relative positioning
            self.sendCommand("M83")

            # Retract the filament
            self.sendCommand("G1 E%f F120" % (-retract_amount))

            # Set E absolute positioning
            self.sendCommand("M82")

        # Move the toolhead up, if position is known
        if pos:
            parkZ = max(min(pos.z + raiseZ, maxZ), pos.z)
            self.sendCommand("G1 Z%f F3000" % parkZ)

        # Move the head away
        self.sendCommand("G1 X%f Y%f F9000" % (parkX, parkY))

        # Disable the E steppers
        self.sendCommand("M18 E")

        # Pause print job timer
        self.sendCommand("M76")

    def resume(self):
        """Resumes a print that was paused"""
        if isinstance(self._pauseState, self.PauseState):
            pos = self._pauseState
            if pos.f is None:
                pos.f = 1200
            if pos.e is None:
                pos.e = 0

            if pos.retraction > 0:
                # Set E relative positioning
                self.sendCommand("M83")
                # Prime the nozzle when changing filament
                self.sendCommand("G1 E%f F120" %  pos.retraction)  # Push the filament out
                self.sendCommand("G1 E%f F120" % -pos.retraction)  # retract again
                # Prime the nozzle again
                self.sendCommand("G1 E%f F120" %  pos.retraction)
                # Set E absolute positioning
                self.sendCommand("M82")
                # Set E absolute position to cancel out any extrude/retract that occured
                self.sendCommand("G92 E%f" % pos.e)

            # Set proper feedrate
            self.sendCommand("G1 F%f" % pos.f)
            # Re-home the nozzle
            self.sendCommand("G28 X0 Y0")
            # Position the toolhead to the correct position and feedrate again
            self.sendCommand("G1 X%f Y%f Z%f F%f" % (pos.x, pos.y, pos.z, pos.f))
            # Reset filament runout sensor
            self.sendCommand("M412 R1")
            # Restart print job timer
            self.sendCommand("M75")
            self._parent.log("d", "Print resumed")

            # Release the PrintThread.
            self._mutex.acquire()
            self._pauseState = None
            self._mutex.release()
