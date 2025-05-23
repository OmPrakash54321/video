# CMake toolchain file for cross compiling x265 for aarch64
# This feature is only supported as experimental. Use with caution.
# Please report bugs on bitbucket
# Run cmake with: cmake -DCMAKE_TOOLCHAIN_FILE=crosscompile.cmake -G "Unix Makefiles" ../../source && ccmake ../../source

set(CROSS_COMPILE_ARM64 1)
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# Define ARM64_LINUX for this target
set(ARM64_LINUX ON)

set(STATIC_LIB ON)

# specify the cross compiler (giving precedence to user-supplied CC/CXX)
if(NOT DEFINED CMAKE_C_COMPILER)
    set(CMAKE_C_COMPILER aarch64-none-linux-gnu-gcc)
endif()
if(NOT DEFINED CMAKE_CXX_COMPILER)
    set(CMAKE_CXX_COMPILER aarch64-none-linux-gnu-g++)
endif()

# specify the target environment
SET(CMAKE_FIND_ROOT_PATH  /home/mcw/Downloads/Video/tools_for_qcs/arm-gnu-toolchain-14.2.rel1-x86_64-aarch64-none-linux-gnu/)

# Ensure CMake finds libraries/headers for the target, not the host
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Force static linking
set(BUILD_SHARED_LIBS OFF CACHE BOOL "Disable shared libraries" FORCE)
set(BUILD_STATIC ON CACHE BOOL "Enable static executables" FORCE)

# Add NEON compiler flags
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -march=armv8-a -mfpu=neon")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=armv8-a -mfpu=neon")

# Force enable assembly and NEON support
set(ENABLE_ASSEMBLY ON CACHE BOOL "Enable assembly optimizations" FORCE)
set(HAVE_NEON ON CACHE BOOL "Enable NEON optimizations" FORCE)