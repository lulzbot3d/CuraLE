from UM.Qt.ListModel import ListModel

from PyQt6.QtCore import pyqtProperty, Qt, pyqtSignal

from UM.Settings.ContainerRegistry import ContainerRegistry
from UM.Settings.DefinitionContainer import DefinitionContainer

import copy

class LulzBotPrintersModel(ListModel):
    NameRole = Qt.ItemDataRole.UserRole + 1
    IdRole = Qt.ItemDataRole.UserRole + 2
    ImageRole = Qt.ItemDataRole.UserRole + 3
    HasSubtypesRole = Qt.ItemDataRole.UserRole + 4

    def __init__(self, parent = None):
        super().__init__(parent)
        self.addRoleName(self.NameRole, "name")
        self.addRoleName(self.IdRole, "id")
        self.addRoleName(self.ImageRole, "image")
        self.addRoleName(self.HasSubtypesRole, "has_subtypes")

        # Listen to changes
        ContainerRegistry.getInstance().containerAdded.connect(self._onContainerChanged)
        ContainerRegistry.getInstance().containerRemoved.connect(self._onContainerChanged)

        self._lulzbot_machine_categories = [("TAZ", ""), ("Mini", ""), ("SideKick", ""), ("Bio", ""), ("Other", "") ]

        self._level = 0
        self._machine_category_property = "TAZ"
        self._machine_type_property = "TAZ 8"
        self._machine_subtype_property = ""

        self._filter_dict = {"author": "LulzBot" , "lulzbot_machine_is_subtype": False}
        self._update()

    ##  Handler for container change events from registry
    def _onContainerChanged(self, container):
        # We only need to update when the changed container is a DefinitionContainer.
        if isinstance(container, DefinitionContainer):
            self._update()

    ##  Private convenience function to reset & repopulate the model.
    def _update(self):
        items = []

        if self._level == 0: # Machine Categories
            for category, image in self._lulzbot_machine_categories:
                items.append({
                    "name": category,
                    "image": image
                })

        elif self._level == 1: # Machine Types within given Category
            new_filter = copy.deepcopy(self._filter_dict)
            new_filter["lulzbot_machine_category"] = self._machine_category_property
            definition_containers = ContainerRegistry.getInstance().findDefinitionContainersMetadata(**new_filter)
            for metadata in definition_containers:
                metadata = metadata.copy()
                dupe = False
                for item in items:
                    if metadata["lulzbot_machine_type"] == item["name"]:
                        dupe = True
                        break
                if not dupe:
                    items.append({
                        "name": metadata["lulzbot_machine_type"],
                        "image": metadata["lulzbot_machine_image"],
                        "has_subtypes": metadata["lulzbot_machine_has_subtypes"]
                    })

        elif self._level == 2: # Machine Subtypes within a given Type
            new_filter = copy.deepcopy(self._filter_dict)
            new_filter["lulzbot_machine_type"] = self._machine_type_property
            del new_filter["lulzbot_machine_is_subtype"]
            definition_containers = ContainerRegistry.getInstance().findDefinitionContainersMetadata(**new_filter)
            for metadata in definition_containers:


        ## new_filter = copy.deepcopy(self._filter_dict)
        # definition_containers = ContainerRegistry.getInstance().findDefinitionContainersMetadata(**new_filter)

        # for metadata in definition_containers:
        #     metadata = metadata.copy()
        #     items.append({
        #         "name": metadata["name"],
        #         "id": metadata["id"],
        #     })
        # items = sorted(items, key=lambda x: x["machine_priority"]+x["name"])
        self.setItems(items)

    def setLevelProperty(self, new_level):
        if self._level != new_level:
            self._level = new_level
            self._update()

    def setMachineCategoryProperty(self, new_machine_category):
        if self._machine_category_property != new_machine_category:
            self._machine_category_property = new_machine_category
            self.machineCategoryPropertyChanged.emit()
            self._update()

    def setMachineTypeProperty(self, new_machine_type):
        if self._machine_type_property != new_machine_type:
            self._machine_type_property = new_machine_type
            self.machineTypePropertyChanged.emit()
            self._update()

    levelPropertyChanged = pyqtSignal()
    @pyqtProperty(int, fset = setLevelProperty, notify = levelPropertyChanged)
    def levelProperty(self):
        return self._level

    machineCategoryPropertyChanged = pyqtSignal()
    @pyqtProperty(str, fset = setMachineCategoryProperty, notify = machineCategoryPropertyChanged)
    def machineCategoryProperty(self):
        return self._machine_category_property

    machineTypePropertyChanged = pyqtSignal()
    @pyqtProperty(str, fset = setMachineTypeProperty, notify = machineTypePropertyChanged)
    def machineTypeProperty(self):
        return self._machine_type_property


    ##  Set the filter of this model based on a string.
    #   \param filter_dict Dictionary to do the filtering by.
    def setFilter(self, filter_dict):
        self._filter_dict = filter_dict
        self._update()

    filterChanged = pyqtSignal()

    @pyqtProperty("QVariantMap", fset = setFilter, notify = filterChanged)
    def filter(self):
        return self._filter_dict
