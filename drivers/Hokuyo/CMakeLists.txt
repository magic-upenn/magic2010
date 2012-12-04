cmake_minimum_required(VERSION 2.4.6)
include($ENV{ROS_ROOT}/core/rosbuild/rosbuild.cmake)

# Set the build type.  Options are:
#  Coverage       : w/ debug symbols, w/o optimization, w/ code-coverage
#  Debug          : w/ debug symbols, w/o optimization
#  Release        : w/o debug symbols, w/ optimization
#  RelWithDebInfo : w/ debug symbols, w/ optimization
#  MinSizeRel     : w/o debug symbols, w/ optimization, stripped binaries
#set(ROS_BUILD_TYPE RelWithDebInfo)

rosbuild_init()

#set the default path for built executables to the "bin" directory
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/bin)
#set the default path for built libraries to the "lib" directory
set(LIBRARY_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/lib)

#uncomment if you have defined messages
#rosbuild_genmsg()
#uncomment if you have defined services
#rosbuild_gensrv()

include_directories(/home/magicbot/Desktop/magic2010/include) #/home/cclinger/Desktop/magic_svn/magic2010/trunk/include) 
#include_directories(/home/magicbot/Desktop/magic2010/common) #/home/cclinger/Desktop/magic_svn/magic2010/trunk/common)

link_directories(/home/magicbot/Desktop/magic2010/lib) #/home/cclinger/Desktop/magic_svn/magic2010/trunk/lib)

#common commands for building c++ executables and libraries
#rosbuild_add_library(${PROJECT_NAME} src/example.cpp)
#target_link_libraries(${PROJECT_NAME} another_library)
#rosbuild_add_boost_directories()
#rosbuild_link_boost(${PROJECT_NAME} thread)
#rosbuild_add_executable(arm_move src/arm.cpp src/arm_move.cpp) #example examples/example.cpp)
#rosbuild_add_executable(close_grippers src/gripper.cpp src/close_grips.cpp)
#rosbuild_add_executable(open_grippers src/gripper.cpp src/open_grips.cpp)
#rosbuild_add_executable(arm_record src/arm.cpp src/arm_record.cpp)
#rosbuild_add_executable(arm_record2 src/arm_record2.cpp)
#rosbuild_add_executable(arm_playback src/arm_playback.cpp)
#rosbuild_add_executable(force_read src/force_read.cpp)
#rosbuild_add_executable(record_arms src/record_arms.cpp)
#rosbuild_add_executable(cancel_arms src/cancel_arms.cpp)
#rosbuild_add_executable(force_read2 src/force_read2.cpp)
#rosbuild_add_executable(record_arms2 src/record_arms2.cpp)
#rosbuild_add_executable(arm_fk src/arm.cpp src/arm_fk.cpp)
#rosbuild_add_executable(arm_tt src/arm_timertest.cpp)
#rosbuild_add_executable(arm_fk_6d src/arm.cpp src/arm_fk_6d.cpp)

#rosbuild_add_library(DynamixelPacket ../../common/dataTypes/DynamixelPacket.c) 

#rosbuild_add_executable(runMicroGateway2ROS ../../common/ErrorMessage.cc ../../common/dataTypes/DynamixelPacket.c ../SerialDevice/SerialDevice.cc MicroGatewayROS.cc runMicroGateway2ROS.cc) 
#../../common/dataTypes/DynamixelPacket.c 

rosbuild_add_executable(runHokuyoROS Hokuyo.cc HokuyoCircular.cc HokuyoCircularHardware.cc runHokuyoROS.cc) #runMicroGateway2ROS MicroGatewayROS.cc runMicroGateway2ROS.cc)

#rosbuild_add_compile_flags(runMicroGateway2ROS ../ErrorMessage.o ../DynamixelController.o)
#rosbuild_add_link_flags(runMicroGateway2ROS ../ErrorMessage.o ../DynamixelController.o)
target_link_libraries(runHokuyoROS ipc SerialDevice db_cxx db) #runMicroGateway2ROS ipc SerialDevice) # DynamixelPacket)


#something added 9-11-12 so that I don't have to create a new package to do something simple in the simulator
#rosbuild_add_executable(simple_move_base src/simple_move_base.cpp)

#target_link_libraries(example ${PROJECT_NAME})
