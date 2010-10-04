function globalMapAvoid()

global GDISPLAY GMAP AVOID_REGIONS

[mask,x_corner,y_corner] = roipoly;
if(numel(x_corner) > 2)
  disp('avoid region...');
  AVOID_REGIONS(end+1).corner_x = x_corner;
  AVOID_REGIONS(end).corner_y = y_corner;
  [AVOID_REGIONS(end).y AVOID_REGIONS(end).x] = find(mask);
  ymap = y(GMAP);
  AVOID_REGIONS(end).y = AVOID_REGIONS(end).y'*resolution(GMAP) + ymap(1);
  xmap = x(GMAP);
  AVOID_REGIONS(end).x = AVOID_REGIONS(end).x'*resolution(GMAP) + xmap(1);

  set(GDISPLAY.avoidRegionList,'String',1:length(AVOID_REGIONS));
  avoidRegionOverlay();
  sendAvoidRegions();
end
