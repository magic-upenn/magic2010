function exploreRegionDelete()
global GDISPLAY EXPLORE_REGIONS

if length(EXPLORE_REGIONS) == 0
  return;
end

id = get(GDISPLAY.exploreRegionList,'Value');

if length(EXPLORE_REGIONS) == 1
  EXPLORE_REGIONS = [];
elseif id == length(EXPLORE_REGIONS)
  EXPLORE_REGIONS = EXPLORE_REGIONS(1:end-1);
  set(GDISPLAY.exploreRegionList,'Value',id-1);
elseif id == 1
  EXPLORE_REGIONS = EXPLORE_REGIONS(2:end);
else
  EXPLORE_REGIONS = [EXPLORE_REGIONS(1:id-1) EXPLORE_REGIONS(id+1:end)];
end

set(GDISPLAY.exploreRegionList,'String',1:length(EXPLORE_REGIONS));

exploreRegionOverlay();
