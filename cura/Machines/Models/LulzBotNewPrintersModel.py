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
                "Bio": {
                    "image": "",
                    "printers": {
                        "Bio": {
                            "has_subtypes": False,
                            "image": "",
                            "priority": 0,
                            "subtypes": {},
                            "toolheads": ["Syringe"]
                        }
                    },
                    "priority": 3
                },
                "Mini": {
                    "image": "",
                    "printers": {
                        "Mini 1": {
                            "has_subtypes": False,
                            "image": "",
                            "priority": 2,
                            "subtypes": {},
                            "toolheads": ["Aerostruder", "Flexystruder v2", "HS", "HS+", "M175 v2", "SE",
                                          "Single Extruder", "SL"]
                        },
                        "Mini 2": {
                            "has_subtypes": False,
                            "image": "",
                            "priority": 1,
                            "subtypes": {},
                            "toolheads": ["H175", "HE", "HS", "HS+", "M175 v2", "Meteor 175", "Meteor 285", "SE", "SL"]
                        },
                        "Mini 3": {
                            "has_subtypes": False,
                            "image": "",
                            "priority": 0,
                            "subtypes": {},
                            "toolheads": ["Meteor 175", "Meteor 285"]
                        }
                    },
                    "priority": 1
                },
                "Other": {
                    "image": "",
                    "printers": {
                        "Core XY": {
                            "has_subtypes": False,
                            "image": "",
                            "priority": 0,
                            "subtypes": {},
                            "toolheads": ["Asteroid 285", "Meteor 175", "Meteor 285"]
                        }
                    },
                    "priority": 4
                },
                "SideKick": {
                    "image": "",
                    "printers": {
                        "SideKick 289": {
                            "has_subtypes": False,
                            "image": "",
                            "priority": 1,
                            "subtypes": {},
                            "toolheads": ["H175", "HE", "HS", "HS+", "M175 v2", "Meteor 175", "Meteor 285", "SE", "SK175",
                                          "SK285", "SL"]
                        },
                        "SideKick 747": {
                            "has_subtypes": False,
                            "image": "",
                            "priority": 0,
                            "subtypes": {},
                            "toolheads": ["Asteroid 285", "H175", "HE", "HS", "HS+", "M175 v2", "Meteor 175", "Meteor 285",
                                          "SE", "SK175", "SK285", "SL"]
                        }
                    },
                    "priority": 2
                },
                "TAZ": {
                    "image": "",
                    "printers": {
                        "TAZ 5": {
                            "has_subtypes": False,
                            "image": "",
                            "priority": 5,
                            "subtypes": {},
                            "toolheads": ["Aerostruder", "Dual v2", "Dual v3", "FlexyDually v2", "Flexystruder v2", "HS",
                                          "HS+", "M175 v2", "MOARstruder", "SE", "Single Extruder", "SL", "Twoolhead"]
                        },
                        "TAZ 6": {
                            "has_subtypes": False,
                            "image": "",
                            "priority": 4,
                            "subtypes": {},
                            "toolheads": ["Aerostruder", "Dual v2", "Dual v3", "FlexyDually v2", "Flexystruder v2", "H175",
                                          "HE", "HS", "HS+", "M175 v2", "MOARstruder", "SE", "Single Extruder", "SL", "Twoolhead"]
                        },
                        "TAZ Pro": {
                            "has_subtypes": True,
                            "image": "",
                            "priority": 1,
                            "subtypes": {
                                "TAZ Pro": {
                                    "image": "",
                                    "toolheads": ["Asteroid 285", "H175", "HE", "HS", "HS+", "M175 v2", "Meteor 175", "Meteor 285",
                                          "Pro Dual", "SE", "SL", "Twin Nebula 175", "Twin Nebula 285"]
                                },
                                "TAZ Pro Long Bed": {
                                    "image": "",
                                    "toolheads": ["Asteroid 285", "Meteor 175", "Meteor 285"]
                                },
                                "TAZ Pro Long Bed v2": {
                                    "image": "",
                                    "toolheads": ["Asteroid 285", "H175", "HE", "HS", "HS+", "M175 v2", "Meteor 175", "Meteor 285",
                                          "Pro Dual", "SE", "SL"]
                                },
                                "TAZ Pro XT": {
                                    "image": "",
                                    "toolheads": ["Asteroid 285", "H175", "HE", "HS", "HS+", "M175 v2", "Meteor 175", "Meteor 285",
                                          "Pro Dual", "SE", "SL", "Twin Nebula 175", "Twin Nebula 285"]
                                }
                            },
                            "toolheads": ["Asteroid 285", "H175", "HE", "HS", "HS+", "M175 v2", "Meteor 175", "Meteor 285",
                                          "Pro Dual", "SE", "SL", "Twin Nebula 175", "Twin Nebula 285"]
                        },
                        "TAZ 8": {
                            "has_subtypes": True,
                            "image": "",
                            "priority": 0,
                            "subtypes": {
                                "TAZ 8": {
                                    "image": "",
                                    "toolheads": ["Asteroid 285", "Meteor 175", "Meteor 285", "Twin Nebula 175", "Twin Nebula 285"]
                                },
                                "TAZ 8 Long Bed v2": {
                                    "image": "",
                                    "toolheads": ["Asteroid 285", "Meteor 175", "Meteor 285", "Twin Nebula 175", "Twin Nebula 285"]
                                },
                                "TAZ 8 XT": {
                                    "image": "",
                                    "toolheads": ["Asteroid 285", "Meteor 175", "Meteor 285", "Twin Nebula 175", "Twin Nebula 285"]
                                }
                            }
                        },
                        "Workhorse": {
                            "has_subtypes": False,
                            "image": "",
                            "priority": 3,
                            "subtypes": {},
                            "toolheads": ["Asteroid 285", "H175", "HE", "HS", "HS+", "M175 v2", "Meteor 175", "Meteor 285"
                                          "SE", "SL"]
                        },
                        "Workhorse 2": {
                            "has_subtypes": False,
                            "image": "",
                            "priority": 2,
                            "subtypes": {},
                            "toolheads": ["Asteroid 285", "Meteor 175", "Meteor 285"]
                        }
                    },
                    "priority": 0
                }
            }
        }

        self._lulzbot_toolheads = {
            "Aerostruder": {},
            "Asteroid 285": {},
            "Dual v2": {},
            "Dual v3": {},
            "FlexyDually v2": {},
            "Flexystruder v2": {},
            "H175": {},
            "HE": {},
            "HS": {},
            "HS+": {},
            "M175 v2": {},
            "Meteor 175": {},
            "Meteor 285": {},
            "MOARstruder": {},
            "Pro Dual": {},
            "SE": {},
            "Single Extruder": {},
            "SK175": {},
            "SK285": {},
            "SL": {},
            "Syringe": {},
            "Twin Nebula 175": {},
            "Twin Nebula 285": {},
            "Twoolhead": {}
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
