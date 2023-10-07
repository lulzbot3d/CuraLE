# Copyright (c) 2023 Fargo Additive Manufacturing Equipment 3D, LLC
# Cura LE is released under the terms of the LGPLv3 or higher.

from UM.Job import Job
from UM.Logger import Logger

from .avr_isp import ispBase
from .avr_isp.stk500v2 import Stk500v2

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
        wait_response_timeouts = [5, 15, 30]
        wait_bootloader_times = [5, 10, 15]
        write_timeout = 3
        read_timeout = 3
        tries = 2
        serial = None

        for retry in range(tries):
            if retry < len(wait_response_timeouts):
                wait_response_timeout = wait_response_timeouts[retry]
            else:
                wait_response_timeout = wait_response_timeouts[-1]
            if retry < len(wait_bootloader_times):
                wait_bootloader = wait_bootloader_times[retry]
            else:
                wait_bootloader = wait_bootloader_times[-1]

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
            sleep(wait_bootloader)  # Ensure that we are not talking to the boot loader. 1.5 seconds seems to be the magic number

            serial.write(b"\n")  # Ensure we clear out previous responses
            serial.write(b"M105\n")

            start_timeout_time = time()
            timeout_time = time() + wait_response_timeout

            while timeout_time > time():
                # If baudrate is wrong, then readline() might never
                # return, even with timeouts set. Using read_until
                # with size limit seems to fix this.
                line = serial.read_until(size = 100)
                if b"ok" in line and b"T:" in line:
                    self.setResult(serial)
                    Logger.log("d", "Created serial connection on port {port} on retry {retry} after {time_elapsed:0.2f} seconds.".format(
                        port = self._serial_port, retry = retry, time_elapsed = time() - start_timeout_time))
                    return
                serial.write(b"M105\n")

            sleep(10)  # Give the printer some time to init and try again.
        self.setResult(None)  # Unable to detect the correct baudrate.