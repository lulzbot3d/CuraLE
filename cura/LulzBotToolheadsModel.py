from UM.Qt.ListModel import ListModel

from PyQt5.QtCore import pyqtProperty, Qt, pyqtSignal

from UM.Settings.ContainerRegistry import ContainerRegistry
from UM.Settings.DefinitionContainer import DefinitionContainer

import copy


class LulzBotToolheadsModel(ListModel):
    NameRole = Qt.UserRole + 1
    IdRole = Qt.UserRole + 2
    ToolheadRole = Qt.UserRole + 3

    def __init__(self, parent = None):
        super().__init__(parent)
        self.addRoleName(self.NameRole, "name")
        self.addRoleName(self.IdRole, "id")
        self.addRoleName(self.ToolheadRole, "toolhead")

        # Listen to changes
        ContainerRegistry.getInstance().containerAdded.connect(self._onContainerChanged)
        ContainerRegistry.getInstance().containerRemoved.connect(self._onContainerChanged)

        self._base_machine_property = ""

        self._filter_dict = {"category": "LulzBot", "visible": True}
        self._update()

    ##  Handler for container change events from registry
    def _onContainerChanged(self, container):
        # We only need to update when the changed container is a DefinitionContainer.
        if isinstance(container, DefinitionContainer):
            self._update()

    ##  Private convenience function to reset & repopulate the model.
    def _update(self):
        items = []
        new_filter = copy.deepcopy(self._filter_dict)
        new_filter["base_machine"] = self._base_machine_property
        definition_containers = ContainerRegistry.getInstance().findDefinitionContainersMetadata(**new_filter)

        for metadata in definition_containers:
            metadata = metadata.copy()

            items.append({
                "toolhead": metadata.get("user_toolhead_name", metadata.get("firmware_toolhead_name", metadata["name"])),
                "id": metadata["id"],
                "name": metadata["name"],
                "priority": metadata.get("priority", "99")
            })
        items = sorted(items, key=lambda x: x["priority"]+x["name"])
        self.setItems(items)

    def setBaseMachineProperty(self, new_base_machine):
        if self._base_machine_property != new_base_machine:
            self._base_machine_property = new_base_machine
            self.baseMachinePropertyChanged.emit()
            self._update()

    baseMachinePropertyChanged = pyqtSignal()
    @pyqtProperty(str, fset = setBaseMachineProperty, notify = baseMachinePropertyChanged)
    def baseMachineProperty(self):
        return self._base_machine_property


    ##  Set the filter of this model based on a string.
    #   \param filter_dict Dictionary to do the filtering by.
    def setFilter(self, filter_dict):
        self._filter_dict = filter_dict
        self._update()

    filterChanged = pyqtSignal()
    @pyqtProperty("QVariantMap", fset = setFilter, notify = filterChanged)
    def filter(self):
        return self._filter_dict
