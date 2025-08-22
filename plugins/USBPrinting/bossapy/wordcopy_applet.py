"""
"""
import struct

from . import bossa_chip_db
from UM.Logger import Logger

class WordCopyApplet():
    def __init__(self, samba, chip):
        self.samba = samba
        self.chip = chip

        self.dst_addr = 0x00000028
        self.reset = 0x00000024
        self.src_addr = 0x0000002c
        self.stack = 0x00000020
        self.start = 0x00000000
        self.words = 0x00000030
        self.code = bytearray([
            0x09, 0x48, 0x0a, 0x49, 0x0a, 0x4a, 0x02, 0xe0, 0x08, 0xc9, 0x08, 0xc0, 0x01, 0x3a, 0x00, 0x2a,
            0xfa, 0xd1, 0x04, 0x48, 0x00, 0x28, 0x01, 0xd1, 0x01, 0x48, 0x85, 0x46, 0x70, 0x47, 0xc0, 0x46,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00])

        self.samba.write(self.chip["user"], self.code)


    def setDstAddr(self, dstAddr):
        self.samba.writeWord(self.chip["user"] + self.dst_addr, dstAddr)

    def setSrcAddr(self, srcAddr):
        self.samba.writeWord(self.chip["user"] + self.src_addr, srcAddr)

    def setWords(self, words):
        self.samba.writeWord(self.chip["user"] + self.words, words)

    def setStack(self, stack):
        self.samba.writeWord(self.chip["user"] + self.stack, stack)

    def run(self):
        # Add one to the start address for Thumb mode
        self.samba.go(self.chip["user"] + self.start + 1)

    def runv(self):
        # Add one to the start address for Thumb mode
        self.samba.writeWord( self.chip["user"] + self.reset, self.chip["user"] + self.start + 1)
        # The stack is the first reset vector
        self.samba.go(self.chip["user"] + self.stack)
