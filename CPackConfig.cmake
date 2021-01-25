# Create the version-related variables
# These can optionally be overridden from the build enviroment.
unset(CURA_MAJOR_VERSION CACHE)
if(DEFINED ENV{CURA_MAJOR_VERSION})
    set(CURA_MAJOR_VERSION $ENV{CURA_MAJOR_VERSION} CACHE STRING "Cura Major Version" FORCE)
else()
    set(CURA_MAJOR_VERSION "2" CACHE STRING "Cura Major Version")
endif()
unset(CURA_MINOR_VERSION CACHE)
if(DEFINED ENV{CURA_MINOR_VERSION})
    set(CURA_MINOR_VERSION $ENV{CURA_MINOR_VERSION} CACHE STRING "Cura Minor Version" FORCE)
else()
    set(CURA_MINOR_VERSION "5" CACHE STRING "Cura Minor Version")
endif()
unset(CURA_PATCH_VERSION CACHE)
if(DEFINED ENV{CURA_PATCH_VERSION})
    set(CURA_PATCH_VERSION $ENV{CURA_PATCH_VERSION} CACHE STRING "Cura Patch Version" FORCE)
else()
    set(CURA_PATCH_VERSION "10" CACHE STRING "Cura Patch Version")
endif()
unset(CURA_EXTRA_VERSION CACHE)
if(DEFINED ENV{CURA_EXTRA_VERSION})
    set(CURA_EXTRA_VERSION $ENV{CURA_EXTRA_VERSION} CACHE STRING "Cura Extra Version Information" FORCE)
else()
    set(CURA_EXTRA_VERSION "${CURA_TAG_OR_BRANCH}" CACHE STRING "Cura Extra Version Information")
endif()

set(CURA_VERSION "${CURA_MAJOR_VERSION}.${CURA_MINOR_VERSION}.${CURA_PATCH_VERSION}")
if(NOT "${CURA_EXTRA_VERSION}" STREQUAL "")
    set(CURA_VERSION "${CURA_VERSION}-${CURA_EXTRA_VERSION}")
endif()



set(MINIMUM_ARCUS_VERSION "15.05.90" CACHE STRING "Minimum Arcus Version")
set(MINIMUM_SAVITAR_VERSION "15.05.91" CACHE STRING "Minimum Savitar Version")
set(MINIMUM_URANIUM_VERSION "15.05.93" CACHE STRING "Minimum Uranium Version")
set(MINIMUM_CURAENGINE_VERSION "15.05.90" CACHE STRING "Minimum Cura Engine Version")

set(DEB_PACKAGE_TARGET_PLATFORM "debian-stretch" CACHE STRING "Target Debian/Ubuntu platform")



message("CPACK_PACKAGE_VERSION_MAJOR ${CURA_MAJOR_VERSION}")
message("CPACK_PACKAGE_VERSION_MINOR ${CURA_MINOR_VERSION}")
message("CPACK_PACKAGE_VERSION_PATCH ${CURA_PATCH_VERSION}")

set(CPACK_PACKAGE_NAME "cura-lulzbot")
set(CPACK_PACKAGE_VENDOR "Ultimaker")
#set(CPACK_PACKAGE_VERSION_MAJOR ${CURA_MAJOR_VERSION})
#set(CPACK_PACKAGE_VERSION_MINOR ${CURA_MINOR_VERSION})
#set(CPACK_PACKAGE_VERSION_PATCH ${CURA_PATCH_VERSION})
set(CPACK_PACKAGE_VERSION ${CURA_VERSION} CACHE STRING "Cura LulzBot Edition package version")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Cura LulzBot Edition 3D Printing Software")
set(CPACK_PACKAGE_CONTACT "LulzBot <info@lulzbot.com>")
if(NOT BUILD_OS_OSX)
    set(CPACK_RESOURCE_FILE_LICENSE ${CMAKE_SOURCE_DIR}/LICENSE)
endif()
set(CPACK_PACKAGE_EXECUTABLES cura-lulzbot "cura-lulzbot ${CURA_MAJOR_VERSION}.${CURA_MINOR_VERSION}.${CURA_PATCH_VERSION}")
set(CPACK_PACKAGE_INSTALL_DIRECTORY "cura-lulzbot ${CURA_MAJOR_VERSION}.${CURA_MINOR_VERSION}")

set(RPM_REQUIRES
    "python3 >= ${MINIMUM_PYTHON_VERSION}"
    "python3-qt5 >= 5.4.0"
    "python3-numpy >= 1.9.0"
    "qt5-qtquickcontrols >= 5.4.0"
)
string(REPLACE ";" "," RPM_REQUIRES "${RPM_REQUIRES}")
set(CPACK_RPM_PACKAGE_REQUIRES ${RPM_REQUIRES})
set(CPACK_RPM_PACKAGE_RELOCATABLE OFF)

if(DEB_PACKAGE_TARGET_PLATFORM STREQUAL "ubuntu-xenial")
  set(DEB_DEPENDS
    "python3 (>= ${MINIMUM_PYTHON_VERSION})"
    "python3-numpy"
    "python3-scipy"
    "libgfortran3"
    "cura-lulzbot-python3.5-deps (>=0.1.0)"
    "arcus (>= ${MINIMUM_ARCUS_VERSION})"
    "savitar (>= ${MINIMUM_SAVITAR_VERSION})"
    "uranium (>= ${MINIMUM_URANIUM_VERSION})"
    "curaengine (>= ${MINIMUM_CURAENGINE_VERSION})"
  )
else()
  set(DEB_DEPENDS
    "python3 (>= ${MINIMUM_PYTHON_VERSION})"
    "python3-numpy"
    "python3-scipy"
    "libgfortran3"
    "qml-module-qt-labs-folderlistmodel (>= 5.6.0)"
    "qml-module-qt-labs-settings (>= 5.6.0)"
    "arcus (>= ${MINIMUM_ARCUS_VERSION})"
    "savitar (>= ${MINIMUM_SAVITAR_VERSION})"
    "uranium (>= ${MINIMUM_URANIUM_VERSION})"
    "curaengine (>= ${MINIMUM_CURAENGINE_VERSION})"
  )
endif()
string(REPLACE ";" "," DEB_DEPENDS "${DEB_DEPENDS}")
set(CPACK_DEBIAN_PACKAGE_DEPENDS ${DEB_DEPENDS})
set(CPACK_DEBIAN_PACKAGE_RECOMMENDS
  "cura-binary-data-all (>=1.0.0)"
  "cura-binary-data-lulzbot (>=1.0.0)"
  "cura-binary-data-ultimaker (>=1.0.0)"
  "ultimaker (>=1.0.0)"
  "doodle3d (>=1.0.0)")
string(REPLACE ";" "," CPACK_DEBIAN_PACKAGE_RECOMMENDS "${CPACK_DEBIAN_PACKAGE_RECOMMENDS}")
set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE amd64)

# Set the right epoch so Debian knows this is a more recent version
#set(CPACK_DEBIAN_PACKAGE_VERSION "2:${CPACK_PACKAGE_VERSION}")

set(CPACK_NSIS_ENABLE_UNINSTALL_BEFORE_INSTALL ON)
set(CPACK_NSIS_EXECUTABLES_DIRECTORY ".")
set(CPACK_NSIS_MUI_FINISHPAGE_RUN "cura-lulzbot.exe")
set(CPACK_NSIS_MENU_LINKS
    "https://ultimaker.com/en/support/software" "Cura Online Documentation"
    "https://github.com/ultimaker/cura" "Cura Development Resources"
)

set(CPACK_NSIS_PACKAGE_ARCHITECTURE "64")

set(CPACK_GENERATOR "DEB")

include(CPack)
