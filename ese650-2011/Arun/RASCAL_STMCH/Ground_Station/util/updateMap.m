function updateMap(incMap)
global MAP
datam = meters2cells([incMap.ys,incMap.xs],[MAP.ymin,MAP.xmin],MAP.res);

idx = sub2ind(size(MAP.map),datam(:,1),datam(:,2));
MAP.map(idx) = incMap.cs;
end