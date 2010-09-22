function globalMapExploreRegion()

global GDISPLAY

[x,y,mask,x_corner,y_corner] = roipoly;
if(numel(x_corner) > 1)
  disp('explore region...');
  %TODO: these x and y values will need to be converted from pixel coordinates to UTM so they are robust to changing map size
  GDISPLAY.exploreRegions(end+1).x = x;
  GDISPLAY.exploreRegions(end+1).y = y;
  GDISPLAY.exploreRegions(end+1).id = GDISPLAY.selectedRobot;
end
