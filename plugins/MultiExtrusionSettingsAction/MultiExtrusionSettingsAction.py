# Copyright (c) 2017 Alephobjects

from PyQt5.QtCore import pyqtProperty, pyqtSignal
from UM.FlameProfiler import pyqtSlot

from cura.MachineAction import MachineAction

from UM.Application import Application
from UM.Settings.InstanceContainer import InstanceContainer
from UM.Settings.ContainerRegistry import ContainerRegistry
from UM.Settings.DefinitionContainer import DefinitionContainer
from UM.Logger import Logger

from cura.Settings.CuraContainerRegistry import CuraContainerRegistry

import UM.i18n
catalog = UM.i18n.i18nCatalog("cura")

class MultiExtrusionSettingsAction(MachineAction):
    def __init__(self, parent = None):
        super().__init__("MultiExtrusionSettingsAction", catalog.i18nc("@action", "Extruders Settings"))
        self._qml_url = "MultiExtrusionSettingsAction.qml"

        self._container_index = 0
        self._container_registry = ContainerRegistry.getInstance()
        self._container_registry.containerAdded.connect(self._onContainerAdded)

    def _reset(self):
        pass

    def _onContainerAdded(self, container):
        # Add this action as a supported action to all multi extrusion machine definitions
        if isinstance(container, DefinitionContainer) and container.getMetaDataEntry("type") == "machine":
            if container.getProperty("machine_extruder_count", "value") > 1:
                Application.getInstance().getMachineActionManager().addSupportedAction(container.getId(), self.getKey())

    @pyqtSlot()
    def forceUpdate(self):
        Application.getInstance().getBuildVolume()._onStackChanged()

