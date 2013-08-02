function [trpy, integrals] = positionController(delT, quadPose, target, integrals, imu_rpy, imu_w_rpy)
    % this controller is based recieves pose information from April and the IMU
    % and uses
    
    %% Gains
    %may have to adjust gains depending on flight mode
    Kp_x=1;
    Ki_x=0;
    Kd_x=0;
    
    Kp_y=1;
    Ki_y=0;
    Kd_y=0;
    
    Kp_z=20;
    Ki_z=0;
    Kd_z=0;
    
    Kp_yaw=1;
    Ki_yaw=0;
    Kd_yaw=0;
    
    %% Variables
    x=quadPose(2);
    y=quadPose(3);
    z=quadPose(4);
    %fprintf('x=%f y=%f z=%f\n',x,y,z);
    yaw_imu = imu_rpy(3);
    yaw_april=quadPose(5);
    xvel = quadPose(6);
    yvel = quadPose(7);
    zvel = quadPose(8);
    yawvel = imu_w_rpy(3);
    xerror = target(1)-x;
    yerror = target(2)-y;
    zerror = target(3)-z;
    yawerror = yaw_april-target(4);%(yaw_april-yaw_imu)-target(4);
    xint = integrals(1) + xerror*Ki_x;
    yint = integrals(2) + yerror*Ki_y;
    zint = integrals(3) + zerror*Ki_z;
    yawint = integrals(4) + yawerror*Ki_yaw;
    
    z_offset = 180;
    
    %% PID commands
    x_command = (Kd_x*xvel) + (Kp_x*xerror) + (xint);
    y_command = (Kd_y*yvel) + (Kp_y*yerror) + (yint);
    z_command = (Kd_z*zvel) + (Kp_z*zerror) + (zint) + z_offset;
    if z_command<20 %prevent division by zero
        z_command = 20;
    end
    yaw_command = (Kd_yaw*yawvel) + (Kp_yaw*yawerror) + (yawint);
    %fprintf('xc = %f, yc=%f zc=%f yawc=%f\n', x_command, y_command, z_command, yaw_command);
    %fprintf('x = %f, xerror= %f, xvel = %f, xp = %f, xd = %f, xi = %f\n',x,xerror, xvel, Kp_x*xerror, Kd_x*xvel, xint);
    
    %% Convert PID commands to trpy
    thrust = sqrt(x_command^2 + y_command^2 + z_command^2); % must calibrate so that when error is zero thrust = weight of quad
    roll_world = atan(y_command/z_command);
    pitch_world = atan(x_command/z_command);
    %tranlate world roll and pitch to quad roll and pitch
    roll = roll_world*cos(-yaw_april)-pitch_world*sin(-yaw_april);
    pitch = roll_world*sin(-yaw_april)+pitch_world*cos(-yaw_april);
    
    yaw = yaw_command;
    
    %% Update and Limit the Intragrals
    max_ints = [30 30 20 0]; %x,y,z,yaw
    min_ints = [-30 -30 -20 0];
    
    integrals = [xint, yint, zint, yawint];
    integrals = max(min(integrals, max_ints), min_ints);
    
    %% Limit the the commands to the quad rotor
    % -pi/2<p,r<pi/2     yaw has no limit really 
    max_r=0.3; %radians
    max_p=0.3; %radians
    max_t=300; %max lift of nano+ is 350 grams
    min_r=-0.3;
    min_p=-0.3;
    min_t=50; %this number must correspond to the thrust value for fastest fall of UAV
    
    tpr = max(min([thrust pitch roll], [max_t max_p max_r]), [min_t min_p min_r]);
    thrust = tpr(1);
    pitch = tpr(2);
    roll = tpr(3);
    
    trpy = [thrust roll pitch yaw];
    
    