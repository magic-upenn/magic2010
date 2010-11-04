function gcsMapUpdateH(id, pkt)

global RPOSE RNODE

pose = RPOSE{id};

if isempty(pose),
  disp(sprintf('Waiting for robot %d pose message...', id));
  return;
end

if isempty(RNODE{id}),
  % Initialize RNODE struct:
  node.n = 0;
  node.gpsInitialized = 0;

  node.pL = zeros(3,0); % Local pose
  node.pGps = zeros(3,0); % GPS pose
  node.oL = zeros(3,0); % Local pose increment
  node.pF = zeros(3,0); % Fitted pose

  node.gpsValid = zeros(1,0); % GPS valid flag
  node.hlidarConf = zeros(1,0); % HLidar confidence flag

  node.hlidar = cell(1,0);
  node.vlidar = cell(1,0);
  
  RNODE{id} = node;
end

n = RNODE{id}.n + 1;

RNODE{id}.n = n;
RNODE{id}.pL(:,n) = pose.pL;
RNODE{id}.pGps(:,n) = pose.pGps;
RNODE{id}.gpsValid(n) = pose.gpsValid;

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
  pLPrev = zeros(3,1);
  pFPrev = zeros(3,1);
  phPrev = zeros(3,0);
end

% Compute lidar correlation statistics
scanCounts = scan_correlation(phPrev, ph);
RNODE{id}.hlidarConf(n) = scanCounts(3)/(max(scanCounts(1:2))+100);

% Compute incremental pose
oL1 = o_p1p2(pLPrev, RNODE{id}.pL(:,n));
% Hack to fix angles:
if (scanCounts(3) == 0),
  oL1(3) = 0;
end
if (scanCounts(3) <= .3*min(scanCounts(1:2))),
  oL1(3) = .3*tanh(oL1(3)/.3);
end

RNODE{id}.oL(:,n) = oL1;
RNODE{id}.pF(:,n) = o_mult(pFPrev, oL1); 

if (~RNODE{id}.gpsInitialized) && ...
    pose.gpsValid && ...
    (pose.gps.speed > 0.1),
  % Use initial gps pose for fitted pose
  dp = o_p1p2(RNODE{id}.pL(:,n), RNODE{id}.pL(:,1:n));
  RNODE{id}.pF(:,1:n) = o_mult(RNODE{id}.pGps(:,n), dp);
  
  RNODE{id}.gpsInitialized = 1;
end
