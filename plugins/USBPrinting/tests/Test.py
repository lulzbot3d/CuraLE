import os
import sys
from unittest.mock import MagicMock, Mock
sys.path.append(os.path.realpath(os.path.join(os.path.dirname(os.path.realpath(__file__)), "..", "..")))


class VirtualSerialConnection():
    def write(self, data):
        print("write():", data)

    def readline(self):
        return b"ok T:10"

    def close(self):
        print("close()")


class stk500v2:
    class Stk500v2:
        def connect(self, port="COM2", baudrate=250000):
            print(port, baudrate)

        def close(self):
            print("closed")

        def leaveISP(self):
            return VirtualSerialConnection()

sys.modules["USBPrinting.USBPrinterOutputDeviceManager"] = MagicMock()
sys.modules["USBPrinting.avr_isp.stk500v2"] = stk500v2

from USBPrinting.USBPrinterOutputDevice import USBPrinterOutputDevice
from UM.Application import Application

Application._instance = Mock()

def test_connect():
    p = USBPrinterOutputDevice("test")
    p.connect()
    p._connect_thread.join()
    p._listen_thread.join()
    pass

test_connect()
