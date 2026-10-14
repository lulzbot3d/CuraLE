# Applied on top of the LulzBot cura.jinja host profile by build_macos_native.sh.
# Keeps version ranges from drifting past what the LulzBot recipes pin
# (ConanCenter has moved on since the 5.11 packages were built).

[settings]
# Deployment target; without it binaries require the build machine's macOS version.
# Matches the oldest macOS supported by the bundled PyQt6 wheels.
os.version=12.0

[buildenv]
MACOSX_DEPLOYMENT_TARGET=12.0
# CPython 3.12.2 calls these unguarded; they exist in the macOS 27 SDK but not on older
# macOS, where os.pipe()/os.dup2() would crash. Hide them from configure.
cpython/*:ac_cv_func_pipe2=no
cpython/*:ac_cv_func_dup3=no

[replace_requires]
# curaengine pins zlib/1.3.1; boost, cpython, openssl, grpc, protobuf use ranges
zlib/*: zlib/1.3.1

[conf]
# Never let CMake pick up Homebrew packages/tools (e.g. a newer grpc_cpp_plugin generates
# code that does not compile against conan's grpc 1.54)
tools.cmake.cmaketoolchain:extra_variables={"CMAKE_IGNORE_PREFIX_PATH": "/opt/homebrew;/usr/local"}
# The macOS 27 SDK declares pipe2(), but it is unavailable on the 12.0 deployment target
# (package-scoped extra_variables replace the global ones, so repeat them)
c-ares/*:tools.cmake.cmaketoolchain:extra_variables={"CMAKE_IGNORE_PREFIX_PATH": "/opt/homebrew;/usr/local", "HAVE_PIPE2": "OFF"}
# range-v3's forward declarations of std::allocator/pair/hash clash with newer libc++
tools.build:defines=["META_NO_STD_FORWARD_DECLARATIONS"]
# apple-clang >= 19 makes this an error; grpc 1.54 trips it in promise/detail/basic_seq.h
grpc/*:tools.build:cxxflags=["-Wno-missing-template-arg-list-after-template-kw"]
