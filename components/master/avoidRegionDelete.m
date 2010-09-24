function avoidRegionDelete()
global GDISPLAY

if length(GDISPLAY.avoidRegions) == 0
  return;
end

id = get(GDISPLAY.avoidRegionList,'Value');

if length(GDISPLAY.avoidRegions) == 1
  GDISPLAY.avoidRegions = [];
elseif id == length(GDISPLAY.avoidRegions)
  GDISPLAY.avoidRegions = GDISPLAY.avoidRegions(1:end-1);
  set(GDISPLAY.avoidRegionList,'Value',id-1);
elseif id == 1
  GDISPLAY.avoidRegions = GDISPLAY.avoidRegions(2:end);
else
  GDISPLAY.avoidRegions = [GDISPLAY.avoidRegions(1:id-1) GDISPLAY.avoidRegions(id+1:end)];
end

set(GDISPLAY.avoidRegionList,'String',1:length(GDISPLAY.avoidRegions));

avoidRegionOverlay();
sendAvoidRegions();
