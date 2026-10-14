# Native Apple Silicon build (no Rosetta)

The official Cura LulzBot Edition macOS builds are x86_64-only and need Rosetta.
`scripts/build_macos_native.sh` builds a native arm64 `Cura LulzBot Edition.app`
from source. It follows the LulzBot CI macOS installer workflow, but every C++
dependency (CPython, CuraEngine, Arcus, pynest2d, pysavitar, gRPC, ...) is
compiled locally for `armv8`.

## Requirements

- An Apple Silicon Mac with Xcode Command Line Tools (`xcode-select --install`)
- [pixi](https://pixi.sh), which provides conan, cmake, ninja and autotools
- About 10 GB of free disk space for the conan cache (`~/.conan2-curale`)

## Build

```bash
pixi run build-macos          # build the .app only
pixi run build-macos --dmg    # also build an unsigned drag-to-Applications .dmg
```

The first build takes roughly 30–60 minutes. Later builds reuse the conan cache.
Outputs go to `build-macos/dist/`:

- `Cura LulzBot Edition.app`
- `Cura_LulzBot_Edition-<version>-macos-ARM64.dmg` (with `--dmg`)

The app targets macOS 12 or later on arm64.

## Running on another Mac

The app is ad-hoc signed and not notarized. On a Mac that receives it as a
download or over AirDrop, Gatekeeper blocks the first launch. You can either
right-click the app, choose **Open**, then **Open Anyway** in
System Settings → Privacy & Security, or clear the quarantine flag:

```bash
xattr -dr com.apple.quarantine "/Applications/Cura LulzBot Edition.app"
```

## What differs from LulzBot CI

These differences are all in `pixi.toml` and `scripts/macos_native_overrides.profile`:

- **Separate cache:** `CONAN_HOME=~/.conan2-curale` holds LulzBot's conan config,
  so an existing UltiMaker `~/.conan2` setup is left alone.
- **conan 2.20.1:** the `uvula` recipe imports `AutoPackager`, which conan 2.21
  removed.
- **zlib 1.3.1 pinned:** this keeps conan version ranges in line with
  curaengine's pin.
- **Newer apple-clang:** apple-clang ≥ 19 needed two workarounds, one for gRPC 1.54
  (`-Wno-missing-template-arg-list-after-template-kw`) and one for range-v3
  (`META_NO_STD_FORWARD_DECLARATIONS`).
- **No Homebrew:** Homebrew is kept out of CMake's search paths. A newer Homebrew
  `grpc_cpp_plugin` otherwise generates code that does not compile.
- **Deployment target:** `os.version=12.0`. Without it, binaries require the
  macOS version of the machine that built them. For the same reason, `pipe2`
  and `dup3` are hidden from configure for c-ares and CPython: newer SDKs
  declare them, but older macOS releases don't have them.
- **conda-forge mirror:** pixi pulls conda-forge from the prefix.dev mirror.
