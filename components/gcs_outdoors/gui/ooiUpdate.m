function ooiUpdate()
global GDISPLAY OOI

if GDISPLAY.lastRegionSelection ~= -1
  tag = get(GDISPLAY.lastRegionSelection,'Tag');
  if tag(1)=='o'
    reg = str2double(tag(2:end));
    OOI(reg).type = GDISPLAY.selectedOOI;
    ooiOverlay();
  end
end
