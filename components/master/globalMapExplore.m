function globalMapExplore()

global GDISPLAY

pts = roipoly;
if(numel(pts) > 0)
  disp('explore region...');
end
sendStateEvent(GDISPLAY.selectedRobot,'explore');
