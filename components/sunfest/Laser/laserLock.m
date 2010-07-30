function laserLock(target,robotAddress)
	
%%%%%%%%%%%%%
% Constants %
%%%%%%%%%%%%%

	robotID						= 3;
	poseMessageSuffix			= 'Pose';
	laserOffset					= [0.15 0 0.43 0 0 0];		% [x y z roll pitch yaw] of center of yaw servo wrt center of robot
	pitchServoOffset			= [.048 0.033 0];			% [x y z] of center of pitch servo wrt center of yaw servo
	bufferLength                = 30;
    kP                          = 4;
    kI                          = 4;
    kD                          = 0;
    
%%%%%%%%%%%%%
	
	SetMagicPaths;
	setenv('ROBOT_ID',num2str(robotID));
	
	if (nargin < 2), robotAddress = ['192.168.10.10' getenv('ROBOT_ID')]; end
	poseMessage = GetMsgName(poseMessageSuffix);
	ipcAPIConnect(robotAddress);
    ipcAPISubscribe(poseMessage); 
	
	initializeServos;	
	
    yawBuffer   = zeros(3,bufferLength);
    pitchBuffer = zeros(3,bufferLength);
    
    tic
    
	while(true)
		robotPose = getRobotPose;
		if ~isempty(robotPose)
			targetRobCoords = glob2laser(target, robotPose, laserOffset);
			[yawAngle pitchAngle] = calculateServoAngles(targetRobCoords, pitchServoOffset);
            [yawBuffer pitchBuffer] = updateBuffers(yawBuffer,pitchBuffer,yawAngle,pitchAngle);
            [yawVel pitchVel] = PIDcontrol(yawBuffer,pitchBuffer,kP,kI,kD);           
			setServoVels(yawVel, pitchVel);
		end
	end
		
end

function robotPose = getRobotPose

    robotPose = [];
    messages = ipcAPIReceive;
    if ~isempty(messages)
        robotPose = MagicPoseSerializer('deserialize',messages(end).data);
    end

end

function targetRobCoords = glob2laser(target,robotPose,laserOffset)

    transR  = [robotPose.x robotPose.y robotPose.z];
    yawR	= robotPose.yaw;
    rollR	= robotPose.roll;
    pitchR	= robotPose.pitch;

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
        disp('Could not set yaw')
    end
    
    try
        dynamixelAPI_2('setPosition',pitchGoal,pitchVel);
    catch
        disp('Could not set pitch')
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
        disp('Could not get yaw')
        yawBuffer(2,1) = yawBuffer(2,2);
    end
    yawBuffer(3,1) = dt;
    
    pitchBuffer(:,2:end) = pitchBuffer(:,1:end-1);  
    pitchBuffer(1,1) = rad2deg(pitchAngle);
    try
        pitchBuffer(2,1) = dynamixelAPI_2('getPosition');
    catch
        disp('Could not get pitch')
        pitchBuffer(2,1) = pitchBuffer(2,2);
    end
    pitchBuffer(3,1) = dt;
    
end

function [yawVel pitchVel] = PIDcontrol(yawBuffer,pitchBuffer,kP,kI,kD)


    yawProportional     = kP * (yawBuffer(1,1)-yawBuffer(2,1));
    yawIntegral         = kI * sum((yawBuffer(1,:)-yawBuffer(2,:)).*yawBuffer(3,:))
    yawDifferential     = kD * ((yawBuffer(1,1)-yawBuffer(2,1)) - (yawBuffer(1,2)-yawBuffer(2,2)))/yawBuffer(3,1);

    pitchProportional     = kP * (pitchBuffer(1,1)-pitchBuffer(2,1));
    pitchIntegral         = kI * sum((pitchBuffer(1,:)-pitchBuffer(2,:)).*pitchBuffer(3,:));
    pitchDifferential     = kD * ((pitchBuffer(1,1)-pitchBuffer(2,1)) - (pitchBuffer(1,2)-pitchBuffer(2,2)))/pitchBuffer(3,1);

    yawVel              = yawProportional + yawIntegral + yawDifferential;
    pitchVel            = pitchProportional + pitchIntegral + pitchDifferential;

end