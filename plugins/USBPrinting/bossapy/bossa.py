"""
BOSSAPY is python3 rewrite of https://github.com/shumatech/BOSSA :
BOSSA is a flash programming utility for Atmel's SAM family of flash-based ARM microcontrollers. The motivation behind BOSSA is to create a simple, easy-to-use, open source utility to replace Atmel's SAM-BA software. BOSSA is an acronym for Basic Open Source SAM-BA Application to reflect that goal.
"""
import struct
import sys
import time

from serial import Serial   # type: ignore
from serial import SerialException
from serial import SerialTimeoutException
from UM.Logger import Logger


class BOSSA():
    def __init__(self):
        self.serial = None
        self.seq = 1
        self.last_addr = -1
        self.progress_callback = None

    def connect(self, port = "COM22", speed = 115200):
        if self.serial is not None:
            self.close()
        try:
            self.serial = Serial(str(port), speed, timeout=1, writeTimeout=10000)
        except SerialException:
            raise ispBase.IspError("Failed to open serial port")
        except:
            raise ispBase.IspError("Unexpected error while connecting to serial port:" + port + ":" + str(sys.exc_info()[0]))
        self.seq = 1

        #Reset the controller
        for n in range(0, 2):
            self.serial.setDTR(True)
            time.sleep(0.1)
            self.serial.setDTR(False)
            time.sleep(0.1)
        time.sleep(0.2)

        self.serial.flushInput()
        self.serial.flushOutput()

    def flash_firmware(self, firmware_file_name):
        return

 
    def close(self):
        if self.serial is not None:
            self.serial.close()
            self.serial = None

    def isConnected(self):
        return self.serial is not None
