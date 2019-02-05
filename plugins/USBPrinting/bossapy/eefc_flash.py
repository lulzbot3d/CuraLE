"""
"""
import struct

from . import bossa_chip_db
from UM.Logger import Logger

class EEFC_Flash():
    def __init__(self, samba, chip):
        self.samba = samba
        self.chip = chip
        # SAM3 Errata (FWS must be 6)
        self.samba.writeWord(self.chip["regs"] + 0x000, 0x600)
        if (self.chip["planes"] == 2):
            self.samba.writeWord(self.chip["regs"] + 0x200, 0x600)

