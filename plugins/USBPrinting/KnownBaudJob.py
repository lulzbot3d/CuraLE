# Copyright (c) 2023 Fargo Additive Manufacturing Equipment 3D, LLC
# Cura LE is released under the terms of the LGPLv3 or higher.

from UM.Job import Job
from UM.Logger import Logger

from time import time, sleep
from serial import Serial, SerialException


#   An async job that attempts to connect to a USB printer with a known baud rate.
#   It tries a pre-set list of baud rates. All these baud rates are validated by requesting the temperature a few times
#   and checking if the results make sense. If getResult() is not None, it was able to find a correct baud rate.
class KnownBaudJob(Job):
    def __init__(self, serial_port: int, baud_rate: int) -> None:
        super().__init__()
        self._serial_port = serial_port
        self._baud_rate = baud_rate

    def run(self) -> None:
        Logger.log("d", "Known Baud Connection Job started.")
        wait_response_timeouts = [3, 5]
        wait_bootloader_times = [1.5]
        write_timeout = 3
        read_timeout = 3
        tries = 2
        serial = None

        for retry in range(tries):
            if retry != 0:
                Logger.log("d", "Waiting for retry...")
                sleep(5)  # Give the printer some time to init and try again.
            if retry < len(wait_response_timeouts):
                wait_response_timeout = wait_response_timeouts[retry]
            else:
                wait_response_timeout = wait_response_timeouts[-1]
            if retry < len(wait_bootloader_times):
                wait_bootloader = wait_bootloader_times[retry]
            else:
                wait_bootloader = wait_bootloader_times[-1]
            Logger.log("d", "Serial creation attempt: {0}.".format(retry + 1))

            if serial is None:
                try:
                    serial = Serial(str(self._serial_port), str(self._baud_rate), timeout = read_timeout, writeTimeout = write_timeout)
                except SerialException:
                    if retry == tries - 1:
                        Logger.logException("w", "Unable to create serial")
                        Logger.log("w", "Attempting AutoDetect for Baud Rate...")
                    else:
                        Logger.log("w", "Serial creation failed, printer may be busy... retrying in 10 seconds")
                        sleep(10)
                    continue
            Logger.log("d", "Serial created, waiting {0} seconds for bootloading sequence.".format(wait_bootloader))
            sleep(wait_bootloader)  # Ensure that we are not talking to the boot loader.

            try:
                serial.write(b"\n")  # Ensure we clear out previous responses
                serial.write(b"M105\n")
            except SerialException:
                Logger.log("w", "Encountered SerialException while trying to write!")
                continue
            Logger.log("d", "Attempting an M105 command...")
            Logger.log("d", "Wait timout: {0}.".format(wait_response_timeout))


            start_timeout_time = time()
            resend_m105_time = time() + 1
            duplicate_lines = 0
            timeout_time = time() + wait_response_timeout
            previous_line = None

            while timeout_time > time():
                # If baudrate is wrong, then readline() might never
                # return, even with timeouts set. Using read_until
                # with size limit seems to fix this.
                try:
                    line = serial.read_until(size = 100)
                    if line == previous_line:
                        duplicate_lines += 1
                    else: duplicate_lines = 0
                    previous_line = line
                except SerialException:
                    Logger.log("w", "Encountered an exception attempting to read from serial!")
                    break
                if b"start" in line:
                    Logger.log("d", "Recieving boot sequence output, continue waiting for response...")
                    timeout_time = time() + wait_response_timeout
                if b"echo" in line:
                    # Don't spam the logs but just keep the connection going for now
                    timeout_time = time() + wait_response_timeout
                if b"ok" in line and b"T:" in line:
                    Logger.log("d", "M105 returned!")
                    self.setResult(serial)
                    Logger.log("d", "Created serial connection on port {port} on retry {retry} after {time_elapsed:0.2f} seconds.".format(
                        port = self._serial_port, retry = retry, time_elapsed = time() - start_timeout_time))
                    return
                if resend_m105_time > time() and duplicate_lines > 3:
                    try:
                        Logger.log("d", "No new output for a while, trying an M105 again.")
                        serial.write(b"M105\n")
                        resend_m105_time = time() + 1
                    except SerialException:
                        Logger.log("w", "Serial Exception during repeated M105 writes.")
                        break
            Logger.log("d", "Printer response timeout.")

        self.setResult(None)  # Unable to detect the correct baudrate.
