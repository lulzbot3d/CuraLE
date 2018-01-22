project(cura NONE)
cmake_minimum_required(VERSION 2.8.12)

set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/
                      ${CMAKE_MODULE_PATH})

include(GNUInstallDirs)

set(URANIUM_DIR "${CMAKE_SOURCE_DIR}/../Uranium" CACHE DIRECTORY "The location of the Uranium repository")
set(URANIUM_SCRIPTS_DIR "${URANIUM_DIR}/scripts" CACHE DIRECTORY "The location of the scripts directory of the Uranium repository")

# Tests
include(CuraTests)

option(CURA_DEBUGMODE "Enable debug dialog and other debug features" OFF)

set(DEB_PACKAGE_TARGET_PLATFORM "default" CACHE STRING "Target OS Platform")

if (NOT MINIMUM_PYTHON_VERSION)
    set(MINIMUM_PYTHON_VERSION 3.5.0)
endif()
set(MINIMUM_PYTHON_VERSION ${MINIMUM_PYTHON_VERSION} CACHE STRING "Minimum Python Version")
if(CURA_DEBUGMODE)
    set(_cura_debugmode "ON")
endif()

set(CURA_VERSION "master" CACHE STRING "Version name of Cura")
set(CURA_BUILDTYPE "" CACHE STRING "Build type of Cura, eg. 'PPA'")
configure_file(${CMAKE_SOURCE_DIR}/cura-lulzbot.desktop.in ${CMAKE_BINARY_DIR}/cura-lulzbot.desktop @ONLY)
configure_file(cura/CuraVersion.py.in CuraVersion.py @ONLY)

if(NOT ${URANIUM_DIR} STREQUAL "")
    set(CMAKE_MODULE_PATH "${URANIUM_DIR}/cmake")
endif()
if(NOT ${URANIUM_SCRIPTS_DIR} STREQUAL "")
    list(APPEND CMAKE_MODULE_PATH ${URANIUM_DIR}/cmake)
    include(UraniumTranslationTools)
    # Extract Strings
    add_custom_target(extract-messages ${URANIUM_SCRIPTS_DIR}/extract-messages ${CMAKE_SOURCE_DIR} cura)
    # Build Translations
    CREATE_TRANSLATION_TARGETS()
endif()

if (NOT BUILD_PYTHON)
    find_package(PythonInterp ${MINIMUM_PYTHON_VERSION} REQUIRED)
endif()

if(NOT PYTHON_SITE_PACKAGES_DIR)
	if(APPLE OR WIN32)
		set(PYTHON_SITE_PACKAGES_DIR lib/python${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}/site-packages
			CACHE STRING "Directory to install Python bindings to")
	else()
		set(PYTHON_SITE_PACKAGES_DIR lib/python${PYTHON_VERSION_MAJOR}/dist-packages
			CACHE STRING "Directory to install Python bindings to")
	endif()
	set(CURA_INSTALL_PLUGINS_PATH lib/cura)
else()
	set(CURA_INSTALL_PLUGINS_PATH ${CMAKE_INSTALL_LIBDIR}/cura)
endif()

install(DIRECTORY resources
        DESTINATION ${CMAKE_INSTALL_DATADIR}/cura)
install(DIRECTORY plugins
        DESTINATION ${CURA_INSTALL_PLUGINS_PATH})

if(NOT APPLE AND NOT WIN32)
  if(DEB_PACKAGE_TARGET_PLATFORM STREQUAL "ubuntu-xenial")
    install(FILES cura_app.py
      DESTINATION ${CMAKE_INSTALL_BINDIR}
      PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
    install(FILES run_cura-lulzbot.sh
      DESTINATION ${CMAKE_INSTALL_BINDIR}
      PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
      RENAME cura-lulzbot)
  else()
    install(FILES cura_app.py
      DESTINATION ${CMAKE_INSTALL_BINDIR}
      PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
      RENAME cura-lulzbot)
  endif()

  install(DIRECTORY cura
    DESTINATION ${PYTHON_SITE_PACKAGES_DIR}
    FILES_MATCHING PATTERN *.py)
  install(FILES ${CMAKE_BINARY_DIR}/CuraVersion.py
    DESTINATION ${PYTHON_SITE_PACKAGES_DIR}/cura)
  install(FILES ${CMAKE_BINARY_DIR}/cura-lulzbot.desktop
    DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)
  install(FILES cura.appdata.xml
    DESTINATION ${CMAKE_INSTALL_DATADIR}/appdata) # "appdata" is changed to "metainfo" in v3.1
  install(FILES cura.sharedmimeinfo
    DESTINATION ${CMAKE_INSTALL_DATADIR}/mime/packages/
    RENAME cura.xml)
  
#  install(FILES ${CMAKE_SOURCE_DIR}/resources/images/cura-icon.png
#    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/128x128/apps/)

else()
    install(FILES cura_app.py
            DESTINATION ${CMAKE_INSTALL_BINDIR}
            PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
    install(DIRECTORY cura
            DESTINATION ${PYTHON_SITE_PACKAGES_DIR}
            FILES_MATCHING PATTERN *.py)
    install(FILES ${CMAKE_BINARY_DIR}/CuraVersion.py
            DESTINATION ${PYTHON_SITE_PACKAGES_DIR}/cura)
endif()

include(CPackConfig.cmake)
