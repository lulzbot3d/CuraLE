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

        Logger.log("d", "...Set binary mode")
        self.serial.write(b'N#')
        self.serial.flush()
        self.serial.read(2) #Expects b'\n\r' here

        cid = self.chipId()
        Logger.log("d", "...ChipID = " + hex(cid))
        
        # Read the sam-ba version to detect if extended commands are available
        # NOTE: we MUST call version() after chipId(), otherwise sam-ba did not
        # answer correctly on some devices when used from UART.
        # The reason is unknown.
        ver = self.version()
        Logger.log("d", "...SAM-BA version = [" + ver +"]")

        eproc = (cid >> 5) & 0x7
        arch = (cid >> 20) & 0xff

        # Check for ARM7TDMI processor
        if (eproc == 2):
            # Check for SAM7 architecture
            if (arch >= 0x70 and arch <= 0x76):
                return
            Logger.log("d", "...Unsupported ARM7TDMI architecture")
        # Check for Cortex-M3 processor
        elif (eproc == 3):
            # Check for SAM3 architecture
            if (arch >= 0x80 and arch <= 0x8a):
                return
            if (arch >= 0x93 and arch <= 0x9a):
                return
            Logger.log("d", "...Unsupported Cortex-M3 architecture")
        # Check for Cortex-M4 processor
        elif (eproc == 7):
            # Check for SAM4 architecture
            if (arch >= 0x88 and arch <= 0x8a):
                return
            Logger.log("d", "...Unsupported Cortex-M4 architecture")
        # Check for ARM920T processor
        elif (eproc == 4):
            # Check for SAM9XE architecture
            if (arch == 0x29):
                return
            Logger.log("d", "...Unsupported ARM920T architecture")
        # Check for supported M0+ processor
        # NOTE: 0x1001000a is a ATSAMD21E18A, 0x1001001c is ATSAMR21E18A
        elif (cid == 0x10010000 or cid == 0x10010100 or cid == 0x10010005 or cid == 0x1001000a or cid == 0x1001001c):
            return
        else:
            Logger.log("d", "...Unsupported processor")

        self.close()
        raise Exception("Unsupported processor or architecture")


    def version(self):
        version_string=""
        self.serial.write(b'V#')
        self.serial.flush()
        while True:
            s = self.serial.read(1)
            if len(s) < 1:
                raise Exception("version read failed")
            if (s == b'\r'):
                return version_string.rstrip()
            version_string += s.decode()


    def chipId(self):
        #Read the ARM reset vector
        vector = self.readWord(0x0)

        if ((vector & 0xff000000) == 0xea000000):
            return self.readWord(0xfffff240)
        # Else use the Atmel SAM3 or SAM4 or SAMD registers
        
        # The M0+, M3 and M4 have the CPUID register at a common addresss 0xe000ed00
        cpuid_reg = self.readWord(0xe000ed00)
        part_no = cpuid_reg & 0x0000fff0

        # Check if it is Cortex M0+
        if (part_no == 0xC600):
            return self.readWord(0x41002018) & 0xFFFF00FF
        # Else assume M3 or M4
        cid = self.readWord(0x400e0740)
        if (cid == 0x0):
            cid = self.readWord(0x400e0940)

        return cid

    def flash_firmware(self, firmware_file_name):
        return

 
    def close(self):
        if self.serial is not None:
            self.serial.close()
            self.serial = None

    def isConnected(self):
        return self.serial is not None

    def readWord(self, address):
        cmd = str.encode("w" + str('%0*x' % (8,address)) + ",4#")
        try:
            self.serial.write(cmd)
            self.serial.flush()
        except SerialTimeoutException:
            raise Exception("readWord failed")
        s = self.serial.read(4)
        if len(s) < 1:
            raise Exception("readWord timeout")
        value = struct.unpack("<L", s)[0]
        Logger.log("d", "...Read from addr=" + hex(address) + "[" + hex(value)+ "]")
        return value

    def writeWord(self, address, value):
        cmd = str.encode("W" + str('%0*x' % (8,address)) + "," + str('%0*x' % (8,value))  + "#")
        try:
            self.serial.write(cmd)
            self.serial.flush()
        except SerialTimeoutException:
            raise Exception("writeWord failed")
        Logger.log("d", "...Write to addr=" + hex(address) + "[" + hex(value)+ "]")
