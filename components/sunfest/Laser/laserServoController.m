addpath( [ getenv('VIS_DIR') '/ipc' ] )
ipcAPI('connect','localhost');

laserPoseMsgName = ['Robot1/LaserPointer' VisMarshall('getMsgSuffix','Pose3D')];
laserPoseMsgFormat = VisMarshall('getMsgFormat','Pose3D');
ipcAPIDefine(laserPoseMsgName,laserPoseMsgFormat);

laserOffset = [0.137 0 0.546];
targetGlob = [3.789 -1.5 1.5];
targetGlob = [targetGlob 1]';

ipcAPI('subscribe', 'Robot1/PoseTruth');
ipcAPI('subscribe', 'Robot2/PoseTruth');
%ipcAPI('subscribe', 'Robot1/ImuFiltered');
while(1)
	messages = ipcAPI('receive');
	for i=1:length(messages)
		if strcmp(messages(i).name,'Robot2/PoseTruth')
			targetPose = MagicPoseSerializer('deserialize',messages(i).data);
			targetGlob = [targetPose.x targetPose.y targetPose.z+1 1]';
		elseif strcmp(messages(i).name,'Robot1/ImuFiltered')
			imu = MagicImuFilteredSerializer('deserialize',messages(i).data);
			wroll = imu.wroll; wpitch = imu.wpitch; wyaw = imu.wyaw;
		elseif strcmp(messages(i).name,'Robot1/PoseTruth')
			robotPose = MagicPoseSerializer('deserialize',messages(i).data);
			xr=robotPose.x; yr=robotPose.y; zr=robotPose.z; yaw=robotPose.yaw; roll=robotPose.roll; pitch=robotPose.pitch;
			glob2rob = makehgtform('translate',[xr yr zr],'zrotate',yaw,'yrotate',pitch,'xrotate',roll,'translate',laserOffset)^-1;

			targetRob = glob2rob * targetGlob;
			xt = targetRob(1); yt = targetRob(2); zt = targetRob(3);
			thetaH = asin(yt/(xt^2+yt^2)^0.5);
			if (xt<0), thetaH = pi-thetaH; end
			if thetaH>pi, thetaH = thetaH - 2*pi; end
			thetaV = asin(-zt/(xt^2+yt^2+zt^2)^0.5);
			
			%rob2fut = makehgtform('translate',[v*dt 0 0],'zrotate',wyaw*dt,'yrotate',wpitch*dt,'xrotate',wroll*dt)^-1;

			%disp(['(thetaH,thetaV) = (' num2str(rad2deg(thetaH)) ',' num2str(rad2deg(thetaV)) ')'])

			if ~exist('thetaHprev','var') || thetaH~=thetaHprev, servoController(rad2deg(thetaH),'ServoH'); end
			if ~exist('thetaVprev','var') || thetaV~=thetaVprev, servoController(rad2deg(thetaV),'ServoV'); end
			thetaHprev = thetaH;
			thetaVprev = thetaV;
		end

	end

end

% function [roll pitch] = changeRollPitch(roll,pitch)
% 
% 	d = pi/36;
% 	droll=d; dpitch=d;
% 
%   c = getch();
%   if ~isempty(c)
%     switch c
%       case 'w'
%         pitch = pitch - dpitch;
%       case 's'
%         pitch = pitch + dpitch;
%       case 'a'
%         roll = roll + droll;
%       case 'd'
%         roll = roll - droll;
% 		end
% 		fprintf(1,'(pitch,roll) = (%1.0f,%1.0f)\n',rad2deg(pitch),rad2deg(roll));
% 	end 
% end