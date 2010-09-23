function globalMapAvoid()

global GDISPLAY GMAP

[mask,x_corner,y_corner] = roipoly;
if(numel(x_corner) > 2)
  disp('avoid region...');
  GDISPLAY.avoidRegions(end+1).corner_x = x_corner;
  GDISPLAY.avoidRegions(end).corner_y = y_corner;
  [GDISPLAY.avoidRegions(end).y GDISPLAY.avoidRegions(end).x] = find(mask);
  ymap = y(GMAP);
  GDISPLAY.avoidRegions(end).y = GDISPLAY.avoidRegions(end).y*resolution(GMAP) + ymap(1);
  xmap = x(GMAP);
  GDISPLAY.avoidRegions(end).x = GDISPLAY.avoidRegions(end).x*resolution(GMAP) + xmap(1);

  set(GDISPLAY.avoidRegionList,'String',1:length(GDISPLAY.avoidRegions));
  avoidRegionOverlay();
end
