magic2010
=========

Installation instructions for Linux machines:

1) Go into the magic2010/ipc

2) make a softlink of the ipc library in accordance to your system architecture

    > sudo ln -s libipc.a.(ARCH) libipc.a
3) install MATLAB (earliest 2007a, latest 2012b)

4) Enter directory where MATLAB is installed (usually /usr/local/MATLAB)

5) remove libstdc++.so.6 in sys/os/glnx(ARCH)/

6) make a softlink of system standard c++ library to this directory (usually in /usr/lib/(ARCH)-linux-gnu/)

    > sudo ln -s $(PATH_TO_SYSTEM_C++_LIB)/libstdc++.so $(PATH_TO_MATLAB)/sys/os/glnx(ARCH)/libstdc__.so.6
7) Go into magic2010 directory

8) run install.sh

Project Description:
--------------------

This git repository consists of code for the UAV-UGV collaborative robotics system project. The system integrates the SLAM algorithm in the multi-autonomous ground robotics system with a UAV system used to constrain local maps in a global coordinate system. The UAVs use the AprilTags fiducial marker system to determine full 6-DOF localization of the ground robots in order to create the map constraints. The UAVs also use this system for flight control.

Simple Directory Description:
-----------------------------
> drivers/

Contains all hardware and software drivers for ground robots, UAV communication, and vision.


> ipc/

Consists of the Carnegie Mellon University IPC package as well as wrappers for use in MATLAB.


> components/

Contains major components to SLAM algorithm and path planning

> scripts/

Contains scripts to run central, necessary hardware drivers, and software drivers.
