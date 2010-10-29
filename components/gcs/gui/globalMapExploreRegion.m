function globalMapExploreRegion()

global GDISPLAY GMAP EXPLORE_REGIONS

[mask,x_corner,y_corner] = roipoly;
if(numel(x_corner) > 2)
  disp('explore region...');
  EXPLORE_REGIONS(end+1).id = [];
  for i=1:length(GDISPLAY.robotRadioControl)
    if get(GDISPLAY.robotRadioControl{i},'Value')
      EXPLORE_REGIONS(end).id(end+1) = i;
    end
  end
  EXPLORE_REGIONS(end).template = GDISPLAY.selectedTemplate;
  [EXPLORE_REGIONS(end).y EXPLORE_REGIONS(end).x] = find(mask);
  ymap = y(GMAP);
  EXPLORE_REGIONS(end).y = EXPLORE_REGIONS(end).y*resolution(GMAP) + ymap(1);
  xmap = x(GMAP);
  EXPLORE_REGIONS(end).x = EXPLORE_REGIONS(end).x*resolution(GMAP) + xmap(1);
  EXPLORE_REGIONS(end).corner_x = x_corner;
  EXPLORE_REGIONS(end).corner_y = y_corner;

  set(GDISPLAY.exploreRegionList,'String',1:length(EXPLORE_REGIONS));
  exploreRegionOverlay();
end
