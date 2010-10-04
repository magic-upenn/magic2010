function globalMapOOI()

global GDISPLAY GMAP OOI

[xp, yp] = ginput(1);
if ~isempty(xp),
  disp('adding ooi...');
  OOI(end+1).type = GDISPLAY.selectedOOI;
  OOI(end).x = xp;
  OOI(end).y = yp;

  set(GDISPLAY.ooiList,'String',1:length(OOI));
  ooiOverlay();
end
