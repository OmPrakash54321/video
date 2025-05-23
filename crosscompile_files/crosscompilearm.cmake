# CMake toolchain file for cross compiling x265 for ARM32 (ARMv7)
# This feature is only supported as experimental. Use with caution.
# Please report bugs on bitbucket
# Run cmake with: cmake -DCMAKE_TOOLCHAIN_FILE=crosscompile.cmake -G "Unix Makefiles" ../../source && ccmake ../../source
message("I'm in------------------------------------------------------")

set(CROSS_COMPILE_ARM32 1)
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)

set(ARM_LINUX ON)

# specify the cross compiler (giving precedence to user-supplied CC/CXX)
if(NOT DEFINED CMAKE_C_COMPILER)
    set(CMAKE_C_COMPILER arm-none-linux-gnueabihf-gcc)
endif()
if(NOT DEFINED CMAKE_CXX_COMPILER)
    set(CMAKE_CXX_COMPILER arm-none-linux-gnueabihf-g++)
endif()

# specify the target environment
SET(CMAKE_FIND_ROOT_PATH  /home/mcw/Downloads/Video/tools_for_qcs/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-linux-gnueabihf/)

# Ensure CMake finds libraries/headers for the target, not the host
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Force static linking
set(BUILD_SHARED_LIBS OFF CACHE BOOL "Disable shared libraries" FORCE)
set(BUILD_STATIC ON CACHE BOOL "Enable static executables" FORCE)

# Add ARMv7 specific compiler flags
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -march=armv7-a -mfloat-abi=hard")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=armv7-a -mfloat-abi=hard")

# Force enable assembly and NEON support
set(ENABLE_ASSEMBLY ON CACHE BOOL "Enable assembly optimizations" FORCE)
set(HAVE_NEON ON CACHE BOOL "Enable NEON optimizations" FORCE)
