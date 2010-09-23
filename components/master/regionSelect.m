function regionSelect(src,eventdata)
global GDISPLAY

set(src,'Selected','on');
if GDISPLAY.lastRegionSelection ~= -1
  set(GDISPLAY.lastRegionSelection,'Selected','off');
end
GDISPLAY.lastRegionSelection = src;
