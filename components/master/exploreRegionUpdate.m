function exploreRegionUpdate()
global GDISPLAY

if GDISPLAY.lastRegionSelection ~= -1
  tag = get(GDISPLAY.lastRegionSelection,'Tag');
  if tag(1)=='e'
    reg = str2double(tag(2:end));
    GDISPLAY.exploreRegions(reg).id = [];
    for i=1:length(GDISPLAY.robotRadioControl)
      if get(GDISPLAY.robotRadioControl{i},'Value')
        GDISPLAY.exploreRegions(reg).id(end+1) = i;
      end
    end
    GDISPLAY.exploreRegions(reg).template = GDISPLAY.selectedTemplate;
  end
end
