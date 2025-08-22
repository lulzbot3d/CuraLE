"""
"""
import struct
import time

from serial import SerialTimeoutException

from . import bossa_chip_db
# from UM.Logger import Logger

class Samba():
    def __init__(self,serial):
        self.serial = serial

    def SetBinary(self):
        # Logger.log("d", "...Set binary mode")
        self.serial.write(b'N#')
        self.serial.flush()
        self.serial.read(2) #Expects b'\n\r' here


    def write(self, addr, data):
        cmd = str.encode("S" + str('%0*x' % (8,addr)) + "," + str('%0*x' % (8,len(data)))  + "#")
        try:
            self.serial.write(cmd)
            self.serial.flush()
        except SerialTimeoutException:
            raise Exception("write failed")

        try:
            size = self.serial.write(data)
            self.serial.flush()
        except SerialTimeoutException:
            raise Exception("write failed")

        # Logger.log("d", "...Write to addr=" + hex(addr) + " of " + str(size) + " bytes")

    def go(self, addr):
        cmd = str.encode("G" + str('%0*x' % (8,addr)) + "#")
        try:
            self.serial.write(cmd)
            self.serial.flush()
        except SerialTimeoutException:
            raise Exception("write failed")
        # Logger.log("d", "...Go to addr=" + hex(addr) )

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

    def reset(self):
        chip_id = self.chipId()
        if chip_id == 0x285e0a60:
            self.writeWord(0x400E1A00, 0xA500000D)
        # else:
        #    Logger.log("d", "...Reset is not supported for this CPU")
        # Some linux users experienced a lock up if the serial
        # port is closed while the port itself is being destroyed.
        # This delay is here to give the time to kernel driver to
        # sort out things before closing the port.
        time.sleep(0.1)

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
        # Logger.log("d", "...Read from addr=" + hex(address) + "[" + hex(value)+ "]")
        return value

    def writeWord(self, address, value):
        cmd = str.encode("W" + str('%0*x' % (8,address)) + "," + str('%0*x' % (8,value))  + "#")
        try:
            self.serial.write(cmd)
            self.serial.flush()
        except SerialTimeoutException:
            raise Exception("writeWord failed")
        # Logger.log("d", "...Write to addr=" + hex(address) + "[" + hex(value)+ "]")

