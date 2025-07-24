"""
"""
import struct
import time

from .wordcopy_applet import WordCopyApplet
from . import bossa_chip_db
from UM.Logger import Logger



class EEFC_Flash():
    def __init__(self, samba, chip):

        self.samba = samba
        self.chip = chip
        self.wordCopy = WordCopyApplet(samba,chip)

        self.eraseAuto

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

    def eraseAll(self):
        self.waitFSR()
        self.writeFCR0(0x5, 0)
        if self.chip["planes"] == 2:
            self.waitFSR()
            self.writeFCR1(0x5, 0)

    def eraseAuto(self, enable):
        self.eraseAuto = enable

    def isLocked(self):
        self.waitFSR()
        self.writeFCR0(0xa, 0)
        self.waitFSR()
        if self.readFRR0():
            return True
        if self.chip["planes"] == 2:
            self.writeFCR1(0xa, 0)
            self.waitFSR()
            if self.readFRR1():
                return True
        return False

    def getLockRegion(self, region):
        if region >= self.chip["lockRegions"]:
            raise Exception("RegionError")

        self.waitFSR()
        if (self.chip["planes"] == 2) and (region >= self.chip["lockRegions"]/2):
            self.writeFCR1(0xa, 0)
            self.waitFSR()
            if self.readFRR1() & (1 << (region - int(self.chip["lockRegions"]/2))):
                return True
        else:
            self.writeFCR0(0xa, 0)
            self.waitFSR()
            if self.readFRR0() & (1 << region):
                return True
        return False


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

    def getSecurity(self):
        self.waitFSR()
        self.writeFCR0(0xd, 0)
        self.waitFSR()
        result = bool(self.readFRR0() & (1 << 0))

    def setSecurity(self):
        self.waitFSR()
        self.writeFCR0(0xb, 0)

    def getBod(self):
        if not self.chip["canBrownout"]:
            return False
        self.waitFSR()
        self.writeFCR0(0xd, 0)
        self.waitFSR()
        result = bool(self.readFRR0() & (1 << 1))
        return result

    def setBod(self, enable):
        if not self.chip["canBrownout"]:
            return
        self.waitFSR()
        if enable:
            self.writeFCR0(0xb, 1)
        else:
            self.writeFCR0(0xc, 1)

    def getBor(self):
        if not self.chip["canBrownout"]:
            return False
        self.waitFSR()
        self.writeFCR0(0xd,0)
        self.waitFSR()
        result = bool(self.readFRR0() & (1 << 2))
        return result

    def setBor(self, enable):
        if not self.chip["canBrownout"]:
            return
        self.waitFSR()
        if enable:
            self.writeFCR0(0xb, 2)
        else:
            self.writeFCR0(0xc, 2)

    def getBootFlash(self):
        self.waitFSR()
        self.writeFCR0(0xd, 0)
        self.waitFSR()
        if self.chip["canBrownout"]:
            result = bool(self.readFRR0() & (1 << 3))
        else:
            result = bool(self.readFRR0() & (1 << 1))
        return result

    def setBootFlash(self, enable):
        self.waitFSR()
        if enable:
            if self.chip["canBrownout"]:
                self.writeFCR0(0xb, 3)
            else:
                self.writeFCR0(0xb, 1)
        else:
            if self.chip["canBrownout"]:
                self.writeFCR0(0xc,3)
            else:
                self.writeFCR0(0xc,1)
        self.waitFSR()
        time.sleep(0.01)
    
    def writePage(self, page):
        if page > self.chip["pages"]:
            raise Exception("FlashPageError")
        self.wordCopy.setDstAddr(self.chip["addr"] + page * self.chip["size"])
        if self.onBufferA:
            self.wordCopy.setSrcAddr(self.pageBufferA)
        else:
            self.wordCopy.setSrcAddr(self.pageBufferB)
        self.onBufferA = not self.onBufferA
        self.waitFSR()
        self.wordCopy.runv()
        if (self.chip["planes"] == 2) and (page >= int( self.chip["pages"] / 2 )):
            if (self.eraseAuto):
                self.writeFCR1(0x3, page - int(self.chip["pages"] / 2))
            else:
                self.writeFCR1(0x1, page - int(self.chip["pages"] / 2))
        else:
            if (self.eraseAuto):
                self.writeFCR0(0x3, page)
            else:
                self.writeFCR0(0x1, page)

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
        if self.onBufferA:
            data = self.samba.read(self.pageBufferA, self.chip["size"])
        else:
            data = self.samba.read(self.pageBufferB, self.chip["size"])

        return data


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
        self.samba.writeWord(self.chip["regs"] + 0x004, (0x5a << 24) | (int(arg) << 8) | cmd )

    def writeFCR1(self, cmd, arg):
        self.samba.writeWord(self.chip["regs"] + 0x204, (0x5a << 24) | (int(arg) << 8) | cmd )

    def readFRR0(self):
        return self.samba.readWord(self.chip["regs"] + 0x00C)

    def readFRR1(self):
        return self.samba.readWord(self.chip["regs"] + 0x20C)

    #------------ Adding Functions common to Flash class here for now -------------#
    def lockAll(self):
        for region in range(0, self.chip["lockRegions"]):
            self.setLockRegion(region, True)

    def unlockAll(self):
        for region in range(0, self.chip["lockRegions"]):
            self.setLockRegion(region, False)

    def loadBuffer(self, data):
        if self.onBufferA:
            self.samba.write(self.pageBufferA, data)
        else:
            self.samba.write(self.pageBufferB, data)

    def writeBuffer(self, dst_addr, size):
        if self.onBufferA:
            self.samba.writeBuffer(self.pageBufferA, dst_addr + self.chip["addr"], size)
        else:
            self.samba.writeBuffer(self.pageBufferB, dst_addr + self.chip["addr"], size)

    def checksumBuffer(self, start_addr, size):
        return self.samba.checksumBuffer(start_addr + self.chip["addr"], size)

    def pageSize(self):
        return self.chip["size"]

    def numPages(self):
        return self.chip["pages"]

