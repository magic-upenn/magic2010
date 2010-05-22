cmake_minimum_required(VERSION 2.4.6)
set(CMAKE_BUILD_TYPE Release)
include_directories(${PROJECT_SOURCE_DIR}/code $ENV{MAGIC_DIR}/ipc $ENV{MAGIC_DIR}/components/sbpl/src/sbpl $ENV{MAGIC_DIR}/components/exploration $ENV{MAGIC_DIR}/Common $ENV{MAGIC_DIR}/include)


# Build executables in the bin directory
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_SOURCE_DIR})


add_executable(lattice_planner
               envMagic.cpp
               main.cpp
               )
target_link_libraries(lattice_planner $ENV{MAGIC_DIR}/components/sbpl/cmake_build/libsbpl.a $ENV{MAGIC_DIR}/ipc/libipc.a.linux64)

