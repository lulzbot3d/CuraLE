from UM.Qt.ListModel import ListModel

from PyQt5.QtCore import pyqtProperty, Qt, pyqtSignal

from UM.Settings.ContainerRegistry import ContainerRegistry
from UM.Settings.DefinitionContainer import DefinitionContainer


class LulzBotPrintersModel(ListModel):
    NameRole = Qt.UserRole + 1
    IdRole = Qt.UserRole + 2
    LCDRole = Qt.UserRole + 3
    RevisionRole = Qt.UserRole + 4

    def __init__(self, parent = None):
        super().__init__(parent)
        self.addRoleName(self.NameRole, "name")
        self.addRoleName(self.IdRole, "id")
        self.addRoleName(self.LCDRole, "lcd")
        self.addRoleName(self.RevisionRole, "revision")

        # Listen to changes
        ContainerRegistry.getInstance().containerAdded.connect(self._onContainerChanged)
        ContainerRegistry.getInstance().containerRemoved.connect(self._onContainerChanged)

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
        definition_containers = ContainerRegistry.getInstance().findDefinitionContainersMetadata(**self._filter_dict)

        for metadata in definition_containers:
            metadata = metadata.copy()

            already_added = False
            for i in items:
                if i["id"] == metadata["base_machine"]:
                    already_added = True
                    break
            if not already_added:
                items.append({
                    "name": metadata["base_machine_name"],
                    "id": metadata["base_machine"],
                    "lcd": metadata.get("has_optional_lcd", False),
                    "revision": metadata.get("has_revision", False),
                    "machine_priority": metadata.get("machine_priority", "90")
                })
        items = sorted(items, key=lambda x: x["machine_priority"]+x["name"])
        self.setItems(items)


    ##  Set the filter of this model based on a string.
    #   \param filter_dict Dictionary to do the filtering by.
    def setFilter(self, filter_dict):
        self._filter_dict = filter_dict
        self._update()

    filterChanged = pyqtSignal()

    @pyqtProperty("QVariantMap", fset = setFilter, notify = filterChanged)
    def filter(self):
        return self._filter_dict
