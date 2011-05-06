function RascalmapfsmRecvLidarScansFcn(data, name)

global LIDAR LFLAG QUEUELASER POSE SERVO_ANGLE PREV_GOAL GOAL START_MAP
global K_LIDAR

if isempty(data)
  return
end

% This will happen only at the very start to ensure that we can see the
% area before clicking in the ground station
if(START_MAP)
    setServotoPoint(0);
    pause(0.5);
    LIDAR{K_LIDAR} = MagicLidarScanSerializer('deserialize',data);
    LIDAR{K_LIDAR}.pitch = POSE.pitch;
    LIDAR{K_LIDAR}.yaw = POSE.yaw;
    LIDAR{K_LIDAR}.roll = POSE.roll;
    LIDAR{K_LIDAR}.servoangle = SERVO_ANGLE;
    K_LIDAR = K_LIDAR + 1;
    if(K_LIDAR > 15)
        START_MAP = false;
        K_LIDAR = [];
        ProcessLidarScans;
        LIDAR = {};

        % Publish the costmap
        mapMsgName = GetMsgName('CMap');
        ipcAPIDefine(mapMsgName);
        
        CMap.MAP = MAP; % costmap
        CMap.orx = POSE.x; % x is column
        CMap.ory = POSE.y; % y is row
        cMap.yaw = POSE.yaw;
        CMap.glx = GOAL(1);
        CMap.gly = GOAL(2);
        
        content = serialize(CMap);
        ipcAPIPublishVC(mapMsgName,content);
    end
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
        setServotoPoint(0);
    end
end

