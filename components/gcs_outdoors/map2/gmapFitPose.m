function ofit = gmapFitPose(id, index);

global GMAP
global RNODE GTRANSFORM


ofit = [0 0 0]';
node = RNODE{id};

% No node information to add:
if isempty(node), return; end

if (index > node.n),
  disp('gmapFitPose: bad index');
  return;
end

n = node.n;
pF = node.pF(:,index);
ph = node.hlidar{index};
if isempty(ph),
  disp('gmapFitPose: no lidar data');
  return;
end

ph0 = o_mult(GTRANSFORM{id}, ph);

ofit = gmapFitCorr(GMAP.im, GMAP.x, GMAP.y, ph0, 5.0)

GTRANSFORM{id} = o_mult(ofit, GTRANSFORM{id});
pFfit = o_mult(ofit, pF);
RNODE{id}.pF(:,index) = pFfit;

return;
