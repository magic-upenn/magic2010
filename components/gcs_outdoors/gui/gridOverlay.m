function gridOverlay()
global GDISPLAY

if get(GDISPLAY.gridOverlay,'Value')
  set(GDISPLAY.hAxes,'XGrid','on','YGrid','on','XMinorGrid','on','YMinorGrid','on');
else
  set(GDISPLAY.hAxes,'XGrid','off','YGrid','off','XMinorGrid','off','YMinorGrid','off');
end
