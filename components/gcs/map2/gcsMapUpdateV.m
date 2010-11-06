function gcsMapUpdateV(id, pkt)

global RNODE

if isempty(RNODE{id})
  disp(sprintf('gcsMapUpdateV: waiting for robot %d RNODE initialization...', id));
  return;
end

n = RNODE{id}.n;

xv = double(pkt.xs);
yv = double(pkt.ys);
cv = double(pkt.cs);
RNODE{id}.vlidar{n} = [xv yv cv]';

%return;

% RCLUSTER processing:
global RCLUSTER RCLUSTER_INFO

if isempty(RCLUSTER{id})
  % Initialize RCLUSTER struct:
  RCLUSTER{id}.n = 0;
  RCLUSTER{id}.nCluster = 0;
  RCLUSTER{id}.iNode = RNODE{id}.n;
  RCLUSTER{id}.pL = RNODE{id}.pL(:,RNODE{id}.n);
  RCLUSTER{id}.mapCurrent = zeros(length(RCLUSTER_INFO.dxMap), ...
                           length(RCLUSTER_INFO.dyMap), 'int8');
  RCLUSTER{id}.pMap = cell(1,0);
end

RCLUSTER{id}.n = RCLUSTER{id}.n + 1;
if rem(RCLUSTER{id}.n, RCLUSTER_INFO.nCluster) == 0,
  RCLUSTER{id}.nCluster = RCLUSTER{id}.nCluster + 1;
  [xm, ym, cm] = find(RCLUSTER{id}.mapCurrent);
  if ~isempty(xm),
    pL1 = RCLUSTER{id}.pL(:,RCLUSTER{id}.nCluster);

    xm = RCLUSTER_INFO.dxMap(xm) + pL1(1);
    ym = RCLUSTER_INFO.dyMap(ym) + pL1(2);
    RCLUSTER{id}.pMap{RCLUSTER{id}.nCluster} = ...
        [xm; ym; double(cm)'];
  else
    RCLUSTER{id}.pMap{RCLUSTER{id}.nCluster} = zeros(3,0);
  end

  RCLUSTER{id}.pL(:,RCLUSTER{id}.nCluster+1) = RNODE{id}.pL(:,RNODE{id}.n);
  RCLUSTER{id}.iNode(:,RCLUSTER{id}.nCluster+1) = RNODE{id}.n;
  RCLUSTER{id}.mapCurrent = zeros(length(RCLUSTER_INFO.dxMap), ...
                                  length(RCLUSTER_INFO.dyMap), 'int8');

end

hl = RNODE{id}.hlidar{n};
hfilter = 0.1;
if ~isempty(hl),
  hl(3,:) = 100;
  map_assign(RCLUSTER{id}.mapCurrent, ...
             RCLUSTER{id}.pL(1,end)+RCLUSTER_INFO.dxMap, ...
             RCLUSTER{id}.pL(2,end)+RCLUSTER_INFO.dyMap, ...
             hl, hfilter);
end

vl = RNODE{id}.vlidar{n};
vfilter = 0.4;
if ~isempty(vl),
  map_assign(RCLUSTER{id}.mapCurrent, ...
             RCLUSTER{id}.pL(1,end)+RCLUSTER_INFO.dxMap, ...
             RCLUSTER{id}.pL(2,end)+RCLUSTER_INFO.dyMap, ...
             vl, vfilter);
end

