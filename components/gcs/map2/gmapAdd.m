function gmapAdd(id, index);

global GMAP
global RNODE

node = RNODE{id};

for i = index,
  pL1 = node.pL(:,i);
  pF1 = node.pF(:,i);
  
  ph = node.hlidar{i};
  if ~isempty(ph),
    phF = o_mult(pF1, o_p1p2(pL1, ph));
    phF(3,:) = 100;
    im_filter(GMAP.im, GMAP.x, GMAP.y, phF, 0.05);  
  end
    
  pv = node.vlidar{i};
  if ~isempty(pv),
    pvF = o_mult(pF1, o_p1p2(pL1, pv));
    pvF(3,:) = pv(3,:);
    pvF(3, pv(3,:) > 0) = 100;
    im_filter(GMAP.im, GMAP.x, GMAP.y, pvF, 0.1);
  end
end
