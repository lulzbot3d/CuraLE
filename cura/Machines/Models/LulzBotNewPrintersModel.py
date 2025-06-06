from UM.Qt.ListModel import ListModel

from PyQt6.QtCore import pyqtProperty, Qt, pyqtSignal

from UM.Settings.ContainerRegistry import ContainerRegistry
from UM.Settings.DefinitionContainer import DefinitionContainer

import copy

class LulzBotPrintersModel(ListModel):
    NameRole = Qt.ItemDataRole.UserRole + 1
    IdRole = Qt.ItemDataRole.UserRole + 2

    def __init__(self, parent = None):
        super().__init__(parent)
        self.addRoleName(self.NameRole, "name")
        self.addRoleName(self.IdRole, "id")

        # Listen to changes
        ContainerRegistry.getInstance().containerAdded.connect(self._onContainerChanged)
        ContainerRegistry.getInstance().containerRemoved.connect(self._onContainerChanged)

        self._lulzbot_machines = {
            "category": {
                "TAZ": {
                    "printers": {
                        "TAZ 5": {
                            "priority": 5,
                            "subtypes": {},
                            "image": ""
                        },
                        "TAZ 6": {
                            "priority": 4,
                            "subtypes": {},
                            "image": ""
                        },
                        "TAZ Pro": {
                            "priority": 1,
                            "subtypes": {
                                "XT": {
                                    "image": ""
                                },
                                "Long Bed": {
                                    "image": ""
                                },
                                "Long Bed v2": {
                                    "image": ""
                                }
                            },
                            "image": ""
                        },
                        "TAZ 8": {
                            "priority": 0,
                            "subtypes": {
                                "XT": {
                                    "image": ""
                                },
                                "Long Bed v2": {
                                    "image": ""
                                }
                            },
                            "image": ""
                        },
                        "Workhorse": {
                            "priority": 3,
                            "subtypes": {},
                            "image": ""
                        },
                        "Workhorse 2": {
                            "priority": 2,
                            "subtypes": {},
                            "image": ""
                        }
                    },
                    "image": "",
                    "priority": 0
                },
                "Mini": {
                    "printers": {
                        "Mini 1": {
                            "priority": 2,
                            "subtypes": {},
                            "image": ""
                        },
                        "Mini 2": {
                            "priority": 1,
                            "subtypes": {},
                            "image": ""
                        },
                        "Mini 3": {
                            "priority": 0,
                            "subtypes": {},
                            "image": ""
                        }
                    },
                    "image": "",
                    "priority": 1
                },
                "SideKick": {
                    "printers": {
                        "SideKick 289": {
                            "priority": 1,
                            "subtypes": {},
                            "image": ""
                        },
                        "SideKick 747": {
                            "priority": 0,
                            "subtypes": {},
                            "image": ""
                        }
                    },
                    "image": "",
                    "priority": 2
                },
                "Bio": {
                    "printers": {
                        "Bio": {
                            "priority": 0,
                            "subtypes": {},
                            "image": ""
                        }
                    },
                    "image": "",
                    "priority": 3
                },
                "Other": {
                    "printers": {
                        "Core XY": {
                            "priority": 0,
                            "subtypes": {},
                            "image": ""
                        }
                    },
                    "image": "",
                    "priority": 4
                }
            }
        }

        self._level = 0
        self._machine_category_property = ""

        self._filter_dict = {"author": "LulzBot", "visible": False}
        self._update()

    ##  Handler for container change events from registry
    def _onContainerChanged(self, container):
        # We only need to update when the changed container is a DefinitionContainer.
        if isinstance(container, DefinitionContainer):
            self._update()

    ##  Private convenience function to reset & repopulate the model.
    def _update(self):
        items = []

        if self._level == 0:
            for category, data in self._lulzbot_machines["category"].items():
                items.append({
                    "name": category,
                    "image": data["image"],
                    "priority": data["priority"]
                })
        elif self._level == 1:
            if self._machine_category_property in self._lulzbot_machines["category"].keys():
                for printer, data in self._lulzbot_machines["category"][self._machine_category_property]["printers"].items():
                    items.append({
                        "name": printer,
                        "image": data["image"],
                        "subtypes": data["subtypes"],
                        "priority": data["priority"]
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

    def setMachineCategoryProperty(self, new_machine_category):
        if self._machine_category_property != new_machine_category:
            self._machine_category_property = new_machine_category
            self.machineCategoryPropertyChanged.emit()
            self._update()

    machineCategoryPropertyChanged = pyqtSignal()
    @pyqtProperty(str, fset = setMachineCategoryProperty, notify = machineCategoryPropertyChanged)
    def machineCategoryProperty(self):
        return self._machine_category_property


    ##  Set the filter of this model based on a string.
    #   \param filter_dict Dictionary to do the filtering by.
    def setFilter(self, filter_dict):
        self._filter_dict = filter_dict
        self._update()

    filterChanged = pyqtSignal()

    @pyqtProperty("QVariantMap", fset = setFilter, notify = filterChanged)
    def filter(self):
        return self._filter_dict
