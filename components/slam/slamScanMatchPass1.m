 
if (abs(IMU.data.wyaw) < 50/180*pi)
  nyaw1 = 5;
  dyaw1 = 0.2/180.0*pi;
elseif (abs(IMU.data.wyaw) < 100/180*pi)
  nyaw1 = 5;
  dyaw1 = 0.3/180.0*pi;
elseif (abs(IMU.data.wyaw) < 200/180*pi)
  nyaw1 = 9;
  dyaw1 = 0.4/180.0*pi;
elseif (abs(IMU.data.wyaw) < 270/180*pi)
  nyaw1 = 15;
  dyaw1 = 0.5/180.0*pi;
else
  nyaw1 = 25;
  dyaw1 = 1.0/180.0*pi;
end


%resolution of the candidate poses
%TODO: make this dependent on angular velocity / motion speed

tEncoders = ENCODERS.counts.t;
tLidar0   = LIDAR0.scan.startTime;

if abs(tLidar0-tEncoders) < 0.1
  nxs1  = 5;
  nys1  = 5;
  dx1   = 0.02;
  dy1   = 0.02;
else
  nxs1  = 11;
  nys1  = 11;
  dx1   = 0.05;
  dy1   = 0.05;
end

yawRange1 = floor(nyaw1/2);
xRange1   = floor(nxs1/2);
yRange1   = floor(nys1/2);

%create the candidate locations in each dimension
aCand1 = (-yawRange1:yawRange1)*dyaw1+SLAM.yaw + IMU.data.wyaw*dt;
xCand1 = (-xRange1:xRange1)*dx1+SLAM.xOdom;
yCand1 = (-yRange1:yRange1)*dy1+SLAM.yOdom;

%get a local 3D sampling of pose likelihood
hits = ScanMatch2D('match',OMAP.map.data,xsss,ysss, ...
  xCand1,yCand1,aCand1);

%find maximum
[hmax imax] = max(hits(:));
[kmax mmax jmax] = ind2sub([nxs1,nys1,nyaw1],imax);

if (SLAM.lidar0Cntr > 1)

  %extract the 2D slice of xy poses at the best angle
  hitsXY = hits(:,:,jmax);

  %create a grid of distance-based costs from each cell to odometry pose
  [yGrid1 xGrid1] = meshgrid(yCand1,xCand1);
  %xDiff1 = xGrid1 - SLAM.xOdom;
  %yDiff1 = yGrid1 - SLAM.yOdom;
  %distGrid1 = 1000*sqrt(xDiff1.^2 + yDiff1.^2);
  %distGrid1(abs(distGrid1
  [minIndX indx] = min(abs(xCand1-SLAM.xOdom));
  [minIndY indy] = min(abs(yCand1-SLAM.yOdom));
  
  %combine the pose likelihoods with the distance from odometry prediction
  %TODO: play around with the weights!!
  %costGrid1 = distGrid1 - hitsXY;
  costGrid1 = - hitsXY;
  costGrid1(indx,indy) = costGrid1(indx,indy) - 500;
  
  %find the minimum and save the new pose
  [cmin cimin] = min(costGrid1(:));
  
  %fprintf(1,'distGrid min %f, hits xy min =%f\n',distGrid1(cimin),hitsXY(cimin));

  %save the best pose
  SLAM.yaw = aCand1(jmax);
  SLAM.x   = xGrid1(cimin);
  SLAM.y   = yGrid1(cimin);
else
  [xStart yStart thStart] = FindStartPose(SLAM.x, SLAM.y, SLAM.yaw, xsss,ysss);

if ~isempty(xStart)
  SLAM.x = xStart;
  SLAM.Y = yStart;
  SLAM.yaw = thStart;
  SLAM.xOdom = xStart;
  SLAM.yOdom = yStart;
  SLAM.yawOdom = thStart;
end
    
end