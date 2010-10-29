function exploreRegionUpdate()
global GDISPLAY EXPLORE_REGIONS

if GDISPLAY.lastRegionSelection ~= -1
  tag = get(GDISPLAY.lastRegionSelection,'Tag');
  if tag(1)=='e'
    reg = str2double(tag(2:end));
    EXPLORE_REGIONS(reg).id = [];
    for i=1:length(GDISPLAY.robotRadioControl)
      if get(GDISPLAY.robotRadioControl{i},'Value')
        EXPLORE_REGIONS(reg).id(end+1) = i;
      end
    end
    EXPLORE_REGIONS(reg).template = GDISPLAY.selectedTemplate;
  end
end
