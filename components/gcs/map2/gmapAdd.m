function gmapAdd(id, index);

global GMAP
global RNODE

node = RNODE{id};

% No node information to add:
if isempty(node), return; end

% Initalize counter values for id
if isempty(GMAP.rnodeN{id}),
  GMAP.rnodeN{id} = 0;
  GMAP.rnodeN0{id} = 0;
end

n0lag = 100;
hfilter = 0.075;
vfilter = 0.10;

for i = index,
  pL1 = node.pL(:,i);
  pF1 = node.pF(:,i);
  
  ph = node.hlidar{i};
  if ~isempty(ph),
    phF = o_mult(pF1, o_p1p2(pL1, ph));
    phF(3,:) = 100;
    %    disp(sprintf('gmapAdd: %.3f ',GMAP.x(1:end),phF(1,1)));

    map_filter(GMAP.im, GMAP.x, GMAP.y, phF, hfilter);  
  end
  pv = node.vlidar{i};
  if ~isempty(pv),
    pvF = o_mult(pF1, o_p1p2(pL1, pv));
    pvF(3,:) = pv(3,:);
    pvF(3, pv(3,:) > 0) = 100;
    map_filter(GMAP.im, GMAP.x, GMAP.y, pvF, vfilter);  
  end
  GMAP.rnodeN{id} = i;

  ilag = i - n0lag;
  if (ilag > GMAP.rnodeN0{id}),
    pL1 = node.pL(:,ilag);
    pF1 = node.pF(:,ilag);
  
    ph = node.hlidar{ilag};
    if ~isempty(ph),
      phF = o_mult(pF1, o_p1p2(pL1, ph));
      phF(3,:) = 100;
      map_filter(GMAP.im0, GMAP.x, GMAP.y, phF, hfilter);  
    end
    pv = node.vlidar{ilag};
    if ~isempty(pv),
      pvF = o_mult(pF1, o_p1p2(pL1, pv));
      pvF(3,:) = pv(3,:);
      pvF(3, pv(3,:) > 0) = 100;
      map_filter(GMAP.im0, GMAP.x, GMAP.y, pvF, vfilter);  
    end
    GMAP.rnodeN0{id} = ilag;
  end

end
