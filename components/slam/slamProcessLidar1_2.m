%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Lidar1 message handler (vertical lidar)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function slamProcessLidar1_2(data,name)
global SLAM LIDAR1 SERVO1 OMAP CMAP EMAP POSE IMU DVMAP

if ~isempty(data)
  LIDAR1.scan = MagicLidarScanSerializer('deserialize',data);
else
  return;
end

xBinLength = 0.1; % meters
xBinMax = round((25.0)/xBinLength);
xBin = xBinLength*[1:xBinMax];

%make sure we have fresh data
if (CheckImu() ~= 1), return; end
if (CheckServo1() ~= 1), return; end

servoAngle = SERVO1.data.position + SERVO1.offsetYaw;
Tservo1 = trans([SERVO1.offsetx SERVO1.offsety SERVO1.offsetz])*rotz(servoAngle);
Tlidar1 = trans([LIDAR1.offsetx LIDAR1.offsety LIDAR1.offsetz]) * ...
          rotx(pi/2);
Timu = roty(IMU.data.pitch)*rotx(IMU.data.roll);
Tpos = trans([SLAM.x SLAM.y SLAM.z])*rotz(SLAM.yaw);

T = (Tpos*Timu*Tservo1*Tlidar1);

nStart = 250; %throw out points that pick up our own body
nStop  = 750;
ranges = double(LIDAR1.scan.ranges); %convert from float to double
indGood = ranges >0.25 & ranges < 15;
indGood(1:nStart-1) = 0;
indGood(nStop:end) = 0;

rangesGood = ranges(indGood);

%sensor frame
xss = rangesGood.*LIDAR1.cosines(indGood);
yss = rangesGood.*LIDAR1.sines(indGood);
zss = zeros(size(xss));

%global frame
X = [xss; yss; zss; ones(size(xss))];
pRot = T*X;
rLidar = sqrt((pRot(1,:)-SLAM.x).^2+(pRot(2,:)-SLAM.y).^2);
zLidar = pRot(3,:);

% Ignore inside robot, and too high:
  indClip = find((rangesGood > 0.3) & (zLidar < 1.5));
if isempty(indClip), return, end

xClip = rLidar(indClip);
zClip = zLidar(indClip);


% Detect negative cliffs:
zDiff = zClip([2:end end]) - zClip;
xDiff = xClip([2:end end]) - xClip;
iCliff = zDiff < min(-0.04, -tand(15)*xDiff);
xCliff = xClip(iCliff);
zCliff = zClip(iCliff);

[stats bins] = binStats(xClip./xBinLength, zClip, xBinMax);

SLAM.lidar1Stats = stats;

counts = [stats.count];
zMean = [stats.mean];
zMaxMin = [stats.max] - [stats.min];

iGnd = (counts >= 2) & (zMaxMin < 0.05) & ...
	    (zMean < 0.3*xBin + 0.05) & (zMean > -0.3*xBin -0.05);

iObs = (zMaxMin > 0.06) | (zMean > 0.4*xBin + 0.10);

xsg = pRot(1,indClip);
ysg = pRot(2,indClip);

xig = ceil((xsg - CMAP.xmin) * CMAP.invRes);
yig = ceil((ysg - CMAP.ymin) * CMAP.invRes);

mapInds = sub2ind(size(CMAP.map.data),xig,yig);

iGndPts     = iGnd(bins);
iObsPts     = iObs(bins);
iFirstObs   = find(iObsPts,1);
iFirstCliff = find(iCliff,1);

if isempty(iFirstObs), iFirstObs = 99999; end
if isempty(iFirstCliff), iFirstCliff = 99999; end
iFirstBad = min([iFirstObs,iFirstCliff,length(iGndPts)]);

countsPts   = counts(bins);
iGndMap   = mapInds(iGndPts(1:iFirstBad-5));
countsGnd = countsPts(iGndPts(1:iFirstBad-5));
iObsMap   = [mapInds(iObsPts) mapInds(iCliff)];
countsObs   = [find(countsPts(iObsPts)) find(iCliff)];

CMAP.map.data(iObsMap) = CMAP.map.data(iObsMap) + countsObs*SLAM.cMapIncObs;
CMAP.map.data(iGndMap) = CMAP.map.data(iGndMap) + countsGnd*SLAM.cMapIncFree;

tooLarge = CMAP.map.data(mapInds) > SLAM.maxCost;
tooSmall = CMAP.map.data(mapInds) < SLAM.minCost;
CMAP.map.data(mapInds(tooLarge)) = SLAM.maxCost;
CMAP.map.data(mapInds(tooSmall)) = SLAM.minCost;

%mark the cells as modified
DVMAP.map.data(iGndMap)  = 1;
DVMAP.map.data(iObsMap)  = 1;

plotFig = 1;

if plotFig
    plot(xClip, zClip, '-');
    hold on;
    plot(xBin(iGnd), zMean(iGnd),'go', ...
         xBin(iObs), zMean(iObs), 'rx', ...
         xCliff, zCliff, 'r*');
    hold off;
    drawnow;
end
