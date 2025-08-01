# Copyright (c) 2020 Ultimaker B.V.
# Cura is released under the terms of the LGPLv3 or higher.

from unittest.mock import MagicMock
import configparser  # To read the profiles.
import os
import os.path
import pytest

from UM.FastConfigParser import FastConfigParser
from cura.CuraApplication import CuraApplication  # To compare against the current SettingVersion.
from UM.Settings.DefinitionContainer import DefinitionContainer
from UM.Settings.InstanceContainer import InstanceContainer
from UM.VersionUpgradeManager import VersionUpgradeManager


def collectAllQualities():
    result = []
    for root, directories, filenames in os.walk(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "resources", "quality"))):
        for filename in filenames:
            if ".md" not in filename:
                result.append(os.path.join(root, filename))
    return result


def collectAllDefinitionIds():
    result = []
    for root, directories, filenames in os.walk(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "resources", "definitions"))):
        for filename in filenames:
            if ".md" not in filename:
                result.append(os.path.basename(filename).split(".")[0])
    return result


def collectAllSettingIds():
    VersionUpgradeManager._VersionUpgradeManager__instance = VersionUpgradeManager(MagicMock())

    CuraApplication._initializeSettingDefinitions()

    definition_container = DefinitionContainer("whatever")
    with open(os.path.join(os.path.dirname(__file__), "..", "..", "resources", "definitions", "fdmprinter.def.json"), encoding = "utf-8") as data:
        definition_container.deserialize(data.read())

    lulz_container = DefinitionContainer("lulz")
    with open(os.path.join(os.path.dirname(__file__), "..", "..", "resources", "definitions", "lulzbot_base.def.json"), encoding = "utf-8") as lulzy_data:
        lulz_container.deserialize(lulzy_data.read())

    key_set = definition_container.getAllKeys()
    lulz_set = lulz_container.getAllKeys()

    key_set.update(lulz_set)

    return key_set


def collectAllVariants():
    result = []
    for root, directories, filenames in os.walk(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "resources", "variants"))):
        for filename in filenames:
            if ".md" not in filename:
                result.append(os.path.join(root, filename))
    return result


def collectAllIntents():
    result = []
    for root, directories, filenames in os.walk(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "resources", "intent"))):
        for filename in filenames:
            if ".md" not in filename:
                result.append(os.path.join(root, filename))
    return result

all_definition_ids = collectAllDefinitionIds()
quality_filepaths = collectAllQualities()
all_setting_ids = collectAllSettingIds()
variant_filepaths = collectAllVariants()
intent_filepaths = collectAllIntents()


def test_uniqueID():
    """Check if the ID's from the qualities, variants & intents are unique."""

    all_paths = quality_filepaths + variant_filepaths + intent_filepaths
    all_ids = {}
    for path in all_paths:
        profile_id = os.path.basename(path)
        profile_id = profile_id.replace(".inst.cfg", "")
        if profile_id not in all_ids:
            all_ids[profile_id] = []
        all_ids[profile_id].append(path)

    duplicated_ids_with_paths = {profile_id: paths for profile_id, paths in all_ids.items() if len(paths) > 1}
    if len(duplicated_ids_with_paths.keys()) == 0:
        return  # No issues!

    assert False, "Duplicate profile ID's were detected! Ensure that every profile ID is unique: %s" % duplicated_ids_with_paths


@pytest.mark.parametrize("file_name", quality_filepaths)
def test_validateQualityProfiles(file_name):
    """Attempt to load all the quality profiles."""

    try:
        with open(file_name, encoding = "utf-8") as data:
            serialized = data.read()
            result = InstanceContainer._readAndValidateSerialized(serialized)
            # Fairly obvious, but all the types here should be of the type quality
            assert InstanceContainer.getConfigurationTypeFromSerialized(serialized) == "quality"
            # All quality profiles must be linked to an existing definition.
            assert result["general"]["definition"] in all_definition_ids, "The quality profile %s links to an unknown definition (%s)" % (file_name, result["general"]["definition"])

            # We don't care what the value is, as long as it's there.
            assert result["metadata"].get("quality_type", None) is not None

    except Exception as e:
        # File can't be read, header sections missing, whatever the case, this shouldn't happen!
        assert False, f"Got an Exception while reading the file [{file_name}]: {e}"


@pytest.mark.parametrize("file_name", intent_filepaths)
def test_validateIntentProfiles(file_name):
    try:
        with open(file_name, encoding = "utf-8") as f:
            serialized = f.read()
            result = InstanceContainer._readAndValidateSerialized(serialized)
            assert InstanceContainer.getConfigurationTypeFromSerialized(serialized) == "intent", "The intent folder must only contain intent profiles."
            assert result["general"]["definition"] in all_definition_ids, "The definition for this intent profile must exist."
            assert result["metadata"].get("intent_category", None) is not None, "All intent profiles must have some intent category."
            assert result["metadata"].get("quality_type", None) is not None, "All intent profiles must be linked to some quality type."
            assert result["metadata"].get("material", None) is not None, "All intent profiles must be linked to some material."
            assert result["metadata"].get("variant", None) is not None, "All intent profiles must be linked to some variant."

    except Exception as e:
        # File can't be read, header sections missing, whatever the case, this shouldn't happen!
        assert False, "Got an exception while reading the file {file_name}: {err}".format(file_name = file_name, err = str(e))


@pytest.mark.parametrize("file_name", variant_filepaths)
def test_validateVariantProfiles(file_name):
    """Attempt to load all the variant profiles."""

    try:
        with open(file_name, encoding = "utf-8") as data:
            serialized = data.read()
            result = InstanceContainer._readAndValidateSerialized(serialized)
            # Fairly obvious, but all the types here should be of the type quality
            assert InstanceContainer.getConfigurationTypeFromSerialized(serialized) == "variant", "The profile %s should be of type variant, but isn't" % file_name

            # All quality profiles must be linked to an existing definition.
            assert result["general"]["definition"] in all_definition_ids, "The profile %s isn't associated with a definition" % file_name

            # Check that all the values that we say something about are known.
            if "values" in result:
                variant_setting_keys = set(result["values"])
                # Prune all the comments from the values
                variant_setting_keys = {key for key in variant_setting_keys if not key.startswith("#")}

                has_unknown_settings = not variant_setting_keys.issubset(all_setting_ids)
                if has_unknown_settings:
                    assert False, "The following setting(s) %s are defined in the variant %s, but not in fdmprinter.def.json" % ([key for key in variant_setting_keys if key not in all_setting_ids], file_name)
    except Exception as e:
        # File can't be read, header sections missing, whatever the case, this shouldn't happen!
        assert False, "Got an exception while reading the file {file_name}: {err}".format(file_name = file_name, err = str(e))


@pytest.mark.parametrize("file_name", quality_filepaths + variant_filepaths + intent_filepaths)
def test_versionUpToDate(file_name):
    try:
        with open(file_name, encoding = "utf-8") as data:
            parser = FastConfigParser(data.read())

            assert "general" in parser
            assert "version" in parser["general"]
            assert int(parser["general"]["version"]) == InstanceContainer.Version, "The version of this profile is not up to date!"

            assert "metadata" in parser
            assert "setting_version" in parser["metadata"]
            assert int(parser["metadata"]["setting_version"]) == CuraApplication.SettingVersion, "The version of this profile is not up to date!"
    except Exception as e:
        # File can't be read, header sections missing, whatever the case, this shouldn't happen!
        assert False, "Got an exception while reading the file {file_name}: {err}".format(file_name = file_name, err = str(e))