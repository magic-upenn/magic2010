function gcsMapUpdateH(id, pkt)

global RPOSE RNODE
global GTRANSFORM GPOSE

pose = RPOSE{id};

if isempty(pose),
  disp(sprintf('gcsMapUpdateH: waiting for robot %d pose message...', id));
  return;
end

if isempty(RNODE{id}),
  if (pose.gpsValid && ...
      (pose.gps.speed > 0.2)),
    disp(sprintf('Initial GPS lock on robot %d', id));

    % Initialize RNODE struct:
    node.n = 0;
    node.gpsInitialized = 0;

    node.pL = zeros(3,0); % Local pose
    node.pGps = zeros(3,0); % GPS pose
    node.oL = zeros(3,0); % Local pose increment
    node.pF = zeros(3,0); % Fitted pose

    node.t = zeros(1,0); % timestamp
    node.gpsValid = zeros(1,0); % GPS valid flag
    node.hlidarConf = zeros(1,0); % HLidar confidence flag
    node.speed = zeros(1,0); % speed

    node.hlidar = cell(1,0);
    node.vlidar = cell(1,0);
  
    RNODE{id} = node;
    RNODE{id}.gpsInitialized = 1;
    
  else
    disp(sprintf('gcsMapUpdateH: robot %d no gps lock: %d sv, %.2f hdop', ...
                 id, pose.gps.numSat, pose.gps.hdop));
    return;
  end
end

n = RNODE{id}.n + 1;

RNODE{id}.n = n;
RNODE{id}.t(n) = gettime;
RNODE{id}.pL(:,n) = pose.pL;
RNODE{id}.pGps(:,n) = pose.pGps;
RNODE{id}.gpsValid(n) = pose.gpsValid;
if ~isempty(pose.gps.speed),
  RNODE{id}.speed(n) = pose.gps.speed;
else
  RNODE{id}.speed(n) = 0;
end

xh = double(pkt.xs);
yh = double(pkt.ys);
ch = double(pkt.cs);
ph = [xh yh ch]';
RNODE{id}.hlidar{n} = ph;

% Fields for fitting pose:
if n > 1,
  pLPrev = RNODE{id}.pL(:,n-1);
  pFPrev = RNODE{id}.pF(:,n-1);
  phPrev = RNODE{id}.hlidar{n-1};
else
  % Use initial gps pose for fitted pose
  pLPrev = pose.pL;
  pFPrev = pose.pGps;
  phPrev = zeros(3,0);

  oGps = o_mult(pose.pGps, o_inv(pose.pL));
  GTRANSFORM{id} = oGps;
end

% Compute lidar correlation statistics
scanCounts = scan_correlation(phPrev, ph);
RNODE{id}.hlidarConf(n) = scanCounts(3)/(max(scanCounts(1:2))+100);


% Compute incremental pose
oL1 = o_p1p2(pLPrev, RNODE{id}.pL(:,n));

RNODE{id}.oL(:,n) = oL1;
RNODE{id}.pF(:,n) = o_mult(pFPrev, oL1); 

GPOSE{id} = o_mult(GTRANSFORM{id}, RNODE{id}.pL(:,n));
