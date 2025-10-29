# Copyright (c) 2023 Aldo Hoeben / fieldOfView
# The TabbedSettingsPlugin is released under the terms of the AGPLv3 or higher.

import os.path
from typing import Optional

from PyQt6.QtCore import QObject, pyqtSlot

from cura.CuraApplication import CuraApplication
from UM.Extension import Extension
from UM.Logger import Logger


class LulzBotRecommendedSettingsPlugin(QObject, Extension):
    def __init__(self):
        super().__init__()

        self._qml_patcher = None
        CuraApplication.getInstance().engineCreatedSignal.connect(self._onEngineCreated)

        self._visibility_handlers = {}

    def _onEngineCreated(self):
        main_window = CuraApplication.getInstance().getMainWindow()
        if not main_window:
            Logger.log(
                "e", "Could not replace Setting View because there is no main window"
            )
            return

        path = os.path.join(
            os.path.dirname(os.path.abspath(__file__)),
            "resources",
            "qml",
            "SettingsViewPatcher.qml",
        )

        plugin_registry = CuraApplication.getInstance().getPluginRegistry()
        preferences = CuraApplication.getInstance().getPreferences()
        has_sidebar_gui = (
            plugin_registry.getMetaData("SidebarGUIPlugin") != {} and
            preferences._findPreference("sidebargui/expand_legend") is not None and
            not preferences._findPreference("sidebargui/incompatible_and_disabled").getValue()
        )

        self._qml_patcher = CuraApplication.getInstance().createQmlComponent(
            path, {
                "manager": self,
                "withSidebarGUI": has_sidebar_gui
            }
        )
        if not self._qml_patcher:
            Logger.log(
                "w", "Could not create qml components for LulzBotRecommendedSettingsPlugin"
            )
            return

        self._qml_patcher.patch(main_window.contentItem())
