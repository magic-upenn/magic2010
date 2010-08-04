%   Created By:  Brett Kuprel
%                kuprel@umich.edu
%                feel free to email me any questions
%
%   To use laserLock:
%       1. start IPC Central
%       2. run lidar driver, micro gateway driver, and slam
%       3. publish a target in slam [x y z] coordinates over IPC
%       4. republish if target changes
%
%   Constants:
%       -  kP, kI, and kD are the PID controller constants
%       -  bufferTime is the time in seconds that error is integrated over
%       -  laserOffset is [x y z roll pitch yaw] of center of yaw servo 
%          with respect to the center of the robot
%       -  pitchServoOffset is [x y z] of center of pitch servo wrt center
%          of yaw servo

function laserLock
	
 %%%%%%%%%%%%%
 % Constants %
 %%%%%%%%%%%%%

	robotID                       = 3;
	robotPoseMessageSuffix        = 'Pose';
  targetPoseMessageSuffix       = 'Target';
	laserOffset                   = [0.15 0 0.43 0 0 0];
	pitchServoOffset              = [0.048 0.033 0];
	bufferTime                    = 2;
  kP                            = 15;
  kI                            = 3;
  kD                            = 0;
    
 %%%%%%%%%%%%%
	
	SetMagicPaths;
	setenv('ROBOT_ID',num2str(robotID));
	
	robotAddress = ['192.168.10.10' getenv('ROBOT_ID')];
    ipcAPIConnect(robotAddress);
    
	robotPoseMessage = GetMsgName(robotPoseMessageSuffix);
    targetPoseMessage = GetMsgName(targetPoseMessageSuffix);
	
    ipcAPISubscribe(robotPoseMessage);
    ipcAPISubscribe(targetPoseMessage);
	
	initializeServos;	
	
    dt = getDT;
    bufferLength = round(bufferTime/dt);
    yawBuffer   = zeros(3,bufferLength);
    pitchBuffer = zeros(3,bufferLength);
    
    tic
    
    robotPose = zeros(1,6);
    targetPose = [0 0 -1e4];
    
	while(true)
        [robotPose targetPose] = updatePoses(robotPose,targetPose,robotPoseMessage,targetPoseMessage);
        targetRobCoords = glob2laser(targetPose, robotPose, laserOffset);
        [yawAngle pitchAngle] = calculateServoAngles(targetRobCoords, pitchServoOffset);
        [yawBuffer pitchBuffer] = updateBuffers(yawBuffer,pitchBuffer,yawAngle,pitchAngle);
        [yawVel pitchVel] = PIDcontrol(yawBuffer,pitchBuffer,kP,kI,kD);           
        setServoVels(yawVel, pitchVel);
	end
		
end

function initializeServos

	dev = '/dev/ttyUSB1';
	baud = 1000000;
	pitchID = 1;
	yawID = 4;

	dynamixelAPI_1('connect',dev,baud,yawID);
	dynamixelAPI_2('connect',dev,baud,pitchID);

end

function dt = getDT

    n = 10;
    i = 0;
    t = zeros(1,n);
    
    while i<=n
        messages = ipcAPIReceive;
        if ~isempty(messages)
            try
                t(i) = toc;
            catch
            end
            i = i + 1;
            tic       
        end
    end
    
    t(t>2*mean(t))=[];
    dt = mean(t);

end

function [robotPose targetPose] = updatePoses(robotPose,targetPose,robotPoseMessage,targetPoseMessage)
    
    messages = ipcAPIReceive;
    for i=1:length(messages)
        if strcmp(messages(i).name,robotPoseMessage)
            r = MagicPoseSerializer('deserialize',messages(i).data);
            robotPose = [r.x r.y r.z r.roll r.pitch r.yaw];
        elseif strcmp(messages(i).name,targetPoseMessage)
            t = MagicPoseSerializer('deserialize',messages(i).data);
            targetPose = [t.x t.y t.z];
            fprintf('Got target! [x y z] = [%.3f %.3f %.3f] \n',t.x,t.y,t.z);
        end
    end

end

function targetRobCoords = glob2laser(target,robotPose,laserOffset)

    transR  = robotPose(1:3);
    rollR	= robotPose(4);
    pitchR	= robotPose(5);
    yawR	= robotPose(6);

    transL	= laserOffset(1:3);
    yawL	= laserOffset(4);
    rollL	= laserOffset(5);
    pitchL	= laserOffset(6);

    glob2rob   = makehgtform('translate',transR,'zrotate',yawR,'yrotate',pitchR,'xrotate',rollR);
    rob2laser  = makehgtform('translate',transL,'zrotate',yawL,'yrotate',pitchL,'xrotate',rollL);
    glob2laser = (glob2rob*rob2laser)^-1;

    targetRobCoords = glob2laser*[target 1]';
    targetRobCoords = targetRobCoords(1:3)';

end

function [yawServoAngle pitchServoAngle] = calculateServoAngles(targetRobCoords, pitchServoOffset)

	xt = targetRobCoords(1);
	yt = targetRobCoords(2);
	oy = pitchServoOffset(2);
	
	thetaH = atan(yt/xt);
	dthetaH = asin(oy/sqrt(xt^2+yt^2));
	yawServoAngle = thetaH - dthetaH;
	
	yawServo2pitchServo = makehgtform('translate',pitchServoOffset,'zrotate',yawServoAngle)^-1;
	
	targetPitchServoCoords = yawServo2pitchServo * [targetRobCoords 1]';
	targetPitchServoCoords = targetPitchServoCoords(1:3)';
	
	xt = targetPitchServoCoords(1);
	zt = targetPitchServoCoords(3);
	
	pitchServoAngle = atan(zt/xt);

end

function setServoVels(yawVel, pitchVel)
	
	yawRange = [-55 55];
	pitchRange = [-90 90];
	min = 1;
	max = 2;
    maxVel = 100;

    if yawVel > 0
		yawGoal = yawRange(max);
    else
        yawGoal = yawRange(min);
    end
    
    yawVel = abs(yawVel);
    
    if yawVel > maxVel
        yawVel = maxVel;
    end
    
    if pitchVel > 0
		pitchGoal = pitchRange(max);
    else
        pitchGoal = pitchRange(min);
    end
    
    pitchVel = abs(pitchVel);
    
    if pitchVel > maxVel
        pitchVel = maxVel;
    end
    
    try
        dynamixelAPI_1('setPosition',yawGoal,yawVel);
    catch
        
    end
    
    try
        dynamixelAPI_2('setPosition',pitchGoal,pitchVel);
    catch
        
    end
	
end

function [yawBuffer pitchBuffer] = updateBuffers(yawBuffer,pitchBuffer,yawAngle,pitchAngle)
    
    dt = toc;
    tic
    
    yawBuffer(:,2:end) = yawBuffer(:,1:end-1);    
    yawBuffer(1,1) = rad2deg(yawAngle);
    try
        yawBuffer(2,1) = dynamixelAPI_1('getPosition');
    catch
        yawBuffer(2,1) = yawBuffer(2,2);
    end
    yawBuffer(3,1) = dt;
    
    pitchBuffer(:,2:end) = pitchBuffer(:,1:end-1);  
    pitchBuffer(1,1) = rad2deg(pitchAngle);
    try
        pitchBuffer(2,1) = dynamixelAPI_2('getPosition');
    catch
        pitchBuffer(2,1) = pitchBuffer(2,2);
    end
    pitchBuffer(3,1) = dt;
    
end

function [yawVel pitchVel] = PIDcontrol(yawBuffer,pitchBuffer,kP,kI,kD)


    yawProportional     = kP * (yawBuffer(1,1)-yawBuffer(2,1));
    yawIntegral         = kI * sum((yawBuffer(1,:)-yawBuffer(2,:)).*yawBuffer(3,:));
    yawDifferential     = kD * ((yawBuffer(1,1)-yawBuffer(2,1)) - (yawBuffer(1,2)-yawBuffer(2,2)))/yawBuffer(3,1);

    pitchProportional   = kP * (pitchBuffer(1,1)-pitchBuffer(2,1));
    pitchIntegral       = kI * sum((pitchBuffer(1,:)-pitchBuffer(2,:)).*pitchBuffer(3,:));
    pitchDifferential   = kD * ((pitchBuffer(1,1)-pitchBuffer(2,1)) - (pitchBuffer(1,2)-pitchBuffer(2,2)))/pitchBuffer(3,1);

    yawVel              = yawProportional + yawIntegral + yawDifferential;
    pitchVel            = pitchProportional + pitchIntegral + pitchDifferential;

end
