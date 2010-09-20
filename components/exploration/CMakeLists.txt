cmake_minimum_required(VERSION 2.4.6)
set(CMAKE_BUILD_TYPE debug)
include_directories(${PROJECT_SOURCE_DIR}/code /opt/ros/boxturtle/stacks/motion_planners/sbpl/src/sbpl)


# Build executables in the bin directory
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_SOURCE_DIR})


#add_executable(gplan global_planner.cpp
#      astarpoint.cpp
#    raycaster.cpp
#    filetransfer.cpp
#     ~/svn_tree/research/ipc-3.8.5/lib/Linux-2.6/libipc.a
#     )
#target_link_libraries(gplan sbpl /home/jon/svn_tree/research/ipc-3.8.5/lib/Linux-2.6/libipc.a)

#building just a library. 
add_library(gplan SHARED global_planner.cpp raycaster.cpp filetransfer.cpp )
target_link_libraries(gplan /opt/ros/boxturtle/stacks/motion_planners/sbpl/lib/libsbpl.so boost_thread)

add_executable(magicwrapper magicwrapper.cpp
     /home/jon/svn_tree/research/ipc-3.8.5/lib/Linux-2.6/libipc.a
     /home/jon/svn_tree/research/magic_video/exploration/IPC_version/libgplan.so
     )
target_link_libraries(magicwrapper gplan /home/jon/svn_tree/research/ipc-3.8.5/lib/Linux-2.6/libipc.a )


#add_executable(stest stest.cpp
#    filetransfer.cpp
	#  generate_map.cpp
	#     ~/svn_tree/research/ipc-3.8.5/lib/Linux-2.6/libipc.a
#     )
#target_link_libraries(stest /home/jon/ros/pkgs/motion_planners/sbpl/lib/libsbpl.so gplan)
