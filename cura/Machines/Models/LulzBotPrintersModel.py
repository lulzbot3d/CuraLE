from UM.Qt.ListModel import ListModel

from PyQt6.QtCore import pyqtProperty, Qt, pyqtSignal

from UM.Logger import Logger
from UM.Settings.ContainerRegistry import ContainerRegistry
from UM.Settings.DefinitionContainer import DefinitionContainer

import copy

class LulzBotPrintersModel(ListModel):
    IdRole = Qt.ItemDataRole.UserRole + 1
    PriorityRole = Qt.ItemDataRole.UserRole + 2
    NameRole = Qt.ItemDataRole.UserRole + 3
    FullNameRole = Qt.ItemDataRole.UserRole + 4
    TypeRole = Qt.ItemDataRole.UserRole + 5
    SubtypeRole = Qt.ItemDataRole.UserRole + 6
    ImageRole = Qt.ItemDataRole.UserRole + 7
    ToolHeadImageRole = Qt.ItemDataRole.UserRole + 8
    OptionsRole = Qt.ItemDataRole.UserRole + 9
    OptionIsDefaultRole = Qt.ItemDataRole.UserRole + 10
    HasSubtypesRole = Qt.ItemDataRole.UserRole + 11

    def __init__(self, parent = None):
        super().__init__(parent)
        self.addRoleName(self.IdRole, "id")
        self.addRoleName(self.PriorityRole, "priority")
        self.addRoleName(self.NameRole, "name")
        self.addRoleName(self.FullNameRole, "full_name")
        self.addRoleName(self.TypeRole, "type")
        self.addRoleName(self.SubtypeRole, "subtype")
        self.addRoleName(self.ImageRole, "image")
        self.addRoleName(self.ToolHeadImageRole, "tool_head_image")
        self.addRoleName(self.OptionsRole, "options")
        self.addRoleName(self.OptionIsDefaultRole, "option_is_default")
        self.addRoleName(self.HasSubtypesRole, "has_subtypes")

        # Listen to changes
        ContainerRegistry.getInstance().containerAdded.connect(self._onContainerChanged)
        ContainerRegistry.getInstance().containerRemoved.connect(self._onContainerChanged)

        self._lulzbot_machine_categories = [("TAZ", "taz_8"), ("Mini", "mini_3"), ("SideKick", "sidekick_747"), ("Bio", "bio"), ("Other", "lulz_logo") ]

        self._level = 0 # 0 = Categories, 1 = Types, 2 = Subtypes, 3 = Tool Heads, 4 = Printer Options
        self._level_history = []
        self._machine_category = "TAZ"
        self._machine_type = "TAZ 8"
        self._machine_subtype = ""
        self._machine_id = ""
        self._machine_name = ""

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
            new_filter["lulzbot_machine_category"] = self._machine_category
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
                        "priority": metadata["lulzbot_machine_priority"],
                        "type": metadata["lulzbot_machine_type"],
                        "image": metadata["lulzbot_machine_image"] if metadata["lulzbot_machine_image"] != "" else "lulz_logo",
                        "has_subtypes": metadata["lulzbot_machine_has_subtypes"]
                    })
            items = sorted(items, key=lambda x: str(x["priority"])+x["name"])

        elif self._level == 2: # Machine Subtypes within a given Type
            new_filter = copy.deepcopy(self._filter_dict)
            new_filter["lulzbot_machine_type"] = self._machine_type
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
                        "priority": metadata["lulzbot_machine_priority"],
                        "type": metadata["lulzbot_machine_type"],
                        "subtype": metadata["lulzbot_machine_subtype"],
                        "image": metadata["lulzbot_machine_image"] if metadata["lulzbot_machine_image"] != "" else "lulz_logo"
                    })
            items = sorted(items, key=lambda x: str(x["priority"])+x["name"])

        elif self._level == 3: # Tool Head Selection
            new_filter = copy.deepcopy(self._filter_dict)
            new_filter["lulzbot_machine_type"] = self._machine_type
            new_filter["lulzbot_machine_subtype"] = self._machine_subtype
            definition_containers = ContainerRegistry.getInstance().findDefinitionContainersMetadata(**new_filter)
            for metadata in definition_containers:
                metadata = metadata.copy()
                items.append({
                    "id": metadata["id"],
                    "priority": metadata["lulzbot_tool_head_priority"],
                    "name": metadata["lulzbot_tool_head"],
                    "full_name": metadata["name"],
                    "type": metadata["lulzbot_machine_type"],
                    "subtype": metadata["lulzbot_machine_subtype"],
                    "image": metadata["lulzbot_tool_head_image"] if metadata["lulzbot_tool_head_image"] != "" else "lulz_logo"
                })
            items = sorted(items, key=lambda x: str(x["priority"])+x["name"])

        elif self._level == 4: # Machine Options
            new_filter = copy.deepcopy(self._filter_dict)
            new_filter["id"] = self._machine_id
            definition_containers = ContainerRegistry.getInstance().findDefinitionContainersMetadata(**new_filter)
            # for metadata in definition_containers:
            if len(definition_containers) > 1:
                Logger.log("w", "There was more than one printer definition with the same ID!?")
            metadata = definition_containers[0]
            for num in range(2):
                data = metadata.copy()
                if num == 0:
                    items.append({
                        "name": str(data["lulzbot_machine_type"] + " " + data["lulzbot_machine_subtype"]).strip(),
                        "image": data["lulzbot_machine_image"] if data["lulzbot_machine_image"] != "" else "lulz_logo"
                    })
                elif num == 1:
                    items.append({
                        "name": data["lulzbot_tool_head"],
                        "image": data["lulzbot_tool_head_image"] if data["lulzbot_tool_head_image"] != "" else "lulz_logo"
                    })
            for option in metadata["lulzbot_machine_options"]:
                items.append({
                    "name": str(option[0]),
                    "image": option[2],
                    "option_is_default": option[1]
                })

        self.setItems(items)

    ### Setters and Getters
    ## Level
    def setLevel(self, new_level):
        if self._level != new_level:
            if new_level < self._level:
                if new_level == 0:
                    self._level_history = []
                else:
                    if len(self._level_history) > 0:
                        self._level_history.pop()
            else:
                self._level_history.append(self._level)
            self._level = new_level
            self.levelChanged.emit()
            self._update()


    levelChanged = pyqtSignal()
    @pyqtProperty(int, fset = setLevel, notify = levelChanged)
    def level(self):
        return self._level

    ## Level History
    levelHistoryChanged = pyqtSignal()
    @pyqtProperty(int, fset = None, notify = levelHistoryChanged)
    def levelHistory(self):
        return self._level_history[-1]

    ## Machine Category
    def setMachineCategory(self, new_machine_category):
        if self._machine_category != new_machine_category:
            self._machine_category = new_machine_category
            self.machineCategoryChanged.emit()

    machineCategoryChanged = pyqtSignal()
    @pyqtProperty(str, fset = setMachineCategory, notify = machineCategoryChanged)
    def machineCategory(self):
        return self._machine_category

    ## Machine Type
    def setMachineType(self, new_machine_type):
        if self._machine_type != new_machine_type:
            self._machine_type = new_machine_type
            self.machineTypeChanged.emit()

    machineTypeChanged = pyqtSignal()
    @pyqtProperty(str, fset = setMachineType, notify = machineTypeChanged)
    def machineType(self):
        return self._machine_type

    ## Machine Subtype
    def setMachineSubtype(self, new_machine_subtype):
        if self._machine_subtype != new_machine_subtype:
            self._machine_subtype = new_machine_subtype
            self.machineSubtypeChanged.emit()

    machineSubtypeChanged = pyqtSignal()
    @pyqtProperty(str, fset = setMachineSubtype, notify = machineSubtypeChanged)
    def machineSubtype(self):
        return self._machine_subtype

    ## Machine ID
    def setMachineId(self, new_machine_id):
        if self._machine_id != new_machine_id:
            self._machine_id = new_machine_id
            self.machineIdChanged.emit()

    machineIdChanged = pyqtSignal()
    @pyqtProperty(str, fset = setMachineId, notify = machineIdChanged)
    def machineId(self):
        return self._machine_id

    ## Machine Name
    def setMachineName(self, new_machine_name):
        if self._machine_name != new_machine_name:
            self._machine_name = new_machine_name
            self.machineNameChanged.emit()

    machineNameChanged = pyqtSignal()
    @pyqtProperty(str, fset = setMachineName, notify = machineNameChanged)
    def machineName(self):
        return self._machine_name

    ## Filter
    def setFilter(self, filter_dict):
        self._filter_dict = filter_dict
        self._update()

    filterChanged = pyqtSignal()
    @pyqtProperty("QVariantMap", fset = setFilter, notify = filterChanged)
    def filter(self):
        return self._filter_dict
