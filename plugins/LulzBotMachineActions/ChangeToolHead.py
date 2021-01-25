from cura.MachineAction import MachineAction
from UM.i18n import i18nCatalog
catalog = i18nCatalog("cura")


class ChangeToolHeadMachineAction(MachineAction):
    def __init__(self):
        super().__init__("ChangeToolHead", catalog.i18nc("@action", "Change Tool Head"))
        self._qml_url = "ChangeToolHead.qml"
