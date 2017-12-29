from UM.Extension import Extension

from UM.i18n import i18nCatalog
i18n_catalog = i18nCatalog("LulzBotPredefinedCommands")
import os
from UM.Application import Application
from UM.Preferences import Preferences
from UM.PluginRegistry import PluginRegistry
from UM.Resources import Resources



class ZOffset(Extension):
    def __init__(self):
        super().__init__()

        value = Preferences.getInstance().getValue( "general/disabled_plugins" )
        try:
            file = Resources.getPath(Resources.Preferences, Application.getInstance().getApplicationName() + ".cfg")
            Preferences.getInstance().readFromFile(file)
            value = Preferences.getInstance().getValue( "general/disabled_plugins" )
            if "ZOffset" not in value:
                Application.getInstance().registerPrintMonitorAdditionalCategory("Firmware Settings",os.path.join(os.path.dirname(__file__), "ZOffset.qml"))
        except FileNotFoundError:
            pass


