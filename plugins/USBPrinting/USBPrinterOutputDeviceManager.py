# Copyright (c) 2017 Ultimaker B.V.
# Cura is released under the terms of the LGPLv3 or higher.

from UM.Signal import Signal, signalemitter
from .USBPrinterOutputDevice import USBPrinterOutputDevice
from UM.Application import Application
from UM.Resources import Resources
from UM.Logger import Logger
from UM.PluginRegistry import PluginRegistry
from UM.OutputDevice.OutputDevicePlugin import OutputDevicePlugin
from cura.PrinterOutputDevice import ConnectionState
from UM.Qt.ListModel import ListModel
from UM.Message import Message

from cura.CuraApplication import CuraApplication

import threading
import platform
import time
import os.path
import serial.tools.list_ports
from UM.Extension import Extension

from PyQt5.QtCore import QUrl, QObject, pyqtSlot, pyqtProperty, pyqtSignal, Qt
from UM.i18n import i18nCatalog
i18n_catalog = i18nCatalog("cura")


##  Manager class that ensures that a usbPrinteroutput device is created for every connected USB printer.
@signalemitter
class USBPrinterOutputDeviceManager(QObject, OutputDevicePlugin, Extension):
    def __init__(self, parent = None):
        super().__init__(parent = parent)
        self._serial_port_list = []
        self._usb_output_devices = {}
        self._usb_output_devices_model = None
        self._update_thread = threading.Thread(target = self._updateThread)
        self._update_thread.setDaemon(True)

        self._check_updates = True
        self._firmware_view = None

        Application.getInstance().applicationShuttingDown.connect(self.stop)
        self.addUSBOutputDeviceSignal.connect(self.addOutputDevice) #Because the model needs to be created in the same thread as the QMLEngine, we use a signal.

    addUSBOutputDeviceSignal = Signal()
    connectionStateChanged = pyqtSignal()

    progressChanged = pyqtSignal()
    firmwareUpdateChange = pyqtSignal()

    @pyqtProperty(float, notify = progressChanged)
    def progress(self):
        progress = 0
        for printer_name, device in self._usb_output_devices.items(): # TODO: @UnusedVariable "printer_name"
            progress += device.progress
        if len(self._usb_output_devices) > 0:
            return progress / len(self._usb_output_devices)
        else:
            return progress

    @pyqtProperty(int, notify = progressChanged)
    def errorCode(self):
        for printer_name, device in self._usb_output_devices.items(): # TODO: @UnusedVariable "printer_name"
            if device._error_code:
                return device._error_code
        return 0

    ##  Return True if all printers finished firmware update
    @pyqtProperty(float, notify = firmwareUpdateChange)
    def firmwareUpdateCompleteStatus(self):
        complete = True
        for printer_name, device in self._usb_output_devices.items(): # TODO: @UnusedVariable "printer_name"
            if not device.firmwareUpdateFinished:
                complete = False
        return complete

    def start(self):
        self._check_updates = True
        self._update_thread.start()

    def stop(self):
        self._check_updates = False

    def _updateThread(self):
        while self._check_updates:
            result = self.getSerialPortList(only_list_usb = True)
            self._addRemovePorts(result)
            time.sleep(5)

    ##  Show firmware interface.
    #   This will create the view if its not already created.
    def spawnFirmwareInterface(self, serial_port):
        if self._firmware_view is None:
            path = os.path.join(PluginRegistry.getInstance().getPluginPath("USBPrinting"), "FirmwareUpdateWindow.qml")
            self._firmware_view = Application.getInstance().createQmlComponent(path, {"manager": self})

        self._firmware_view.show()

    @pyqtSlot(str, bool)
    def updateAllFirmware(self, file_name, update_eeprom):
        if file_name.startswith("file://"):
            file_name = QUrl(file_name).toLocalFile()  # File dialogs prepend the path with file://, which we don't need / want

        if not self._usb_output_devices:
            Message(i18n_catalog.i18nc("@info", "Unable to update firmware because there are no printers connected."), title = i18n_catalog.i18nc("@info:title", "Warning")).show()
            return

        for printer_connection in self._usb_output_devices:
            self._usb_output_devices[printer_connection].resetFirmwareUpdate()
        self.spawnFirmwareInterface("")
        for printer_connection in self._usb_output_devices:
            try:
                self._usb_output_devices[printer_connection].updateFirmware(file_name, update_eeprom)
            except FileNotFoundError:
                # Should only happen in dev environments where the resources/firmware folder is absent.
                self._usb_output_devices[printer_connection].setProgress(100, 100)
                Logger.log("w", "No firmware found for printer %s called '%s'", printer_connection, file_name)
                Message(i18n_catalog.i18nc("@info",
                    "Could not find firmware required for the printer at %s.") % printer_connection, title = i18n_catalog.i18nc("@info:title", "Printer Firmware")).show()
                self._firmware_view.close()

                continue

    @pyqtSlot(str, str, result = bool)
    def updateFirmwareBySerial(self, serial_port, file_name):
        if serial_port in self._usb_output_devices:
            self.spawnFirmwareInterface(self._usb_output_devices[serial_port].getSerialPort())
            try:
                self._usb_output_devices[serial_port].updateFirmware(file_name)
            except FileNotFoundError:
                self._firmware_view.close()
                Logger.log("e", "Could not find firmware required for this machine called '%s'", file_name)
                return False
            return True
        return False

    ##  Return the singleton instance of the USBPrinterManager
    @classmethod
    def getInstance(cls, engine = None, script_engine = None):
        # Note: Explicit use of class name to prevent issues with inheritance.
        if USBPrinterOutputDeviceManager._instance is None:
            USBPrinterOutputDeviceManager._instance = cls()

        return USBPrinterOutputDeviceManager._instance

    @pyqtSlot(result = str)
    def getDefaultFirmwareName(self):
        # Check if there is a valid global container stack
        global_container_stack = Application.getInstance().getGlobalContainerStack()
        if not global_container_stack:
            Logger.log("e", "There is no global container stack. Can not update firmware.")
            self._firmware_view.close()
            return ""

        # The bottom of the containerstack is the machine definition
        machine_id = global_container_stack.getBottom().id

        machine_has_heated_bed = global_container_stack.getProperty("machine_heated_bed", "value")

        if platform.system() == "Linux":
            baudrate = 115200
        else:
            baudrate = 250000

        # NOTE: The keyword used here is the id of the machine. You can find the id of your machine in the *.json file, eg.
        # https://github.com/Ultimaker/Cura/blob/master/resources/machines/ultimaker_original.json#L2
        # The *.hex files are stored at a seperate repository:
        # https://github.com/Ultimaker/cura-binary-data/tree/master/cura/resources/firmware
        machine_without_extras  = {"bq_witbox"                : "MarlinWitbox.hex",
                                   "bq_hephestos_2"           : "MarlinHephestos2.hex",
                                   "ultimaker_original"       : "MarlinUltimaker-{baudrate}.hex",
                                   "ultimaker_original_plus"  : "MarlinUltimaker-UMOP-{baudrate}.hex",
                                   "ultimaker_original_dual"  : "MarlinUltimaker-{baudrate}-dual.hex",
                                   "ultimaker2"               : "MarlinUltimaker2.hex",
                                   "ultimaker2_go"            : "MarlinUltimaker2go.hex",
                                   "ultimaker2_plus"          : "MarlinUltimaker2plus.hex",
                                   "ultimaker2_extended"      : "MarlinUltimaker2extended.hex",
                                   "ultimaker2_extended_plus" : "MarlinUltimaker2extended-plus.hex",
                                   }
        machine_with_heated_bed = {"ultimaker_original"       : "MarlinUltimaker-HBK-{baudrate}.hex",
                                   "ultimaker_original_dual"  : "MarlinUltimaker-HBK-{baudrate}-dual.hex",
                                   }
        lulzbot_machines = {
            "lulzbot_mini":                             "Marlin_Mini_SingleExtruder_1.1.9.34_5f9c029d1.hex",
            "lulzbot_mini_flexy":                         "Marlin_Mini_Flexystruder_1.1.9.34_5f9c029d1.hex",
            "lulzbot_mini_aerostruder":                    "Marlin_Mini_Aerostruder_1.1.9.34_5f9c029d1.hex",
            "lulzbot_mini_achemon":                         "Marlin_Mini_SmallLayer_1.1.9.34_5f9c029d1.hex",
            "lulzbot_mini_banded_tiger":                 "Marlin_Mini_HardenedSteel_1.1.9.34_5f9c029d1.hex",
            "lulzbot_mini_dingy_cutworm":            "Marlin_Mini_HardenedSteelPlus_1.1.9.34_5f9c029d1.hex",
            "lulzbot_mini_cecropia":              "Marlin_Mini_SingleExtruderAeroV2_1.1.9.34_5f9c029d1.hex",
            "lulzbot_mini_lutefisk":              "Marlin_Mini_M175_2.0.0.144.1_8c651988.hex",

            "lulzbot_taz5":                             "Marlin_TAZ5_SingleExtruder_1.1.9.34_5f9c029d1.hex",
            "lulzbot_taz5_flexy_v2":                      "Marlin_TAZ5_Flexystruder_1.1.9.34_5f9c029d1.hex",
            "lulzbot_taz5_moarstruder":                    "Marlin_TAZ5_Moarstruder_1.1.9.34_5f9c029d1.hex",
            "lulzbot_taz5_dual_v2":                     "Marlin_TAZ5_DualExtruderV2_1.1.9.34_5f9c029d1.hex",
            "lulzbot_taz5_flexy_dually_v2":                "Marlin_TAZ5_FlexyDually_1.1.9.34_5f9c029d1.hex",
            "lulzbot_taz5_dual_v3":                     "Marlin_TAZ5_DualExtruderV3_1.1.9.34_5f9c029d1.hex",
            "lulzbot_taz5_aerostruder":                    "Marlin_TAZ5_Aerostruder_1.1.9.34_5f9c029d1.hex",
            "lulzbot_taz5_achemon":                         "Marlin_TAZ5_SmallLayer_1.1.9.34_5f9c029d1.hex",
            "lulzbot_taz5_banded_tiger":                 "Marlin_TAZ5_HardenedSteel_1.1.9.34_5f9c029d1.hex",
            "lulzbot_taz5_dingy_cutworm":            "Marlin_TAZ5_HardenedSteelPlus_1.1.9.34_5f9c029d1.hex",
            "lulzbot_taz5_cecropia":              "Marlin_TAZ5_SingleExtruderAeroV2_1.1.9.34_5f9c029d1.hex",
            "lulzbot_taz5_lutefisk":              "lulzbot_taz5_lutefisk.hex",

            "lulzbot_taz6_flexy_v2":                      "Marlin_TAZ6_Flexystruder_1.1.9.34_5f9c029d1.hex",
            "lulzbot_taz6_moarstruder":                    "Marlin_TAZ6_Moarstruder_1.1.9.34_5f9c029d1.hex",
            "lulzbot_taz6_dual_v2":                     "Marlin_TAZ6_DualExtruderV2_1.1.9.34_5f9c029d1.hex",
            "lulzbot_taz6_flexy_dually_v2":                "Marlin_TAZ6_FlexyDually_1.1.9.34_5f9c029d1.hex",
            "lulzbot_taz6_dual_v3":                     "Marlin_TAZ6_DualExtruderV3_1.1.9.34_5f9c029d1.hex",
            "lulzbot_taz6_aerostruder":                    "Marlin_TAZ6_Aerostruder_1.1.9.34_5f9c029d1.hex",

            "lulzbot_taz6":                             "Marlin_TAZ6_Universal_2.0.6.7_d5f08b22.hex",
            "lulzbot_taz6_achemon":                         "Marlin_TAZ6_Universal_2.0.6.7_d5f08b22.hex",
            "lulzbot_taz6_banded_tiger":                 "Marlin_TAZ6_Universal_2.0.6.7_d5f08b22.hex",
            "lulzbot_taz6_dingy_cutworm":            "Marlin_TAZ6_Universal_2.0.6.7_d5f08b22.hex",
            "lulzbot_taz6_cecropia":              "Marlin_TAZ6_Universal_2.0.6.7_d5f08b22.hex",
            "lulzbot_taz6_goldenrod":              "Marlin_TAZ6_Universal_2.0.6.7_d5f08b22.hex",
            "lulzbot_taz6_lutefisk":              "Marlin_TAZ6_Universal_2.0.6.7_d5f08b22.hex",
            "lulzbot_taz6_perca":              "Marlin_TAZ6_Universal_2.0.6.7_d5f08b22.hex",

            "lulzbot_hibiscus":                  "Marlin_Mini2_Universal_2.0.6.7_d5f08b22.hex",
            "lulzbot_hibiscus_achemon":                    "Marlin_Mini2_Universal_2.0.6.7_d5f08b22.hex",
            "lulzbot_hibiscus_banded_tiger":            "Marlin_Mini2_Universal_2.0.6.7_d5f08b22.hex",
            "lulzbot_hibiscus_dingy_cutworm":       "Marlin_Mini2_Universal_2.0.6.7_d5f08b22.hex",
            "lulzbot_hibiscus_goldenrod":                    "Marlin_Mini2_Universal_2.0.6.7_d5f08b22.hex",
            "lulzbot_hibiscus_lutefisk":       "Marlin_Mini2_Universal_2.0.6.7_d5f08b22.hex",
            "lulzbot_hibiscus_perca":       "Marlin_Mini2_Universal_2.0.6.7_d5f08b22.hex",

            "lulzbot_quiver_achemon":                    "Marlin_TAZPro_Universal_2.0.6.7_a9890b31.bin",
            "lulzbot_quiver_banded_tiger":            "Marlin_TAZPro_Universal_2.0.6.7_a9890b31.bin",
            "lulzbot_quiver_cecropia":         "Marlin_TAZPro_Universal_2.0.6.7_a9890b31.bin",
            "lulzbot_quiver_dingy_cutworm":       "Marlin_TAZPro_Universal_2.0.6.7_a9890b31.bin",
            "lulzbot_quiver_evergreen_bagworm":        "Marlin_TAZPro_DualExtruder_2.0.0.144_aded3b617.bin",
            "lulzbot_quiver_goldenrod":            "Marlin_TAZPro_Universal_2.0.6.7_a9890b31.bin",
            "lulzbot_quiver_lutefisk":            "Marlin_TAZPro_Universal_2.0.6.7_a9890b31.bin",
            "lulzbot_quiver_perca":            "Marlin_TAZPro_Universal_2.0.6.7_a9890b31.bin",

            "lulzbot_redgum_goldenrod":      "Marlin_TAZWorkhorse_Universal_2.0.6.7_fbac1510.hex",
            "lulzbot_redgum_achemon":              "Marlin_TAZWorkhorse_Universal_2.0.6.7_fbac1510.hex",
            "lulzbot_redgum_banded_tiger":      "Marlin_TAZWorkhorse_Universal_2.0.6.7_fbac1510.hex",
            "lulzbot_redgum_cecropia":   "Marlin_TAZWorkhorse_Universal_2.0.6.7_fbac1510.hex",
            "lulzbot_redgum_dingy_cutworm": "Marlin_TAZWorkhorse_Universal_2.0.6.7_fbac1510.hex",
            "lulzbot_redgum_yellowfin":        "Marlin_TAZWorkhorse_DualExtruderV3.1_2.0.0.144.hex",
            "lulzbot_redgum_lutefisk":        "Marlin_TAZWorkhorse_Universal_2.0.6.7_fbac1510.hex",
            "lulzbot_redgum_perca":        "Marlin_TAZWorkhorse_Universal_2.0.6.7_fbac1510.hex",

            "lulzbot_gladiator_evergreen_bagworm":      "Marlin_TAZProXT_DualExtruder_2.0.0.144.1_78264b7f.bin",
            "lulzbot_gladiator_goldenrod":      "Marlin_TAZProXT_Universal_2.0.6.7_a9890b31.bin",
            "lulzbot_gladiator_dingy_cutworm":      "Marlin_TAZProXT_Universal_2.0.6.7_a9890b31.bin",
            "lulzbot_gladiator_banded_tiger":      "Marlin_TAZProXT_Universal_2.0.6.7_a9890b31.bin",
            "lulzbot_gladiator_lutefisk":      "Marlin_TAZProXT_Universal_2.0.6.7_a9890b31.bin",
            "lulzbot_gladiator_cecropia":      "Marlin_TAZProXT_Universal_2.0.6.7_a9890b31.bin",
            "lulzbot_gladiator_achemon":      "Marlin_TAZProXT_Universal_2.0.6.7_a9890b31.bin",
            "lulzbot_gladiator_perca":      "Marlin_TAZProXT_Universal_2.0.6.7_a9890b31.bin",

            "lulzbot_sidekick_289_achemon" :     "Marlin_289_SESLHE_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_289_banded_tiger" :     "Marlin_289_HSHSPLUS_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_289_cecropia" :     "Marlin_289_SESLHE_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_289_dingy_cutworm" :     "Marlin_289_HSHSPLUS_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_289_goldenrod" :     "Marlin_289_SESLHE_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_289_lutefisk" :     "Marlin_289_M175_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_289_perca" :     "Marlin_289_H175_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_289_sk175" :     "Marlin_289_SK175_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_289_sk285" :     "Marlin_289_SK285_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_747_achemon" :     "Marlin_747_SESLHE_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_747_banded_tiger" :     "Marlin_747_HSHSPLUS_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_747_cecropia" :     "Marlin_747_SESLHE_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_747_dingy_cutworm" :     "Marlin_747_HSHSPLUS_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_747_goldenrod" :     "Marlin_747_SESLHE_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_747_lutefisk" :     "Marlin_747_M175_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_747_perca" :     "Marlin_747_H175_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_747_sk175" :     "Marlin_747_SK175_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_747_sk285" :     "Marlin_747_SK285_2.0.6.6_b84f03e6.hex",

            

            "lulzbot_kangaroo_paw":                     "Marlin_Bio_SingleExtruder_2.0.0.174_226bfbbb7.hex",
        }

        lulzbot_lcd_machines = {
            "lulzbot_mini":                          "Marlin_MiniLCD_SingleExtruder_1.1.9.34_5f9c029d1.hex",
            "lulzbot_mini_flexy":                      "Marlin_MiniLCD_Flexystruder_1.1.9.34_5f9c029d1.hex",
            "lulzbot_mini_aerostruder":                 "Marlin_MiniLCD_Aerostruder_1.1.9.34_5f9c029d1.hex",
            "lulzbot_mini_achemon":                      "Marlin_MiniLCD_SmallLayer_1.1.9.34_5f9c029d1.hex",
            "lulzbot_mini_banded_tiger":              "Marlin_MiniLCD_HardenedSteel_1.1.9.34_5f9c029d1.hex",
            "lulzbot_mini_dingy_cutworm":         "Marlin_MiniLCD_HardenedSteelPlus_1.1.9.34_5f9c029d1.hex",
            "lulzbot_mini_cecropia":           "Marlin_MiniLCD_SingleExtruderAeroV2_1.1.9.34_5f9c029d1.hex",
            "lulzbot_mini_lutefisk":           "Marlin_MiniLCD_M175_2.0.0.144.1_8c651988.hex",

            "lulzbot_sidekick_289_achemon" :     "Marlin_289_Universal_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_289_banded_tiger" :     "Marlin_289_Universal_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_289_cecropia" :     "Marlin_289_Universal_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_289_dingy_cutworm" :     "Marlin_289_Universal_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_289_goldenrod" :     "Marlin_289_Universal_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_289_lutefisk" :     "Marlin_289_Universal_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_289_perca" :     "Marlin_289_Universal_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_289_sk175" :     "Marlin_289_Universal_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_289_sk285" :     "Marlin_289_Universal_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_747_achemon" :            "Marlin_747_Universal_2.0.6.6_b84f03e6.hex", 
            "lulzbot_sidekick_747_banded_tiger" :            "Marlin_747_Universal_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_747_cecropia" :            "Marlin_747_Universal_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_747_dingy_cutworm" :            "Marlin_747_Universal_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_747_goldenrod" :            "Marlin_747_Universal_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_747_lutefisk" :            "Marlin_747_Universal_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_747_perca" :            "Marlin_747_Universal_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_747_sk175" :            "Marlin_747_Universal_2.0.6.6_b84f03e6.hex",
            "lulzbot_sidekick_747_sk285" :            "Marlin_747_Universal_2.0.6.6_b84f03e6.hex",
        }
        lulzbot_revision_machines = {
            "lulzbot_quiver_achemon":                    "Marlin_TAZPro_Universal_2.0.6.7_a9890b31.bin",
            "lulzbot_quiver_banded_tiger":            "Marlin_TAZPro_Universal_2.0.6.7_a9890b31.bin",
            "lulzbot_quiver_cecropia":         "Marlin_TAZPro_Universal_2.0.6.7_a9890b31.bin",
            "lulzbot_quiver_dingy_cutworm":       "Marlin_TAZPro_Universal_2.0.6.7_a9890b31.bin",
            "lulzbot_quiver_evergreen_bagworm":        "Marlin_TAZPro_DualExtruder_2.0.0.144_aded3b617.bin",
            "lulzbot_quiver_goldenrod":            "Marlin_TAZPro_Universal_2.0.6.7_a9890b31.bin",
            "lulzbot_quiver_lutefisk":            "Marlin_TAZPro_Universal_2.0.6.7_a9890b31.bin",
            "lulzbot_quiver_perca":            "Marlin_TAZPro_Universal_2.0.6.7_a9890b31.bin",

            "lulzbot_redgum_goldenrod":      "Marlin_TAZWorkhorse_Universal_2.0.6.7_fbac1510.hex",
            "lulzbot_redgum_achemon":              "Marlin_TAZWorkhorse_Universal_2.0.6.7_fbac1510.hex",
            "lulzbot_redgum_banded_tiger":      "Marlin_TAZWorkhorse_Universal_2.0.6.7_fbac1510.hex",
            "lulzbot_redgum_cecropia":   "Marlin_TAZWorkhorse_Universal_2.0.6.7_fbac1510.hex",
            "lulzbot_redgum_dingy_cutworm": "Marlin_TAZWorkhorse_Universal_2.0.6.7_fbac1510.hex",
            "lulzbot_redgum_yellowfin":        "Marlin_TAZWorkhorse_DualExtruderV3.1_2.0.0.144.hex",
            "lulzbot_redgum_lutefisk":        "Marlin_TAZWorkhorse_Universal_2.0.6.7_fbac1510.hex",
            "lulzbot_redgum_perca":        "Marlin_TAZWorkhorse_Universal_2.0.6.7_fbac1510.hex",

        }

        ##TODO: Add check for multiple extruders
        hex_file = None
        if machine_id in machine_without_extras.keys():  # The machine needs to be defined here!
            if machine_id in machine_with_heated_bed.keys() and machine_has_heated_bed:
                Logger.log("d", "Choosing firmware with heated bed enabled for machine %s.", machine_id)
                hex_file = machine_with_heated_bed[machine_id]  # Return firmware with heated bed enabled
            else:
                Logger.log("d", "Choosing basic firmware for machine %s.", machine_id)
                hex_file = machine_without_extras[machine_id]  # Return "basic" firmware
        elif machine_id in lulzbot_machines.keys():
            machine_has_lcd = global_container_stack.getProperty("machine_has_lcd", "value")
            revision_type = global_container_stack.getProperty("revision_type","value")
            if machine_id in lulzbot_lcd_machines.keys() and machine_has_lcd:
                Logger.log("d", "Found firmware with LCD for machine %s.", machine_id)
                hex_file = lulzbot_lcd_machines[machine_id]
            ##elif machine_id in lulzbot_revision_machines.keys() and revision_type:
            ##    Logger.log("d","Found firmware with Revision for machine %s.", machine_id)
            ##    hex_file = lulzbot_revision_machines[machine_id]
            else:
                Logger.log("d", "Found firmware for machine %s.", machine_id)
                hex_file = lulzbot_machines[machine_id]
        else:
            Logger.log("w", "There is no firmware for machine %s.", machine_id)

        if hex_file:
            try:
                return Resources.getPath(CuraApplication.ResourceTypes.Firmware, hex_file.format(baudrate=baudrate))
            except FileNotFoundError:
                pass
        Logger.log("w", "Could not find any firmware for machine %s.", machine_id)
        return ""

    ##  Helper to identify serial ports (and scan for them)
    def _addRemovePorts(self, serial_ports):
        if len(self._serial_port_list) == 0 and len(serial_ports) > 0:
            # Hack to ensure its created in main thread
            self.addUSBOutputDeviceSignal.emit(USBPrinterOutputDevice.SERIAL_AUTODETECT_PORT)
        elif len(serial_ports) == 0:
            for port, device in self._usb_output_devices.items():
                device.close()
            self._usb_output_devices = {}
            self.getOutputDeviceManager().removeOutputDevice(USBPrinterOutputDevice.SERIAL_AUTODETECT_PORT)
        self._serial_port_list = list(serial_ports)

    ##  Because the model needs to be created in the same thread as the QMLEngine, we use a signal.
    def addOutputDevice(self, serial_port):
        device = USBPrinterOutputDevice(serial_port)
        device.connectionStateChanged.connect(self._onConnectionStateChanged)
        #device.connect()
        device.progressChanged.connect(self.progressChanged)
        device.firmwareUpdateChange.connect(self.firmwareUpdateChange)
        self._usb_output_devices[serial_port] = device
        self.getOutputDeviceManager().addOutputDevice(device)

    ##  If one of the states of the connected devices change, we might need to add / remove them from the global list.
    def _onConnectionStateChanged(self, serial_port):
        try:
            self.connectionStateChanged.emit()
        except KeyError:
            Logger.log("w", "Connection state of %s changed, but it was not found in the list")

    @pyqtProperty(QObject , notify = connectionStateChanged)
    def connectedPrinterList(self):
        self._usb_output_devices_model = ListModel()
        self._usb_output_devices_model.addRoleName(Qt.UserRole + 1, "name")
        self._usb_output_devices_model.addRoleName(Qt.UserRole + 2, "printer")
        for connection in self._usb_output_devices:
            if self._usb_output_devices[connection].connectionState == ConnectionState.connected:
                self._usb_output_devices_model.appendItem({"name": connection, "printer": self._usb_output_devices[connection]})
        return self._usb_output_devices_model

    ##  Create a list of serial ports on the system.
    #   \param only_list_usb If true, only usb ports are listed
    def getSerialPortList(self, only_list_usb = False):
        base_list = []
        for port in serial.tools.list_ports.comports():
            if not isinstance(port, tuple):
                port = (port.device, port.description, port.hwid)
            if only_list_usb and not port[2].startswith("USB"):
                continue
            base_list += [port[0]]

        return list(base_list)

    @pyqtProperty("QVariantList", constant=True)
    def portList(self):
        return self.getSerialPortList()

    @pyqtSlot(str, result=bool)
    def sendCommandToCurrentPrinter(self, command):
        try:
            printer = Application.getInstance().getMachineManager().printerOutputDevices[0]
        except:
            return False
        if type(printer) != USBPrinterOutputDevice:
            return False
        printer.sendCommand(command)
        return True

    @pyqtSlot(result=bool)
    def connectToCurrentPrinter(self):
        try:
            printer = Application.getInstance().getMachineManager().printerOutputDevices[0]
        except:
            return False
        if type(printer) != USBPrinterOutputDevice:
            return False
        printer.connect()
        return True

    _instance = None    # type: "USBPrinterOutputDeviceManager"
