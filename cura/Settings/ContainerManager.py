# Copyright (c) 2017 Ultimaker B.V.
# Cura is released under the terms of the LGPLv3 or higher.

import os
import urllib.parse
import uuid
from typing import Any, cast, Dict, List, TYPE_CHECKING, Union

from PyQt5.QtCore import QObject, QUrl, QVariant
from PyQt5.QtWidgets import QMessageBox
from UM.Util import parseBool

from UM.i18n import i18nCatalog
from UM.FlameProfiler import pyqtSlot
from UM.Logger import Logger
from UM.MimeTypeDatabase import MimeTypeDatabase, MimeTypeNotFoundError
from UM.Platform import Platform
from UM.SaveFile import SaveFile
from UM.Settings.ContainerFormatError import ContainerFormatError
from UM.Settings.ContainerRegistry import ContainerRegistry
from UM.Settings.ContainerStack import ContainerStack
from UM.Settings.DefinitionContainer import DefinitionContainer
from UM.Settings.InstanceContainer import InstanceContainer
from cura.QualityManager import QualityManager

import cura.CuraApplication
from cura.Machines.ContainerTree import ContainerTree
from cura.Settings.ExtruderStack import ExtruderStack
from cura.Settings.GlobalStack import GlobalStack

if TYPE_CHECKING:
    from cura.CuraApplication import CuraApplication
    from cura.Machines.ContainerNode import ContainerNode
    from cura.Machines.MaterialNode import MaterialNode
    from cura.Machines.QualityChangesGroup import QualityChangesGroup

catalog = i18nCatalog("cura")

##  Manager class that contains common actions to deal with containers in Cura.
#
#   This is primarily intended as a class to be able to perform certain actions
#   from within QML. We want to be able to trigger things like removing a container
#   when a certain action happens. This can be done through this class.
class ContainerManager(QObject):
    """Manager class that contains common actions to deal with containers in Cura.

    This is primarily intended as a class to be able to perform certain actions
    from within QML. We want to be able to trigger things like removing a container
    when a certain action happens. This can be done through this class.
    """

    ##  Create a duplicate of the specified container
    #
    #   This will create and add a duplicate of the container corresponding
    #   to the container ID.
    #
    #   \param container_id \type{str} The ID of the container to duplicate.
    #
    #   \return The ID of the new container, or an empty string if duplication failed.
    @pyqtSlot(str, result = str)
    def duplicateContainer(self, container_id):
        #TODO: It should be able to duplicate a container of which only the metadata is known.
        containers = self._container_registry.findContainers(id = container_id)
        if not containers:
            Logger.log("w", "Could duplicate container %s because it was not found.", container_id)
            return ""

    def __init__(self, application: "CuraApplication") -> None:
        if ContainerManager.__instance is not None:
            raise RuntimeError("Try to create singleton '%s' more than once" % self.__class__.__name__)
        ContainerManager.__instance = self
        try:
            super().__init__(parent = application)
        except TypeError:
            super().__init__()

        self._container_name_filters = {}  # type: Dict[str, Dict[str, Any]]

    @pyqtSlot(str, str, result=str)
    def getContainerMetaDataEntry(self, container_id: str, entry_names: str) -> str:
        metadatas = cura.CuraApplication.CuraApplication.getInstance().getContainerRegistry().findContainersMetadata(id = container_id)
        if not metadatas:
            Logger.log("w", "Could not get metadata of container %s because it was not found.", container_id)
            return ""

        entries = entry_names.split("/")
        result = metadatas[0]
        while entries:
            entry = entries.pop(0)
            result = result.get(entry, {})
        if not result:
            return ""
        return str(result)

    @pyqtSlot("QVariant", str, str)
    def setContainerMetaDataEntry(self, container_node: "ContainerNode", entry_name: str, entry_value: str) -> bool:
        """Set a metadata entry of the specified container.

        This will set the specified entry of the container's metadata to the specified
        value. Note that entries containing dictionaries can have their entries changed
        by using "/" as a separator. For example, to change an entry "foo" in a
        dictionary entry "bar", you can specify "bar/foo" as entry name.

        :param container_node: :type{ContainerNode}
        :param entry_name: :type{str} The name of the metadata entry to change.
        :param entry_value: The new value of the entry.

        TODO: This is ONLY used by MaterialView for material containers. Maybe refactor this.
        Update: In order for QML to use objects and sub objects, those (sub) objects must all be QObject. Is that what we want?
        """

        if container_node.container is None:
            Logger.log("w", "Container node {0} doesn't have a container.".format(container_node.container_id))
            return False
        root_material_id = container_node.getMetaDataEntry("base_file", "")
        container_registry = cura.CuraApplication.CuraApplication.getInstance().getContainerRegistry()
        if container_registry.isReadOnly(root_material_id):
            Logger.log("w", "Cannot set metadata of read-only container %s.", root_material_id)
            return False
        root_material_query = container_registry.findContainers(id = root_material_id)
        if not root_material_query:
            Logger.log("w", "Unable to find root material: {root_material}.".format(root_material = root_material_id))
            return False
        root_material = root_material_query[0]

        entries = entry_name.split("/")
        entry_name = entries.pop()

        sub_item_changed = False
        if entries:
            root_name = entries.pop(0)
            root = container.getMetaDataEntry(root_name)

            item = root
            for _ in range(len(entries)):
                item = item.get(entries.pop(0), {})

            if item[entry_name] != entry_value:
                sub_item_changed = True
            item[entry_name] = entry_value

            entry_name = root_name
            entry_value = root

        root_material.setMetaDataEntry(entry_name, entry_value)
        if sub_item_changed: #If it was only a sub-item that has changed then the setMetaDataEntry won't correctly notice that something changed, and we must manually signal that the metadata changed.
            root_material.metaDataChanged.emit(root_material)

        cura.CuraApplication.CuraApplication.getInstance().getMachineManager().updateUponMaterialMetadataChange()
        return True

    @pyqtSlot(str, result = str)
    def makeUniqueName(self, original_name: str) -> str:
        return cura.CuraApplication.CuraApplication.getInstance().getContainerRegistry().uniqueName(original_name)

    @pyqtSlot(str, result = "QStringList")
    def getContainerNameFilters(self, type_name: str) -> List[str]:
        """Get a list of string that can be used as name filters for a Qt File Dialog

        This will go through the list of available container types and generate a list of strings
        out of that. The strings are formatted as "description (*.extension)" and can be directly
        passed to a nameFilters property of a Qt File Dialog.

        :param type_name: Which types of containers to list. These types correspond to the "type"
            key of the plugin metadata.

        :return: A string list with name filters.
        """

        return True

    ##  Get a setting property of the specified container.
    #
    #   This will get the specified property of the specified setting of the
    #   specified container.
    #
    #   \param container_id The ID of the container to get the setting property
    #   of.
    #   \param setting_key The key of the setting to get the property of.
    #   \param property_name The property to obtain.
    #   \return The value of the specified property. The type of this property
    #   value depends on the type of the property. For instance, the "value"
    #   property of an integer setting will be a Python int, but the "value"
    #   property of an enum setting will be a Python str.
    @pyqtSlot(str, str, str, result = QVariant)
    def getContainerProperty(self, container_id: str, setting_key: str, property_name: str):
        containers = self._container_registry.findContainers(id = container_id)
        if not containers:
            Logger.log("w", "Could not get properties of container %s because it was not found.", container_id)
            return ""
        container = containers[0]

        return container.getProperty(setting_key, property_name)

    ##  Set the name of the specified container.
    @pyqtSlot(str, str, result = bool)
    def setContainerName(self, container_id, new_name):
        if self._container_registry.isReadOnly(container_id):
            Logger.log("w", "Cannot set name of read-only container %s.", container_id)
            return False

        containers = self._container_registry.findContainers(id = container_id) #We need to get the full container, not just metadata, since we need to know whether it's read-only.
        if not containers:
            Logger.log("w", "Could not set name of container %s because it was not found.", container_id)
            return False

        containers[0].setName(new_name)

        return True

    ##  Find instance containers matching certain criteria.
    #
    #   This effectively forwards to
    #   ContainerRegistry::findInstanceContainersMetadata.
    #
    #   \param criteria A dict of key - value pairs to search for.
    #
    #   \return A list of container IDs that match the given criteria.
    @pyqtSlot("QVariantMap", result = "QVariantList")
    def findInstanceContainers(self, criteria):
        return [entry["id"] for entry in self._container_registry.findInstanceContainersMetadata(**criteria)]

    @pyqtSlot(str, result = bool)
    def isContainerUsed(self, container_id):
        Logger.log("d", "Checking if container %s is currently used", container_id)
        # check if this is a material container. If so, check if any material with the same base is being used by any
        # stacks.
        container_ids_to_check = [container_id]
        container_results = self._container_registry.findInstanceContainersMetadata(id = container_id, type = "material")
        if container_results:
            this_container = container_results[0]
            material_base_file = this_container["id"]
            if "base_file" in this_container:
                material_base_file = this_container["base_file"]
            # check all material container IDs with the same base
            material_containers = self._container_registry.findInstanceContainersMetadata(base_file = material_base_file,
                                                                                  type = "material")
            if material_containers:
                container_ids_to_check = [container["id"] for container in material_containers]

        all_stacks = self._container_registry.findContainerStacks()
        for stack in all_stacks:
            for used_container_id in container_ids_to_check:
                if used_container_id in [child.getId() for child in stack.getContainers()]:
                    Logger.log("d", "The container is in use by %s", stack.getId())
                    return True
        return False

    @pyqtSlot(str, result = str)
    def makeUniqueName(self, original_name):
        return self._container_registry.uniqueName(original_name)

    ##  Get a list of string that can be used as name filters for a Qt File Dialog
    #
    #   This will go through the list of available container types and generate a list of strings
    #   out of that. The strings are formatted as "description (*.extension)" and can be directly
    #   passed to a nameFilters property of a Qt File Dialog.
    #
    #   \param type_name Which types of containers to list. These types correspond to the "type"
    #                    key of the plugin metadata.
    #
    #   \return A string list with name filters.
    @pyqtSlot(str, result = "QStringList")
    def getContainerNameFilters(self, type_name):
        if not self._container_name_filters:
            self._updateContainerNameFilters()

        filters = []
        for filter_string, entry in self._container_name_filters.items():
            if not type_name or entry["type"] == type_name:
                filters.append(filter_string)

        filters.append("All Files (*)")
        return filters

    ##  Export a container to a file
    #
    #   \param container_id The ID of the container to export
    #   \param file_type The type of file to save as. Should be in the form of "description (*.extension, *.ext)"
    #   \param file_url_or_string The URL where to save the file.
    #
    #   \return A dictionary containing a key "status" with a status code and a key "message" with a message
    #           explaining the status.
    #           The status code can be one of "error", "cancelled", "success"
    @pyqtSlot(str, str, QUrl, result = "QVariantMap")
    def exportContainer(self, container_id: str, file_type: str, file_url_or_string: Union[QUrl, str]) -> Dict[str, str]:
        """Export a container to a file

        :param container_id: The ID of the container to export
        :param file_type: The type of file to save as. Should be in the form of "description (*.extension, *.ext)"
        :param file_url_or_string: The URL where to save the file.

        :return: A dictionary containing a key "status" with a status code and a key "message" with a message
        explaining the status. The status code can be one of "error", "cancelled", "success"
        """

        if not container_id or not file_type or not file_url_or_string:
            return {"status": "error", "message": "Invalid arguments"}

        if isinstance(file_url_or_string, QUrl):
            file_url = file_url_or_string.toLocalFile()
        else:
            file_url = file_url_or_string

        if not file_url:
            return {"status": "error", "message": "Invalid path"}

        if file_type not in self._container_name_filters:
            try:
                mime_type = MimeTypeDatabase.getMimeTypeForFile(file_url)
            except MimeTypeNotFoundError:
                return {"status": "error", "message": "Unknown File Type"}
        else:
            mime_type = self._container_name_filters[file_type]["mime"]

        containers = cura.CuraApplication.CuraApplication.getInstance().getContainerRegistry().findContainers(id = container_id)
        if not containers:
            return {"status": "error", "message": "Container not found"}
        container = containers[0]

        if Platform.isOSX() and "." in file_url:
            file_url = file_url[:file_url.rfind(".")]

        for suffix in mime_type.suffixes:
            if file_url.endswith(suffix):
                break
        else:
            file_url += "." + mime_type.preferredSuffix

        if not Platform.isWindows():
            if os.path.exists(file_url):
                result = QMessageBox.question(None, catalog.i18nc("@title:window", "File Already Exists"),
                                              catalog.i18nc("@label Don't translate the XML tag <filename>!", "The file <filename>{0}</filename> already exists. Are you sure you want to overwrite it?").format(file_url))
                if result == QMessageBox.No:
                    return {"status": "cancelled", "message": "User cancelled"}

        try:
            contents = container.serialize()
        except NotImplementedError:
            return {"status": "error", "message": "Unable to serialize container"}

        if contents is None:
            return {"status": "error", "message": "Serialization returned None. Unable to write to file"}

        try:
            with SaveFile(file_url, "w") as f:
                f.write(contents)
        except OSError:
            return {"status": "error", "message": "Unable to write to this location.", "path": file_url}

        Logger.info("Successfully exported container to {path}".format(path = file_url))
        return {"status": "success", "message": "Successfully exported container", "path": file_url}

    ##  Imports a profile from a file
    #
    #   \param file_url A URL that points to the file to import.
    #
    #   \return \type{Dict} dict with a 'status' key containing the string 'success' or 'error', and a 'message' key
    #       containing a message for the user
    @pyqtSlot(QUrl, result = "QVariantMap")
    def importMaterialContainer(self, file_url_or_string: Union[QUrl, str]) -> Dict[str, str]:
        """Imports a profile from a file

        :param file_url: A URL that points to the file to import.

        :return: :type{Dict} dict with a 'status' key containing the string 'success' or 'error', and a 'message' key
            containing a message for the user
        """

        if not file_url_or_string:
            return {"status": "error", "message": "Invalid path"}

        if isinstance(file_url_or_string, QUrl):
            file_url = file_url_or_string.toLocalFile()
        else:
            file_url = file_url_or_string
        Logger.info(f"Importing material from {file_url}")

        if not file_url or not os.path.exists(file_url):
            return {"status": "error", "message": "Invalid path"}

        try:
            mime_type = MimeTypeDatabase.getMimeTypeForFile(file_url)
        except MimeTypeNotFoundError:
            return {"status": "error", "message": "Could not determine mime type of file"}

        container_registry = cura.CuraApplication.CuraApplication.getInstance().getContainerRegistry()
        container_type = container_registry.getContainerForMimeType(mime_type)
        if not container_type:
            return {"status": "error", "message": "Could not find a container to handle the specified file."}
        if not issubclass(container_type, InstanceContainer):
            return {"status": "error", "message": "This is not a material container, but another type of file."}

        container_id = urllib.parse.unquote_plus(mime_type.stripExtension(os.path.basename(file_url)))
        container_id = container_registry.uniqueName(container_id)

        container = container_type(container_id)

        try:
            with open(file_url, "rt", encoding = "utf-8") as f:
                container.deserialize(f.read(), file_url)
        except PermissionError:
            return {"status": "error", "message": "Permission denied when trying to read the file."}
        except ContainerFormatError:
            return {"status": "error", "Message": "The material file appears to be corrupt."}
        except Exception as ex:
            return {"status": "error", "message": str(ex)}

        container.setDirty(True)

        container_registry.addContainer(container)

        return {"status": "success", "message": "Successfully imported container {0}".format(container.getName())}

    ##  Update the current active quality changes container with the settings from the user container.
    #
    #   This will go through the active global stack and all active extruder stacks and merge the changes from the user
    #   container into the quality_changes container. After that, the user container is cleared.
    #
    #   \return \type{bool} True if successful, False if not.
    @pyqtSlot(result = bool)
    def updateQualityChanges(self) -> bool:
        """Update the current active quality changes container with the settings from the user container.

        This will go through the active global stack and all active extruder stacks and merge the changes from the user
        container into the quality_changes container. After that, the user container is cleared.

        :return: :type{bool} True if successful, False if not.
        """

        application = cura.CuraApplication.CuraApplication.getInstance()
        global_stack = application.getMachineManager().activeMachine
        if not global_stack:
            return False

        application.getMachineManager().blurSettings.emit()

        current_quality_changes_name = global_stack.qualityChanges.getName()
        current_quality_type = global_stack.quality.getMetaDataEntry("quality_type")
        extruder_stacks = global_stack.extruderList
        container_registry = cura.CuraApplication.CuraApplication.getInstance().getContainerRegistry()
        machine_definition_id = ContainerTree.getInstance().machines[global_stack.definition.getId()].quality_definition
        for stack in [global_stack] + extruder_stacks:
            # Find the quality_changes container for this stack and merge the contents of the top container into it.
            quality_changes = stack.qualityChanges

            if quality_changes.getId() == "empty_quality_changes":
                quality_changes = InstanceContainer(container_registry.uniqueName((stack.getId() + "_" + current_quality_changes_name).lower().replace(" ", "_")))
                quality_changes.setName(current_quality_changes_name)
                quality_changes.setMetaDataEntry("type", "quality_changes")
                quality_changes.setMetaDataEntry("quality_type", current_quality_type)
                if stack.getMetaDataEntry("position") is not None:  # Extruder stacks.
                    quality_changes.setMetaDataEntry("position", stack.getMetaDataEntry("position"))
                    quality_changes.setMetaDataEntry("intent_category", stack.quality.getMetaDataEntry("intent_category", "default"))
                quality_changes.setMetaDataEntry("setting_version", application.SettingVersion)
                quality_changes.setDefinition(machine_definition_id)
                container_registry.addContainer(quality_changes)
                stack.qualityChanges = quality_changes

            if not quality_changes or container_registry.isReadOnly(quality_changes.getId()):
                Logger.log("e", "Could not update quality of a nonexistent or read only quality profile in stack %s", stack.getId())
                continue

            self._performMerge(quality_changes, stack.getTop())

        cura.CuraApplication.CuraApplication.getInstance().getMachineManager().activeQualityChangesGroupChanged.emit()

        return True

    ##  Clear the top-most (user) containers of the active stacks.
    @pyqtSlot()
    def clearUserContainers(self) -> None:
        """Clear the top-most (user) containers of the active stacks."""

        machine_manager = cura.CuraApplication.CuraApplication.getInstance().getMachineManager()
        machine_manager.blurSettings.emit()

        send_emits_containers = []

        # Go through global and extruder stacks and clear their topmost container (the user settings).
        global_stack = machine_manager.activeMachine
        for stack in [global_stack] + global_stack.extruderList:
            container = stack.userChanges
            container.clear()
            send_emits_containers.append(container)

        # user changes are possibly added to make the current setup match the current enabled extruders
        machine_manager.correctExtruderSettings()

        # The Print Sequence should be changed to match the current setup
        machine_manager.correctPrintSequence()

        for container in send_emits_containers:
            container.sendPostponedEmits()

    @pyqtSlot("QVariant", bool, result = "QStringList")
    def getLinkedMaterials(self, material_node: "MaterialNode", exclude_self: bool = False) -> List[str]:
        """Get a list of materials that have the same GUID as the reference material

        :param material_node: The node representing the material for which to get
            the same GUID.
        :param exclude_self: Whether to include the name of the material you provided.
        :return: A list of names of materials with the same GUID.
        """

        same_guid = ContainerRegistry.getInstance().findInstanceContainersMetadata(GUID = material_node.guid)
        if exclude_self:
            return list({meta["name"] for meta in same_guid if meta["base_file"] != material_node.base_file})
        else:
            return list({meta["name"] for meta in same_guid})

    @pyqtSlot("QVariant")
    def unlinkMaterial(self, material_node: "MaterialNode") -> None:
        """Unlink a material from all other materials by creating a new GUID

        :param material_id: :type{str} the id of the material to create a new GUID for.
        """
        # Get the material group
        if material_node.container is None:  # Failed to lazy-load this container.
            return
        root_material_query = cura.CuraApplication.CuraApplication.getInstance().getContainerRegistry().findInstanceContainers(id = material_node.getMetaDataEntry("base_file", ""))
        if not root_material_query:
            Logger.log("w", "Unable to find material group for %s", material_node)
            return
        root_material = root_material_query[0]

        # Generate a new GUID
        new_guid = str(uuid.uuid4())

        # Update the GUID
        # NOTE: We only need to set the root material container because XmlMaterialProfile.setMetaDataEntry() will
        # take care of the derived containers too
        root_material.setMetaDataEntry("GUID", new_guid)

    def _performMerge(self, merge_into: InstanceContainer, merge: InstanceContainer, clear_settings: bool = True) -> None:
        if merge == merge_into:
            return

        for key in merge.getAllKeys():
            merge_into.setProperty(key, "value", merge.getProperty(key, "value"))

        if clear_settings:
            merge.clear()

    def _updateContainerNameFilters(self) -> None:
        self._container_name_filters = {}
        plugin_registry = cura.CuraApplication.CuraApplication.getInstance().getPluginRegistry()
        container_registry = cura.CuraApplication.CuraApplication.getInstance().getContainerRegistry()
        for plugin_id, container_type in container_registry.getContainerTypes():
            # Ignore default container types since those are not plugins
            if container_type in (InstanceContainer, ContainerStack, DefinitionContainer, GlobalStack, ExtruderStack):
                continue

            serialize_type = ""
            try:
                plugin_metadata = plugin_registry.getMetaData(plugin_id)
                if plugin_metadata:
                    serialize_type = plugin_metadata["settings_container"]["type"]
                else:
                    continue
            except KeyError as e:
                continue

            mime_type = container_registry.getMimeTypeForContainer(container_type)
            if mime_type is None:
                continue
            entry = {
                "type": serialize_type,
                "mime": mime_type,
                "container": container_type
            }

            suffix = mime_type.preferredSuffix
            if Platform.isOSX() and "." in suffix:
                # OSX's File dialog is stupid and does not allow selecting files with a . in its name
                suffix = suffix[suffix.index(".") + 1:]

            suffix_list = "*." + suffix
            for suffix in mime_type.suffixes:
                if suffix == mime_type.preferredSuffix:
                    continue

                if Platform.isOSX() and "." in suffix:
                    # OSX's File dialog is stupid and does not allow selecting files with a . in its name
                    suffix = suffix[suffix.index("."):]

                suffix_list += ", *." + suffix

            name_filter = "{0} ({1})".format(mime_type.comment, suffix_list)
            self._container_name_filters[name_filter] = entry

    @pyqtSlot(QUrl, result = "QVariantMap")
    def importProfile(self, file_url: QUrl) -> Dict[str, str]:
        """Import single profile, file_url does not have to end with curaprofile"""

    ##  Create a quality changes container for a specified quality container.
    #
    #   \param quality_container The quality container to create a changes container for.
    #   \param new_name The name of the new quality_changes container.
    #   \param machine_definition The machine definition this quality changes container is specific to.
    #   \param extruder_id
    #
    #   \return A new quality_changes container with the specified container as base.
    def _createQualityChanges(self, quality_container, new_name, machine_definition, extruder_id):
        base_id = machine_definition.getId() if extruder_id is None else extruder_id

        # Create a new quality_changes container for the quality.
        quality_changes = InstanceContainer(self._createUniqueId(base_id, new_name))
        quality_changes.setName(new_name)
        quality_changes.addMetaDataEntry("type", "quality_changes")
        quality_changes.addMetaDataEntry("quality_type", quality_container.getMetaDataEntry("quality_type"))

        # If we are creating a container for an extruder, ensure we add that to the container
        if extruder_id is not None:
            quality_changes.addMetaDataEntry("extruder", extruder_id)

        # If the machine specifies qualities should be filtered, ensure we match the current criteria.
        if not machine_definition.getMetaDataEntry("has_machine_quality"):
            quality_changes.setDefinition("fdmprinter")
        else:
            quality_changes.setDefinition(QualityManager.getInstance().getParentMachineDefinition(machine_definition).getId())

        from cura.CuraApplication import CuraApplication
        quality_changes.addMetaDataEntry("setting_version", CuraApplication.SettingVersion)
        return quality_changes


    ##  Import profiles from a list of file_urls.
    #   Each QUrl item must end with .curaprofile, or it will not be imported.
    #
    #   \param QVariant<QUrl>, essentially a list with QUrl objects.
    #   \return Dict with keys status, text
    @pyqtSlot("QVariantList", result="QVariantMap")
    def importProfiles(self, file_urls):
        status = "ok"
        results = {"ok": [], "error": []}
        for file_url in file_urls:
            if not file_url.isValid():
                continue
            path = file_url.toLocalFile()
            if not path:
                continue
            if not path.endswith(".curaprofile"):
                continue

            single_result = self._container_registry.importProfile(path)
            if single_result["status"] == "error":
                status = "error"
            results[single_result["status"]].append(single_result["message"])

        return {
            "status": status,
            "message": "\n".join(results["ok"] + results["error"])}

    ##  Import single profile, file_url does not have to end with curaprofile
    @pyqtSlot(QUrl, result="QVariantMap")
    def importProfile(self, file_url):
        if not file_url.isValid():
            return {"status": "error", "message": catalog.i18nc("@info:status", "Invalid file URL:") + " " + str(file_url)}
        path = file_url.toLocalFile()
        if not path:
            return {"status": "error", "message": catalog.i18nc("@info:status", "Invalid file URL:") + " " + str(file_url)}
        return cura.CuraApplication.CuraApplication.getInstance().getContainerRegistry().importProfile(path)

    @pyqtSlot(QObject, QUrl, str)
    def exportQualityChangesGroup(self, quality_changes_group: "QualityChangesGroup", file_url: QUrl, file_type: str) -> None:
        if not file_url.isValid():
            return
        path = file_url.toLocalFile()
        if not path:
            return

        container_registry = cura.CuraApplication.CuraApplication.getInstance().getContainerRegistry()
        container_list = [cast(InstanceContainer, container_registry.findContainers(id = quality_changes_group.metadata_for_global["id"])[0])]  # type: List[InstanceContainer]
        for metadata in quality_changes_group.metadata_per_extruder.values():
            container_list.append(cast(InstanceContainer, container_registry.findContainers(id = metadata["id"])[0]))
        cura.CuraApplication.CuraApplication.getInstance().getContainerRegistry().exportQualityProfile(container_list, path, file_type)

    __instance = None   # type: ContainerManager

    @classmethod
    def getInstance(cls, *args, **kwargs) -> "ContainerManager":
        return cls.__instance
