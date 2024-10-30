# Copyright (c) 2022 Ultimaker B.V.
# Cura is released under the terms of the LGPLv3 or higher.

# NOTE: This is only being used for translation scripts.

# For MSVC flags, will be ignored on non-Windows OS's and this project in general. Only needed for cura-build-environment.
cmake_policy(SET CMP0091 NEW)
project(curale)
cmake_minimum_required(VERSION 3.18)

include(GNUInstallDirs)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

set(URANIUMLE_DIR "${CMAKE_SOURCE_DIR}/../UraniumLE" CACHE PATH "The location of the UraniumLE repository")
set(URANIUMLE_SCRIPTS_DIR "${URANIUMLE_DIR}/scripts" CACHE PATH "The location of the scripts directory of the UraniumLE repository")

option(GENERATE_TRANSLATIONS "Should the translations be generated?" ON)

if(NOT ${URANIUMLE_DIR} STREQUAL "")
    set(CMAKE_MODULE_PATH "${URANIUMLE_DIR}/cmake")
endif()
if(NOT ${URANIUMLE_SCRIPTS_DIR} STREQUAL "")
    list(APPEND CMAKE_MODULE_PATH ${URANIUMLE_DIR}/cmake)
    include(UraniumTranslationTools)
    # Extract Strings
    add_custom_target(extract-messages ${URANIUMLE_SCRIPTS_DIR}/extract-messages ${CMAKE_SOURCE_DIR} curale)
    # Build Translations
    if(${GENERATE_TRANSLATIONS})
        CREATE_TRANSLATION_TARGETS()
    endif()
endif()
