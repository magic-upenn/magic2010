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

return;

global RCLUSTER

nCluster = 60;  % number of nodes in each cluster

% Initialize RCLUSTER struct:
cluster0.nCount = 0;
cluster0.iNode = 0;
cluster0.pL = zeros(3,1);
cluster0.mapDx = [-100:.10:100];
cluster0.mapDy = [-100:.10:100];
cluster0.mapH = zeros(length(cluster0.mapDx), ...
                      length(cluster0.mapDy), 'int8');
cluster0.mapV = zeros(length(cluster0.mapDx), ...
                      length(cluster0.mapDy), 'int8');

if isempty(RCLUSTER{id}),
  RCLUSTER{id} = cluster0;
end

cl = RCLUSTER{id}(end);
cl.nCount = cl.nCount + 1;

RCLUSTER{id}(end) = cl;

if (cl.nCount >= nCluster)
  % Append additional cluster data
  RCLUSTER{id}(end+1) = cluster0;
end
