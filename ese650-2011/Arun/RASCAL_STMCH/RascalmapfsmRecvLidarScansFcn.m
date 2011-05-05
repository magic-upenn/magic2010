function RascalmapfsmRecvLidarScansFcn(data, name)

global LIDAR LFLAG QUEUELASER POSE SERVO_ANGLE PREV_GOAL GOAL
global K_LIDAR

if isempty(data)
  return
end

if(QUEUELASER)
    %fprintf('%d, %f \n',K_LIDAR,SERVO_ANGLE);
    if(isempty(K_LIDAR))
        K_LIDAR = 1;
        LIDAR = {};
        setServotoScan;
        pause(0.5)
        return;
    end
    LIDAR{K_LIDAR} = MagicLidarScanSerializer('deserialize',data);
    LIDAR{K_LIDAR}.pitch = POSE.pitch;
    LIDAR{K_LIDAR}.yaw = POSE.yaw;
    LIDAR{K_LIDAR}.roll = POSE.roll;
    LIDAR{K_LIDAR}.servoangle = SERVO_ANGLE;
    K_LIDAR = K_LIDAR + 1;
    
    if(K_LIDAR > 170)
        K_LIDAR = [];
        LFLAG = true;
        QUEUELASER = false;
        PREV_GOAL = GOAL;
        setServotoPoint;
    end
end

