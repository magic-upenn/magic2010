function RascalmapfsmRecvLidarScansFcn(data, name)

global LIDAR LFLAG QUEUELASER POSE SERVO_ANGLE
persistent k_Lidar

if isempty(data)
  return
end

if(QUEUELASER)
    fprintf('%d \n',k_Lidar);
    if(isempty(k_Lidar))
        k_Lidar = 1;
        LIDAR = {};
        setServotoScan;
        pause(0.1)
    end
    LIDAR{k_Lidar} = MagicLidarScanSerializer('deserialize',data);
    LIDAR{k_Lidar}.pitch = POSE.pitch;
    LIDAR{k_Lidar}.yaw = POSE.yaw;
    LIDAR{k_Lidar}.roll = POSE.roll;
    LIDAR{k_Lidar}.servoangle = SERVO_ANGLE;
    k_Lidar = k_Lidar + 1;
    
    if(k_Lidar > 150)
        k_Lidar = [];
        LFLAG = true;
        QUEUELASER = false;
        setServotoPoint;
    end
end

