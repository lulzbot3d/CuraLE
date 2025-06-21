from UM.Qt.ListModel import ListModel

from PyQt6.QtCore import pyqtProperty, Qt, pyqtSignal

from UM.Settings.ContainerRegistry import ContainerRegistry
from UM.Settings.DefinitionContainer import DefinitionContainer

import copy

class LulzBotNewPrintersModel(ListModel):
    IdRole = Qt.ItemDataRole.UserRole + 1
    NameRole = Qt.ItemDataRole.UserRole + 2
    TypeRole = Qt.ItemDataRole.UserRole + 3
    SubtypeRole = Qt.ItemDataRole.UserRole + 4
    ToolHeadRole = Qt.ItemDataRole.UserRole + 5
    ImageRole = Qt.ItemDataRole.UserRole + 6
    OptionsRole = Qt.ItemDataRole.UserRole + 7
    HasSubtypesRole = Qt.ItemDataRole.UserRole + 8

    def __init__(self, parent = None):
        super().__init__(parent)
        self.addRoleName(self.IdRole, "id")
        self.addRoleName(self.NameRole, "name")
        self.addRoleName(self.TypeRole, "type")
        self.addRoleName(self.SubtypeRole, "subtype")
        self.addRoleName(self.ToolHeadRole, "tool_head")
        self.addRoleName(self.ImageRole, "image")
        self.addRoleName(self.OptionsRole, "options")
        self.addRoleName(self.HasSubtypesRole, "has_subtypes")

        # Listen to changes
        ContainerRegistry.getInstance().containerAdded.connect(self._onContainerChanged)
        ContainerRegistry.getInstance().containerRemoved.connect(self._onContainerChanged)

        self._lulzbot_machine_categories = [("TAZ", ""), ("Mini", ""), ("SideKick", ""), ("Bio", ""), ("Other", "") ]

        self._level = 0 # 0 = Categories, 1 = Types, 2 = Subtypes, 3 = Tool Heads, 4 = Printer Options
        self._machine_category_property = "TAZ"
        self._machine_type_property = "TAZ 8"
        self._machine_subtype_property = ""
        self._machine_id_property = ""

        self._filter_dict = {"author": "LulzBot" , "visible": True}
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
            new_filter["lulzbot_machine_is_subtype"] = False
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
                        "type": metadata["lulzbot_machine_type"],
                        "image": metadata["lulzbot_machine_image"],
                        "has_subtypes": metadata["lulzbot_machine_has_subtypes"]
                    })

        elif self._level == 2: # Machine Subtypes within a given Type
            new_filter = copy.deepcopy(self._filter_dict)
            new_filter["lulzbot_machine_type"] = self._machine_type_property
            definition_containers = ContainerRegistry.getInstance().findDefinitionContainersMetadata(**new_filter)
            for metadata in definition_containers:
                metadata = metadata.copy()
                dupe = False
                for item in items:
                    if metadata["lulzbot_machine_subtype"] == item["subtype"]:
                        dupe = True
                        break
                if not dupe:
                    items.append({
                        "name": str(metadata["lulzbot_machine_type"] + " " + metadata["lulzbot_machine_subtype"]).strip(),
                        "type": metadata["lulzbot_machine_type"],
                        "subtype": metadata["lulzbot_machine_subtype"],
                        "image": metadata["lulzbot_machine_image"]
                    })

        elif self._level == 3: # Tool Head Selection
            new_filter = copy.deepcopy(self._filter_dict)
            new_filter["lulzbot_machine_type"] = self._machine_type_property
            new_filter["lulzbot_machine_subtype"] = self._machine_subtype_property
            definition_containers = ContainerRegistry.getInstance().findDefinitionContainersMetadata(**new_filter)
            for metadata in definition_containers:
                metadata = metadata.copy()
                items.append({
                    "id": metadata["id"],
                    "name": metadata["name"],
                    "type": metadata["lulzbot_machine_type"],
                    "subtype": metadata["lulzbot_machine_subtype"],
                    "tool_head": metadata["lulzbot_tool_head"],
                    "image": metadata["lulzbot_tool_head_image"]
                })

        elif self._level == 4: # Machine Options
            new_filter = copy.deepcopy(self._filter_dict)
            new_filter["id"] = self._machine_id_property
            definition_containers = ContainerRegistry.getInstance().findDefinitionContainersMetadata(**new_filter)
            for metadata in definition_containers:
                metadata = metadata.copy()
                items.append({
                    "id": metadata["id"],
                    "name": metadata["name"],
                    "image": metadata["lulzbot_tool_head_image"],
                    "options": metadata.get("lulzbot_machine_options", {})
                })


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

    def setMachineTypeProperty(self, new_machine_type):
        if self._machine_type_property != new_machine_type:
            self._machine_type_property = new_machine_type
            self.machineTypePropertyChanged.emit()

    def setMachineSubtypeProperty(self, new_machine_subtype):
        if self._machine_subtype_property != new_machine_subtype:
            self._machine_subtype_property = new_machine_subtype
            self.machineSubtypePropertyChanged.emit()

    def setMachineIdProperty(self, new_machine_id):
        if self._machine_id_property != new_machine_id:
            self._machine_id_property = new_machine_id
            self.machineIdPropertyChanged.emit()

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

    machineSubtypePropertyChanged = pyqtSignal()
    @pyqtProperty(str, fset = setMachineSubtypeProperty, notify = machineSubtypePropertyChanged)
    def machineSubtypeProperty(self):
        return self._machine_subtype_property

    machineIdPropertyChanged = pyqtSignal()
    @pyqtProperty(str, fset = setMachineIdProperty, notify = machineIdPropertyChanged)
    def machineIdProperty(self):
        return self._machine_id_property


    ##  Set the filter of this model based on a string.
    #   \param filter_dict Dictionary to do the filtering by.
    def setFilter(self, filter_dict):
        self._filter_dict = filter_dict
        self._update()

    filterChanged = pyqtSignal()

    @pyqtProperty("QVariantMap", fset = setFilter, notify = filterChanged)
    def filter(self):
        return self._filter_dict
