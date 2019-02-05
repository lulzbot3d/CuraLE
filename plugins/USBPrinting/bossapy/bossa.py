"""
BOSSAPY is python3 rewrite of https://github.com/shumatech/BOSSA :
BOSSA is a flash programming utility for Atmel's SAM family of flash-based ARM microcontrollers. The motivation behind BOSSA is to create a simple, easy-to-use, open source utility to replace Atmel's SAM-BA software. BOSSA is an acronym for Basic Open Source SAM-BA Application to reflect that goal.
"""
import sys
import time

from serial import Serial   # type: ignore
from serial import SerialException
from serial import SerialTimeoutException
from UM.Logger import Logger

from .samba import Samba
from .eefc_flash import EEFC_Flash
from . import bossa_chip_db

class BOSSA():
    def __init__(self):
        self.serial = None
        self.chip = False
        self.samba = None
        self.flash = None
        self.seq = 1
        self.last_addr = -1
        self.progress_callback = None

    def connect(self, port = "COM22", speed = 115200):
        if self.serial is not None:
            self.close()


        Logger.log("d", "...Initializing serial with %s", str(port) )
        try:
            self.serial = Serial(str(port), 1200, timeout=1, writeTimeout=10000)
        except SerialException:
            raise Exception("Failed to open serial port")
        except:
            raise Exception("Unexpected error while connecting to serial port:" + port + ":" + str(sys.exc_info()[0]))
        self.seq = 1
        self.serial.setDTR(True)
        time.sleep(0.1)
        self.serial.setDTR(False)
        self.close()

        # After this new serial device should appear within max 2 seconds..
        time.sleep(2.0)
        Logger.log("d", "...Trying to reconnect with bootloader on %s", str(port) )
        try:
            self.serial = Serial(str(port), 921600 , timeout=1, writeTimeout=10000)
        except SerialException:
            raise Exception("Failed to open serial port in bootloader mode")
        except:
            raise Exception("Unexpected error while connecting to serial port:" + port + ":" + str(sys.exc_info()[0]))


        if not self.isConnected():
            raise Exception("Failed to enter BOSSA bootloader")

        self.samba = Samba(self.serial)

        self.samba.SetBinary()
        cid = self.samba.chipId()
        Logger.log("d", "...ChipID = " + hex(cid))
        
        # Read the sam-ba version to detect if extended commands are available
        # NOTE: we MUST call version() after chipId(), otherwise sam-ba did not
        # answer correctly on some devices when used from UART.
        # The reason is unknown.
        ver = self.samba.version()
        Logger.log("d", "...SAM-BA version = [" + ver +"]")

        self.chip = bossa_chip_db.getChipFromDB(cid)
        if not self.chip:
            raise Exception("Chip with signature: " + str(cid) + "not found")

        if self.chip["flash_type"] == "eefc":
            self.flash = EEFC_Flash(self.samba, self.chip)
        else:
            self.flash = None
            raise Exception("Unsupported flash type")


    def flash_firmware(self, firmware_file_name):
        Logger.log("d", "...Flashing firmware from " + str (firmware_file_name) )
        
        return

 
    def close(self):
        if self.serial is not None:
            self.serial.close()
            self.serial = None

    def isConnected(self):
        return self.serial is not None

#---------------------------------------------------------------------------------------#
def runProgrammer(port, filename):
    """ Run a BOSSA program on serial port 'port' and write 'filename' into flash. """
    programmer = BOSSA()
    programmer.connect(port = port)
    programmer.flash_firmware(filename)
    programmer.close()

def main():
    """ Entry point to call the BOSSA programmer from the commandline. """
    import threading
    if sys.argv[1] == "AUTO":
        Logger.log("d", "portList(): ", repr(portList()))
        for port in portList():
            threading.Thread(target=runProgrammer, args=(port,sys.argv[2])).start()
            time.sleep(5)
    else:
        programmer = BOSSA()
        programmer.connect(port = sys.argv[1])
        programmer.flash_firmware(sys.argv[2])
        sys.exit(1)

if __name__ == "__main__":
    main()
