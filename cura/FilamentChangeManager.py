# Copyright (c) 2023 Fargo Additive Manufacturing Equipment 3D, LLC.
# CuraLE is released under the terms of the LGPLv3 or higher.

import collections
import configparser  # The metadata is stored as a serialised config file
import io
import json
from typing import Any, Dict, List, Optional, TYPE_CHECKING

from PyQt5.QtCore import QObject, pyqtProperty, pyqtSignal, pyqtSlot

from UM.Application import Application
from UM.Logger import Logger
from UM.Settings.ContainerFormatError import ContainerFormatError
from UM.Settings.ContainerRegistry import ContainerRegistry
from UM.Settings.ContainerStack import ContainerStack
from UM.Settings.DefinitionContainer import DefinitionContainer
from UM.Settings.InstanceContainer import InstanceContainer
from UM.Signal import Signal, signalemitter

import cura.CuraApplication

if TYPE_CHECKING:
    from UM.Settings.Interfaces import DefinitionContainerInterface
    from cura.CuraApplication import CuraApplication

@signalemitter
class FilamentChangeManager(QObject):
    """
    Provides the tool to trigger a filament change at specific layers
    Useful for color changes
    """

    def __init__(self, parent = None) -> None:
        QObject.__init__(self, parent)

        # Script __init__
        self._stack = None  # type: Optional[ContainerStack]
        self._definition = None  # type: Optional[DefinitionContainerInterface]
        self._instance = None  # type: Optional[InstanceContainer]

        # Filament Change __init__
        self._metadata_name = "filament_change_manager"
        self._layer_keyword = ";LAYER:"
        self._current_printer = None

        # PostProcessing __init__
        self._global_container_stack = Application.getInstance().getGlobalContainerStack()
        if self._global_container_stack:
            self._global_container_stack.metaDataChanged.connect(self._restoreSettingsFromMetadata)
            self._current_printer = self._global_container_stack.getId()

        Application.getInstance().getOutputDeviceManager().writeStarted.connect(self.execute)
        Application.getInstance().globalContainerStackChanged.connect(self._onGlobalContainerStackChanged)

        self.initialize()

    settingsLoaded = Signal()
    valueChanged = Signal()  # Signal emitted whenever a value of a setting is changed
    stackChanged = pyqtSignal()

    ##
    # All related to retreiving and storing settings and preferences from the stack
    ##

    def initialize(self) -> None:
        """Sets up settings needed for Filament Changes. Called whenever the global stack changes."""
        Logger.log("d", "Initializing Filament Change Manager")
        setting_data = self.getSettingData()
        self._stack = ContainerStack(stack_id=str(id(self)))
        self._stack.setDirty(False)  # This stack does not need to be saved.

        ## Check if the definition of this script already exists. If not, add it to the registry.
        if "key" in setting_data:
            definitions = ContainerRegistry.getInstance().findDefinitionContainers(id=setting_data["key"])
            if definitions:
                # Definition was found
                self._definition = definitions[0]
            else:
                self._definition = DefinitionContainer(setting_data["key"])
                try:
                    self._definition.deserialize(json.dumps(setting_data))
                    ContainerRegistry.getInstance().addContainer(self._definition)
                except ContainerFormatError:
                    self._definition = None
                    return
        if self._definition is None:
            return
        self._stack.addContainer(self._definition)
        self._instance = InstanceContainer(container_id="FilamentChangeInstanceContainer")
        self._instance.setDefinition(self._definition.getId())
        self._instance.setMetaDataEntry("setting_version",
                                        self._definition.getMetaDataEntry("setting_version", default=0))
        self._stack.addContainer(self._instance)
        self._stack.propertyChanged.connect(self._onPropertyChanged)

        ContainerRegistry.getInstance().addContainer(self._stack)

        ##  Copy machine name and gcode flavor from global stack so we can use their value in the script stack
        if self._global_container_stack is None or self._instance is None:
            return

        for key in ["machine_gcode_flavor"]:
            self._instance.setProperty(key, "value", self._global_container_stack.getProperty(key, "value"))

        self._current_printer = self._global_container_stack.getId()


    def _onGlobalContainerStackChanged(self) -> None:
        """When the global container stack is changed, swap out the list of active scripts."""
        if self._global_container_stack:
            self._global_container_stack.metaDataChanged.disconnect(self._restoreSettingsFromMetadata)

        self._global_container_stack = Application.getInstance().getGlobalContainerStack()

        if self._global_container_stack:
            self._global_container_stack.metaDataChanged.connect(self._restoreSettingsFromMetadata)
        self._restoreSettingsFromMetadata()


    def _restoreSettingsFromMetadata(self):
        new_stack = self._global_container_stack
        if new_stack is None:
            return
        if not new_stack.getMetaDataEntry(self._metadata_name):  # Missing or empty.
            self.stackChanged.emit() # This *should* generate a stack for us...
            return

        script_string = new_stack.getMetaDataEntry(self._metadata_name)
        for script_str in script_string.split("\n"):  # Newline is used as a delimiter
            if not script_str:  # There's nothing saved... (or a corrupt file caused more than 3 consecutive newlines here).
                continue
            script_str = script_str.replace(r"\\\n", "\n").replace(r"\\\\", "\\\\")  # Unescape escape sequences.
            script_parser = configparser.ConfigParser(interpolation=None)
            script_parser.optionxform = str  # type: ignore  # Don't transform the setting keys as they are case-sensitive.
            try:
                script_parser.read_string(script_str)
            except configparser.Error as e:
                Logger.error("Stored Filament Change settings have syntax errors: {err}".format(err = str(e)))
                continue
            for script_name, settings in script_parser.items():  # There should only be one, really! Otherwise we can't guarantee the order or allow multiple uses of the same script.
                if script_name == "DEFAULT":  # ConfigParser always has a DEFAULT section, but we don't fill it. Ignore this one.
                    continue
                if script_name != "FilamentChangeLE":  # This isn't what we're looking for!
                    Logger.log("e",
                               "FilamentChangeManager pulled an unexpected script name {name} in this global stack.".format(
                                   name=script_name))
                    continue
                self.initialize()
                for setting_key, setting_value in settings.items():  # Put all setting values into the script.
                    if self._instance is not None:
                        self._instance.setProperty(setting_key, "value", setting_value)

        # Ensure that we always force an update
        self.stackChanged.emit()
        self._metadataChanged()


    def _metadataChanged(self) -> None:
        """Property changed: trigger re-slice

        To do this we use the global container stack propertyChanged.
        Re-slicing is necessary for setting changes in this plugin, because the changes
        are applied only once per "fresh" gcode
        """
        global_container_stack = Application.getInstance().getGlobalContainerStack()
        if global_container_stack is not None:
            global_container_stack.propertyChanged.emit(self._metadata_name, "value")


    def _onPropertyChanged(self, key: str, property_name: str) -> None:
        if property_name == "value":
            self.valueChanged.emit()

            # Property changed: trigger reslice
            # To do this we use the global container stack propertyChanged.
            # Re-slicing is necessary for setting changes in this plugin, because the changes
            # are applied only once per "fresh" gcode
            global_container_stack = Application.getInstance().getGlobalContainerStack()
            if global_container_stack is not None:
                global_container_stack.propertyChanged.emit(key, property_name)


    @pyqtSlot()
    def writeSettingsToStack(self) -> None:
        Logger.log("i", "Writing Filament Change settings to the Stack")
        parser = configparser.ConfigParser(interpolation = None)  # We'll encode the script as a config with one section. The section header is the key and its values are the settings.
        parser.optionxform = str  # type: ignore # Don't transform the setting keys as they are case-sensitive.
        script_name = self.getSettingData()["key"]
        parser.add_section(script_name)
        for key in self.getSettingData()["settings"]:
            value = self.getSettingValueByKey(key)
            parser[script_name][key] = str(value)
        serialized = io.StringIO()  # ConfigParser can only write to streams. Fine.
        parser.write(serialized)
        serialized.seek(0)
        script_str = serialized.read()
        script_str = script_str.replace("\\\\", r"\\\\").replace("\n", r"\\\n")  # Escape newlines because configparser sees those as section delimiters.

        script_string = "\n".join(script_str)  # ConfigParser should never output three newlines in a row when serialised, so it's a safe delimiter.

        if self._global_container_stack is None:
            return

        # Ensure we don't get triggered by our own write.
        self._global_container_stack.metaDataChanged.disconnect(self._restoreSettingsFromMetadata)

        if self._metadata_name not in self._global_container_stack.getMetaData():
            self._global_container_stack.setMetaDataEntry(self._metadata_name, "")

        self._global_container_stack.setMetaDataEntry(self._metadata_name, script_string)
        # We do want to listen to other events.
        self._global_container_stack.metaDataChanged.connect(self._restoreSettingsFromMetadata)


    def getSettingData(self) -> Dict[str, Any]:
        setting_data_as_string = self.getSettingDataString()
        setting_data = json.loads(setting_data_as_string, object_pairs_hook = collections.OrderedDict)
        return setting_data


    def getSettingValueByKey(self, key: str) -> Any:
        """Convenience function that retrieves value of a setting from the stack."""

        if self._stack is not None:
            return self._stack.getProperty(key, "value")
        return None


    def getSettingDataString(self):
        return """{
            "name": "Filament Change LE",
            "key": "FilamentChangeLE",
            "metadata": {},
            "version": 2,
            "settings":
            {
                "layer_number":
                {
                    "label": "Layer",
                    "description": "At what layer should color change occur. This will be before the layer starts printing. Specify multiple color changes with a comma.",
                    "unit": "",
                    "type": "str",
                    "default_value": ""
                }
            }
        }"""

    ##
    # Execution of the Filament Change scripting
    ##

    def execute(self, output_device) -> None:
        """Add our Filament Change Layers to the gcode."""

        scene = Application.getInstance().getController().getScene()
        # If the scene does not have a gcode, do nothing
        if not hasattr(scene, "gcode_dict"):
            return
        gcode_dict = getattr(scene, "gcode_dict")
        if not gcode_dict:
            return

        # get gcode list for the active build plate
        active_build_plate_id = CuraApplication.getInstance().getMultiBuildPlateModel().activeBuildPlate
        gcode_list = gcode_dict[active_build_plate_id]
        if not gcode_list:
            return

        if ";FILAMENT_CHANGES" not in gcode_list[0]:
            try:
                gcode_list = self.execute_script(gcode_list)
            except Exception:
                Logger.logException("e", "Exception in Filament Change script.")
            if len(self._script_list):  # Add comment to g-code if any changes were made.
                gcode_list[0] += ";FILAMENT_CHANGES\n"
            gcode_dict[active_build_plate_id] = gcode_list
            setattr(scene, "gcode_dict", gcode_dict)
        else:
            Logger.log("w", "Already added filament changes!")


    def execute_script(self, data: List[str]) -> List[str]:
        """Inserts the filament change g-code at specific layer numbers.

        :param data: A list of layers of g-code.
        :return: A similar list, with filament change commands inserted.
        """
        layer_nums = self.getSettingValueByKey("layer_number") # type: str

        if "pro" in self._current_printer:
            color_change = "M25"
        else:
            color_change = "M600"

        color_change += " ; Generated by FilamentChangeManager\n"

        layer_targets = layer_nums.split(",")
        if len(layer_targets) > 0:
            for layer_num in layer_targets:
                try:
                    layer_num = int(layer_num.strip()) + 1 #Needs +1 because the 1st layer is reserved for start g-code.
                except ValueError: #Layer number is not an integer.
                    continue
                if 0 < layer_num < len(data):
                    data[layer_num] = color_change + data[layer_num]

        return data

    ##
    # Interactables for the tool panel
    ##

    @pyqtProperty(str, notify = stackChanged)
    def currentStackId(self) -> str:
        if self._stack:
            return self._stack.getId()
        return None

    # @pyqtProperty(str, notify = valueChanged)
    # def filamentChangeLayers(self) -> str:
    #     return self.getSettingValueByKey("layer_number")

