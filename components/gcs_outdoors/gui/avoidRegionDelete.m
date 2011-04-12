function avoidRegionDelete()
global GDISPLAY AVOID_REGIONS

if length(AVOID_REGIONS) == 0
  return;
end

id = get(GDISPLAY.avoidRegionList,'Value');

if length(AVOID_REGIONS) == 1
  AVOID_REGIONS = [];
elseif id == length(AVOID_REGIONS)
  AVOID_REGIONS = AVOID_REGIONS(1:end-1);
  set(GDISPLAY.avoidRegionList,'Value',id-1);
elseif id == 1
  AVOID_REGIONS = AVOID_REGIONS(2:end);
else
  AVOID_REGIONS = [AVOID_REGIONS(1:id-1) AVOID_REGIONS(id+1:end)];
end

set(GDISPLAY.avoidRegionList,'String',1:length(AVOID_REGIONS));

avoidRegionOverlay();
sendAvoidRegions();
