from UM.Settings.Models.InstanceContainersModel import InstanceContainersModel
from UM.Application import Application
from UM.Settings.ContainerRegistry import ContainerRegistry

from typing import Any, List


##  A model that shows a list of currently valid materials.
class MaterialsModel(InstanceContainersModel):
    def __init__(self, parent = None):
        super().__init__(parent)

        ContainerRegistry.getInstance().containerMetaDataChanged.connect(self._onContainerMetaDataChanged)

    ##  Called when the metadata of the container was changed.
    #
    #   This makes sure that we only update when it was a material that changed.
    #
    #   \param container The container whose metadata was changed.
    def _onContainerMetaDataChanged(self, container):
        if container.getMetaDataEntry("type") == "material": #Only need to update if a material was changed.
            self._container_change_timer.start()


    def _fetchInstanceContainers(self):
        results = super()._fetchInstanceContainers()
        if Application.getInstance().getMachineManager().currentCategory != "Experimental":
            for material in results:
                if material.getMetaDataEntry("category", None) == "Experimental":
                    results.remove(material)
        return results

    def _onContainerChanged(self, container):
        if container.getMetaDataEntry("type", "") == "material":
            super()._onContainerChanged(container)


    ##  Group brand together
    def _sortKey(self, item) -> List[Any]:
        result = []
        result.append(item["metadata"]["brand"])
        result.append(item["metadata"]["material"])
        result.append(item["metadata"]["name"])
        result.append(item["metadata"]["color_name"])
        result.append(item["metadata"]["id"])
        result.extend(super()._sortKey(item))
        return result
