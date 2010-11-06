function gmapRecalc;

global GMAP
global RNODE RCLUSTER RCLUSTER_INFO
global GTRANSFORM

% Need to refill with UAV prior
GMAP.im = GMAP.im0 + 0; % Force making copy

idValid = [];
for id = 1:9,
  if ~isempty(RCLUSTER{id}),
    idValid(end+1) = id;
  end
end

mfilter = 0.2;

i = 0;
loop = true;
while loop,
  i = i + 1;
  loop = false;
  for id = idValid,
    if (RCLUSTER{id}.nCluster < i),
      continue;
    end
    loop = true;

    inode = RCLUSTER{id}.iNode(i)+RCLUSTER_INFO.nCluster/2; 
    inode = min(inode, RNODE{id}.n);
    oF1 = o_mult(RNODE{id}.pF(:,inode), ...
                 o_inv(RNODE{id}.pL(:,inode)));
    pm = o_mult(oF1, RCLUSTER{id}.pMap{i});
    pm(3,:) = RCLUSTER{id}.pMap{i}(3,:);
    map_filter(GMAP.im, GMAP.x, GMAP.y, pm, mfilter);
  end
end

for id = idValid,
  inode = RCLUSTER{id}.iNode(end);
  oF1 = o_mult(RNODE{id}.pF(:,inode), ...
               o_inv(RNODE{id}.pL(:,inode)));
  GTRANSFORM{id} = oF1;

  [xm, ym, cm] = find(RCLUSTER{id}.mapCurrent);
  if ~isempty(xm),
    pL1 = RCLUSTER{id}.pL(:,end);
    xm = RCLUSTER_INFO.dxMap(xm) + pL1(1);
    ym = RCLUSTER_INFO.dyMap(ym) + pL1(2);
    pm = [xm; ym; double(cm)'];

    pmF = o_mult(oF1, pm);
    pmF(3,:) = pm(3,:);
    map_filter(GMAP.im, GMAP.x, GMAP.y, pmF, mfilter);
  end
end



return;


%{
  cl = RCLUSTER{id};

  if isempty(cl), continue; end
  if (cl.nCluster <= 0), continue, end

  for i = 1:cl.nCluster,
    inode = cl.iNode(i)+RCLUSTER_INFO.nCluster/2; 
    oF1 = o_mult(RNODE{id}.pF(:,inode), ...
                 o_inv(RNODE{id}.pL(:,inode)));
    pm = o_mult(oF1, RCLUSTER{id}.pMap{i});
    pm(3,:) = RCLUSTER{id}.pMap{i}(3,:);
    map_filter(GMAP.im, GMAP.x, GMAP.y, pm, 0.2);
  end

  inode = RCLUSTER{id}.iNode(end);
  oF1 = o_mult(RNODE{id}.pF(:,inode), ...
               o_inv(RNODE{id}.pL(:,inode)));
  GTRANSFORM{id} = oF1;

  [xm, ym, cm] = find(RCLUSTER{id}.mapCurrent);
  if ~isempty(xm),
    pL1 = RCLUSTER{id}.pL(:,end);
    xm = RCLUSTER_INFO.dxMap(xm) + pL1(1);
    ym = RCLUSTER_INFO.dyMap(ym) + pL1(2);
    pm = [xm; ym; double(cm)'];

    pmF = o_mult(oF1, pm);
    pmF(3,:) = pm(3,:);
    map_filter(GMAP.im, GMAP.x, GMAP.y, pmF, 0.2); 
  end

end
%}
