# Copyright (c) 2023 Aldo Hoeben / fieldOfView
# The TabbedSettingsPlugin is released under the terms of the AGPLv3 or higher.

import os
import json

from UM.Version import Version
from UM.Application import Application
from UM.Logger import Logger

from . import LulzBotRecommendedSettingsPlugin


def getMetaData():
    return {}


def register(app):
    return {"extension": LulzBotRecommendedSettingsPlugin.LulzBotRecommendedSettingsPlugin()}
