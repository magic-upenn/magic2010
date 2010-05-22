cmake_minimum_required(VERSION 2.4.6)
set(CMAKE_BUILD_TYPE Release)
include_directories(${PROJECT_SOURCE_DIR}/code $ENV{MAGIC_DIR}/ipc $ENV{MAGIC_DIR}/components/sbpl/src/sbpl)


# Build executables in the bin directory
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_SOURCE_DIR})


add_executable(gplan global_planner.cpp
      astarpoint.cpp
    raycaster.cpp
    filetransfer.cpp
     $ENV{MAGIC_DIR}/ipc/libipc.a.linux64
     )
target_link_libraries(gplan $ENV{MAGIC_DIR}/components/sbpl/cmake_build/libsbpl.a $ENV{MAGIC_DIR}/ipc/libipc.a.linux64)


add_executable(test_plan test_planner.cpp
    filetransfer.cpp
    generate_map.cpp
     $ENV{MAGIC_DIR}/ipc/libipc.a.linux64
     )
target_link_libraries(test_plan $ENV{MAGIC_DIR}/components/sbpl/cmake_build/libsbpl.a $ENV{MAGIC_DIR}/ipc/libipc.a.linux64)
