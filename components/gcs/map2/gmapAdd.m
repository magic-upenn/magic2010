function gmapAdd(id, index);

global GMAP
global RNODE GTRANSFORM

node = RNODE{id};

% No node information to add:
if isempty(node), return; end

hfilter = 0.1;
vfilter = 0.4;

for i = index,
  pL1 = node.pL(:,i);
  pF1 = node.pF(:,i);

  %oFL1 = o_mult(pF1, o_inv(pL1));
  oFL1 = GTRANSFORM{id};
  
  ph = node.hlidar{i};
  if ~isempty(ph),
    phF = o_mult(oFL1, ph);
    %phF(3,:) = max(ph(3,:), 10);
    phF(3,:) = ph(3,:);
    %    disp(sprintf('gmapAdd: %.3f ',GMAP.x(1:end),phF(1,1)));

    map_filter(GMAP.im, GMAP.x, GMAP.y, phF, hfilter);  
  end
  pv = node.vlidar{i};
  if ~isempty(pv),
    pvF = o_mult(oFL1, pv);
    pvF(3,:) = pv(3,:);
    %    pvF(3, pv(3,:) > 0) = 100;
    map_filter(GMAP.im, GMAP.x, GMAP.y, pvF, vfilter);  
  end

end
