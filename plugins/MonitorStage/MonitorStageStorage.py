from PyQt5.QtCore import pyqtProperty, pyqtSignal, QObject


class MonitorStageStorage (QObject):
    __instance = None

    def __init__(self):
        super().__init__()
        self._moveLengthAmount = 1
        self._extrusionAmount = 1
        self._temperature = 1
        self._extruderNumber = 0

    moveLengthAmountChanged = pyqtSignal()
    extrusionAmountChanged = pyqtSignal()
    temperatureChanged = pyqtSignal()
    extruderNumberChanged = pyqtSignal()

    @classmethod
    def getInstance(self, *args, **kwargs):
        if self.__instance is None:
            self.__instance = MonitorStageStorage()
        return self.__instance

    def setMoveLengthAmount(self, value):
        self._moveLengthAmount = value
        self.moveLengthAmountChanged.emit()

    @pyqtProperty(int, notify=moveLengthAmountChanged, fset=setMoveLengthAmount)
    def moveLengthAmount(self):
        return self._moveLengthAmount

    def setExtrusionAmount(self, value):
        self._extrusionAmount = value
        self.extrusionAmountChanged.emit()

    @pyqtProperty(int, notify=extrusionAmountChanged, fset=setExtrusionAmount)
    def extrusionAmount(self):
        return self._extrusionAmount

    def setTemperature(self, value):
        self._temperature = value
        self.temperatureChanged.emit()

    @pyqtProperty(int, notify=temperatureChanged, fset=setTemperature)
    def Temperature(self):
        return self._temperature

    def setExtruderNumber(self, value):
        self._extruderNumber = value
        self.extruderNumberChanged.emit()

    @pyqtProperty(int, notify=extruderNumberChanged, fset=setExtruderNumber)
    def extruderNumber(self):
        return self._extruderNumber




