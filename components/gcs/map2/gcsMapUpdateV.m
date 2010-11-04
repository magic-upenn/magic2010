function gcsMapUpdateV(id, pkt)

global RNODE

if isempty(RNODE{id})
  disp(sprintf('Waiting for robot %d initial horizontal lidar...', id));
  return;
end

n = RNODE{id}.n;

xv = double(pkt.xs);
yv = double(pkt.ys);
cv = double(pkt.cs);
RNODE{id}.vlidar{n} = [xv yv cv]';
