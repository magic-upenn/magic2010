function exploreRegionDelete()
global GDISPLAY

if length(GDISPLAY.exploreRegions) == 0
  return;
end

id = get(GDISPLAY.exploreRegionList,'Value');

if length(GDISPLAY.exploreRegions) == 1
  GDISPLAY.exploreRegions = [];
elseif id == length(GDISPLAY.exploreRegions)
  GDISPLAY.exploreRegions = GDISPLAY.exploreRegions(1:end-1);
  set(GDISPLAY.exploreRegionList,'Value',id-1);
elseif id == 1
  GDISPLAY.exploreRegions = GDISPLAY.exploreRegions(2:end);
else
  GDISPLAY.exploreRegions = [GDISPLAY.exploreRegions(1:id-1) GDISPLAY.exploreRegions(id+1:end)];
end

set(GDISPLAY.exploreRegionList,'String',1:length(GDISPLAY.exploreRegions));

exploreRegionOverlay();
