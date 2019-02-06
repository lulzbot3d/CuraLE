"""
"""
import struct

from .wordcopy_applet import WordCopyApplet
from . import bossa_chip_db
from UM.Logger import Logger



class EEFC_Flash():
    def __init__(self, samba, chip):
        self.samba = samba
        self.chip = chip
        self.wordCopy = WordCopyApplet(samba,chip)

        # Copying init code from Flash class here
        self.wordCopy.setWords(int( self.chip["size"] / 4) )
        self.wordCopy.setStack(self.chip["stack"])

        self.onBufferA = True
        # page buffers will have the size of a physical page and will be situated right after the applet
        self.pageBufferA = self.chip["user"] + 0x1000
        self.pageBufferB = self.pageBufferA + self.chip["size"]

        # SAM3 Errata (FWS must be 6)
        self.samba.writeWord(self.chip["regs"] + 0x000, 0x600)
        if (self.chip["planes"] == 2):
            self.samba.writeWord(self.chip["regs"] + 0x200, 0x600)

    def setLockRegion(self, region, enable):
        if region >= self.chip["lockRegions"]:
            raise Exception("RegionError")

        if enable != self.getLockRegion(region):
            if (self.chip["planes"] == 2)and(region >= self.chip["lockRegions"]/2):
                page = (region - self.chip["lockRegions"] / 2) * self.chip["pages"] / self.chip["lockRegions"]
                self.waitFSR()
                if enable:
                    self.writeFCR1(0x8, page)
                else:
                    self.writeFCR1(0x9, page)
            else:
                page = region * self.chip["pages"] / self.chip["lockRegions"]
                self.waitFSR()
                if enable:
                    self.writeFCR0(0x8, page)
                else:
                    self.writeFCR0(0x9, page)

    
    def writePage(self, page):
        if page > self.chip["pages"]:
            raise Exception("FlashPageError")


    def readPage(self, page):
        if page > self.chip["pages"]:
            raise Exception("FlashPageError")
        # The SAM3 firmware has a bug where it returns all zeros for reads
        # directly from the flash so instead, we copy the flash page to
        # SRAM and read it from there.
        if self.onBufferA:
            self.wordCopy.setDstAddr(self.pageBufferA)
        else:
            self.wordCopy.setDstAddr(self.pageBufferB)
        self.wordCopy.setSrcAddr(self.chip["addr"] + page * self.chip["size"])
        self.waitFSR()
        self.wordCopy.runv()

        # _samba.read(_onBufferA ? _pageBufferA : _pageBufferB, data, _size);

    def waitFSR(self):
        tries = 0
        fsr1 = 0x1
        while tries <= 500:
            tries = tries + 1
            fsr0 = self.samba.readWord(self.chip["regs"] + 0x008)
            if fsr0 & (1 << 2):
                raise Exception("FlashLockError")

            if self.chip["planes"] == 2:
                fsr1 = self.samba.readWord(self.chip["regs"] + 0x208)
                if fsr1 & (1 << 2):
                    raise Exception("FlashLockError")
            if fsr0 & fsr1 & 0x1:
                break
            time.sleep(0.0001)
        if tries > 500:
            raise Exception("FlashCmdError")

    def writeFCR0(self, cmd, arg):
        self.samba.writeWord(self.chip["regs"] + 0x004, (0x5a << 24) | (arg << 8) | cmd )

    def writeFCR1(self, cmd, arg):
        self.samba.writeWord(self.chip["regs"] + 0x204, (0x5a << 24) | (arg << 8) | cmd )

    def readFRR0(self):
        return self.samba.readWord(self.chip["regs"] + 0x00C)

    def readFRR1(self):
        return self.samba.readWord(self.chip["regs"] + 0x20C)
