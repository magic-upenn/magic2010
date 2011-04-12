function globalMapAvoid(xs,ys,x_corner,y_corner,serial)

global GDISPLAY GMAP AVOID_REGIONS

if nargin == 0
  [mask,x_corner,y_corner] = roipoly;
  [ys xs] = find(mask);
  serial = -1;
end

if(numel(x_corner) > 2)
  disp('avoid region...');
  AVOID_REGIONS(end+1).corner_x = x_corner;
  AVOID_REGIONS(end).corner_y = y_corner;
  AVOID_REGIONS(end).x = xs;
  AVOID_REGIONS(end).y = ys;
  ymap = y(GMAP);
  AVOID_REGIONS(end).y = AVOID_REGIONS(end).y'*resolution(GMAP) + ymap(1);
  xmap = x(GMAP);
  AVOID_REGIONS(end).x = AVOID_REGIONS(end).x'*resolution(GMAP) + xmap(1);
  AVOID_REGIONS(end).serial = serial;

  set(GDISPLAY.avoidRegionList,'String',1:length(AVOID_REGIONS));
  avoidRegionOverlay();
  sendAvoidRegions();
end
