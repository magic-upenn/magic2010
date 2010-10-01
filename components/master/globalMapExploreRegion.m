function globalMapExploreRegion()

global GDISPLAY GMAP

[mask,x_corner,y_corner] = roipoly;
if(numel(x_corner) > 2)
  disp('explore region...');
  GDISPLAY.exploreRegions(end+1).id = [];
  for i=1:length(GDISPLAY.robotRadioControl)
    if get(GDISPLAY.robotRadioControl{i},'Value')
      GDISPLAY.exploreRegions(end).id(end+1) = i;
    end
  end
  GDISPLAY.exploreRegions(end).template = GDISPLAY.selectedTemplate;
  [GDISPLAY.exploreRegions(end).y GDISPLAY.exploreRegions(end).x] = find(mask);
  ymap = y(GMAP);
  GDISPLAY.exploreRegions(end).y = GDISPLAY.exploreRegions(end).y*resolution(GMAP) + ymap(1);
  xmap = x(GMAP);
  GDISPLAY.exploreRegions(end).x = GDISPLAY.exploreRegions(end).x*resolution(GMAP) + xmap(1);
  GDISPLAY.exploreRegions(end).corner_x = x_corner;
  GDISPLAY.exploreRegions(end).corner_y = y_corner;

  set(GDISPLAY.exploreRegionList,'String',1:length(GDISPLAY.exploreRegions));
  exploreRegionOverlay();
end
