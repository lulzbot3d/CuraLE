"""
Database of the chips used by BOSCAPY.
"""
bossa_chip_db = {
    #
    # SAMD21
    #
    "ATSAMD21J18A": {
        "chip_id": 0x10010000,
        "flash_type": "nvm",
        "addr": 0x00002000,
        "pages": 4096,
        "size": 64,
        "planes": 1,
        "lockRegions": 16,
        "user": 0x20004000,
        "stack": 0x20008000,
        "regs": 0x41004000,
        "canBrownout": True,
    },
    #
    # SAM7SE
    #

    #
    # SAM7S
    #

    #
    # SAM7XC
    #

    #
    # SAM7X
    #
    "AT91SAMX512": {
        "chip_id": 0x275c0a40,
        "flash_type": "efc",
        "addr": 0x100000,
        "pages": 2048,
        "size": 256,
        "planes": 2,
        "lockRegions" : 32,
        "user": 0x202000,
        "stack": 0x220000,
        "canBootFlash": True,
    },
    "AT91SAMX256": {
        "chip_id": 0x275b0940,
        "flash_type": "efc",
        "addr": 0x100000,
        "pages": 1024,
        "size": 256,
        "planes": 1,
        "lockRegions" : 16,
        "user": 0x202000,
        "stack": 0x210000,
        "canBootFlash": True,
    },
    "AT91SAMX128": {
        "chip_id": 0x275a0740,
        "flash_type": "efc",
        "addr": 0x100000,
        "pages": 512 ,
        "size": 256,
        "planes": 1,
        "lockRegions" : 8,
        "user": 0x202000,
        "stack": 0x208000,
        "canBootFlash": True,
    },

    #
    # SAM4S
    #

    #
    # SAM3N
    #

    #
    # SAM3S
    #

    #
    # SAM3U
    #

    #
    # SAM3X
    #
    "ATSAM3X8E": {
        "chip_id": 0x285e0a60,
        "flash_type": "eefc",
        "addr": 0x00080000,
        "pages": 2048,
        "size": 256,
        "planes": 2,
        "lockRegions" : 32,
        "user": 0x20001000,
        "stack": 0x20010000,
        "regs": 0x400e0a00,
        "canBrownout": False,
    },

    #
    # SAM3A
    #

    #
    # SAM7L
    #

    #
    # SAM9XE
    #
    "ATSAM9XE512": {
        "chip_id": 0x329aa3a0,
        "flash_type": "eefc",
        "addr": 0x200000,
        "pages": 1024,
        "size": 512,
        "planes": 1,
        "lockRegions" : 32,
        "user": 0x300000,
        "stack": 0x307000,
        "regs": 0xfffffa00,
        "canBrownout": True,
    },
    "ATSAM9XE256": {
        "chip_id": 0x329a93a0,
        "flash_type": "eefc",
        "addr": 0x200000,
        "pages": 512,
        "size": 512,
        "planes": 1,
        "lockRegions" : 16,
        "user": 0x300000,
        "stack": 0x307000,
        "regs": 0xfffffa00,
        "canBrownout": True,
    },
    "ATSAM9XE128": {
        "chip_id": 0x329973a0,
        "flash_type": "eefc",
        "addr": 0x200000,
        "pages": 256,
        "size": 512,
        "planes": 1,
        "lockRegions" : 8,
        "user": 0x300000,
        "stack": 0x303000,
        "regs": 0xfffffa00,
        "canBrownout": True,
    },
}

def getChipFromDB( chip_id):
    for chip in bossa_chip_db.values():
        if chip["chip_id"] == chip_id:
            return chip
    return False
