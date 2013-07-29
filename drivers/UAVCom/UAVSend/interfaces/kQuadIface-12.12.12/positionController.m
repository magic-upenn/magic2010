function [trpy, integrals] = positionController(delT, quadPose, target, integrals, attitude)
% this controller is based recieves pose information from April and the IMU
% and uses

%% Gains
Kp_x=1;
Ki_x=0;
Kd_x=0;

Kp_y=1;
Ki_y+0;
Kd_y=0;

Kp_z=1;
Ki_z=0;
Kd_z=0;

%% Variables
x=quadPose(2);
y=quadPose(3);
z=quadPose(4);
yaw=quadPose(5);
xvel = quadrotorPose(6);
yvel = quadrotorPose(7);
zvel = quadrotorPose(8);
xerror = x-target(1);
yerror = y-target(2);
zerror = z-target(3);
xint = integrals(1) + xerror*Ki_x;
yint = integrals(2) + yerror*Ki_y;
zint = integrals(3) + zerror*Ki_z;

%% PID commands

x_command = (Kd_x*xvel) + (Kp_x*xerror) + (xint);
y_command = (Kd_y*yvel) + (Kp_y*yerror) + (yint);
z_command = (Kd_z*zvel) + (Kp_z*zerror) + (zint);
yaw_command = yaw_imu - yaw_april + tar;

