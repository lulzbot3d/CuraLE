from UM.Settings.Models.InstanceContainersModel import InstanceContainersModel
from UM.Application import Application


class MaterialsModel(InstanceContainersModel):
    def _fetchInstanceContainers(self):
        results = super()._fetchInstanceContainers()
        if Application.getInstance().getMachineManager().currentCategory == "All":
            for material in results:
                if material.getMetaDataEntry("category", None) == "Experimental":
                    results.remove(material)
        return results