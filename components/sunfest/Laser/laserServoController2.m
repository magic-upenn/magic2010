ipcAPI('connect','192.168.10.102');
ipcAPI('subscribe', 'Robot2/Pose');
ipcAPI('subscribe', 'Robot2/Lidar0');

laserOffset = [0.137 0 0.546];
targetGlob = [1 0 0 1]';

hLidar = polar(0,10,'b.');

while(1)
	messages = ipcAPI('receive');
	for i=1:length(messages);
		if strcmp(messages(i).name,'Robot2/Pose')
			robotPose = MagicPoseSerializer('deserialize',messages(i).data);
			xr=robotPose.x; yr=robotPose.y; zr=robotPose.z; yaw=robotPose.yaw; roll=robotPose.roll; pitch=robotPose.pitch;
			glob2rob = makehgtform('translate',[xr yr zr],'zrotate',yaw,'yrotate',pitch,'xrotate',roll,'translate',laserOffset)^-1;
			
			targetRob = glob2rob * targetGlob;
			xt = targetRob(1); yt = targetRob(2); zt = targetRob(3);
			thetaH = asin(yt/(xt^2+yt^2)^0.5);
			if (xt<0), thetaH = pi-thetaH; end
			if thetaH>pi, thetaH = thetaH - 2*pi; end
			thetaV = asin(-zt/(xt^2+yt^2+zt^2)^0.5);

			%disp(['(thetaH,thetaV) = (' num2str(rad2deg(thetaH)) ',' num2str(rad2deg(thetaV)) ')'])
			
			servoControllerTest(rad2deg(thetaH),'ServoH');
			
		elseif strcmp(messages(i).name,'Robot2/Lidar0')
      lidarScan = MagicLidarScanSerializer('deserialize',messages(i).data);
      lidarData = double([linspace(lidarScan.startAngle,lidarScan.stopAngle,length(lidarScan.ranges))+pi/2; lidarScan.ranges]);
      lidarData(:,lidarData(2,:)<0.021)=[];
			
			lidarTheta = lidarData(2,:);
			lidarRho = lidarData(1,:);
			
      [lidarX lidarY] = pol2cart(lidarTheta, lidarRho);
      lidarY = lidarY + .137;
      [lidarTheta lidarRho] = cart2pol(lidarX, lidarY);
			
			thetaHorizontal = lidarTheta(lidarRho==min(lidarRho));

			set(hLidar,'xdata',lidarX,'ydata',lidarY);
			drawnow;
			
		end
			

	end

end