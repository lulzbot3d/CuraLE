#!/usr/bin/env bash
# Build a native arm64 "Cura LulzBot Edition.app" (no Rosetta) on Apple Silicon.
#
# Mirrors the LulzBot CI macOS installer workflow (lulzbot3d/CuraLE_Workflows,
# cura-installer-macos.yml) but compiles every C++ dependency locally for armv8.
# Run through pixi so conan/ninja/cmake/autotools are available:
#
#   pixi run build-macos            # build the .app
#   pixi run build-macos --dmg      # also create an (unsigned) .dmg
#
# Outputs land in build-macos/dist/. Set CODESIGN_IDENTITY to sign the dmg.
set -euo pipefail

CONAN_CONFIG_URL="https://github.com/lulzbot3d/Conan_LulzBot_Config.git"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${REPO_ROOT}/build-macos"
INST_DIR="${BUILD_DIR}/cura_inst"
VENV_DIR="${BUILD_DIR}/installer_venv"
DIST_DIR="${BUILD_DIR}/dist"
BUILD_DMG=false

for arg in "$@"; do
    case "${arg}" in
        --dmg) BUILD_DMG=true ;;
        *)
            echo "Unknown argument: ${arg} (supported: --dmg)" >&2
            exit 1
            ;;
    esac
done

if [[ "$(uname -s)" != "Darwin" || "$(uname -m)" != "arm64" ]]; then
    echo "This script builds a native Apple Silicon app; run it on arm64 macOS (not under Rosetta)." >&2
    exit 1
fi

if [[ -z "${CONAN_HOME:-}" ]]; then
    echo "CONAN_HOME is not set; run via 'pixi run build-macos' so the LulzBot conan cache stays separate from ~/.conan2." >&2
    exit 1
fi

# LulzBot conan config: remotes (artifacts.lulzbot.com), profiles, VirtualPythonEnv generator
if ! conan remote list 2>/dev/null | grep --quiet "cura-le-conan2"; then
    conan config install "${CONAN_CONFIG_URL}"
fi
# Newer Xcode/CLT apple-clang releases are not yet listed in conan's settings.yml
if [[ ! -f "${CONAN_HOME}/settings_user.yml" ]]; then
    cat >"${CONAN_HOME}/settings_user.yml" <<'EOF'
compiler:
  apple-clang:
    version: ["18", "18.0", "19", "19.0", "20", "20.0", "21", "21.0", "22", "22.0"]
EOF
fi
if [[ ! -f "${CONAN_HOME}/profiles/default" ]]; then
    conan profile detect --name default
fi

# Keep Homebrew tools out of the build: conan's grpc falls back to its own grpc_cpp_plugin
# only if none is on PATH, and a newer Homebrew grpc generates incompatible code.
# pixi provides everything else that is needed (cmake, ninja, autotools).
PATH="$(tr ':' '\n' <<<"${PATH}" | grep --invert-match --extended-regexp '^/(opt/homebrew|usr/local)/' | paste -s -d ':' -)"
export PATH

cd "${REPO_ROOT}"
version="$(python -c "import yaml; print(yaml.safe_load(open('conandata.yml'))['version'])")"

# Use the recipe from this checkout rather than the one on the remote
conan export .

# Builds all missing binaries (CPython, CuraEngine, pynest2d, pysavitar, ...) for armv8
# and deploys everything pyinstaller needs into ${INST_DIR}
conan install --requires "curale/${version}" \
    --build=missing \
    --output-folder "${INST_DIR}" \
    --deployer-package="*" \
    --profile:host cura.jinja \
    --profile:host "${REPO_ROOT}/scripts/macos_native_overrides.profile" \
    --options "curale/*:skip_licenses_download=True"

# Everything below runs on the conan-built (arm64) CPython, as in CI.
# The generated env scripts reference unset variables, so relax -u while sourcing.
set +u
# shellcheck disable=SC1091
source "${INST_DIR}/conanrun.sh"
set -u
python -c "import platform, sys; assert platform.machine() == 'arm64', f'{sys.executable} is {platform.machine()}, expected arm64'"

python -m venv --clear "${VENV_DIR}"
set +u
# shellcheck disable=SC1091
source "${VENV_DIR}/bin/activate"
set -u
for requirements in "${INST_DIR}"/packaging/pip_requirements_{core,installer}_*.txt; do
    pip install --requirement "${requirements}"
done

plutil -convert xml1 "${INST_DIR}/packaging/MacOS/cura.entitlements"
# Run outside the source tree so pyinstaller bundles the deployed cura package
# (with the generated CuraVersion.py) instead of ./cura from this checkout
cd "${BUILD_DIR}"
pyinstaller --noconfirm --distpath "${DIST_DIR}" --workpath "${BUILD_DIR}/pyinstaller_work" \
    "${INST_DIR}/CuraLE.spec"

app_path="$(find "${DIST_DIR}" -maxdepth 1 -name "*.app" -print -quit)"
echo "Built: ${app_path}"
file "${app_path}/Contents/MacOS/"*

# Plain drag-to-Applications dmg via hdiutil (CI's build_macos.py needs Homebrew create-dmg)
if [[ "${BUILD_DMG}" == true ]]; then
    staging_dir="${BUILD_DIR}/dmg_staging"
    dmg_path="${DIST_DIR}/Cura_LulzBot_Edition-${version}-macos-ARM64.dmg"
    rm -rf "${staging_dir}" "${dmg_path}"
    mkdir -p "${staging_dir}"
    cp -R "${app_path}" "${staging_dir}/"
    ln -s /Applications "${staging_dir}/Applications"
    hdiutil create -volname "Cura LulzBot Edition ${version}" -srcfolder "${staging_dir}" \
        -fs HFS+ -format UDZO -ov "${dmg_path}"
    rm -rf "${staging_dir}"
    echo "Built: ${dmg_path}"
fi
