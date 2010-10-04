function regionSelect(src,eventdata)
global GDISPLAY EXPLORE_REGIONS

if GDISPLAY.lastRegionSelection ~= -1
  set(GDISPLAY.lastRegionSelection,'Selected','off');
end
set(src,'Selected','on');
GDISPLAY.lastRegionSelection = src;


tag = get(GDISPLAY.lastRegionSelection,'Tag');
if tag(1)=='e'
  for i=1:length(GDISPLAY.robotRadioControl)
    set(GDISPLAY.robotRadioControl{i},'Value',0);
  end

  reg = str2double(tag(2:end));
  for id = EXPLORE_REGIONS(reg).id
    set(GDISPLAY.robotRadioControl{id},'Value',1);
  end

  set(GDISPLAY.templateGroup,'SelectedObject',GDISPLAY.templateControl{EXPLORE_REGIONS(reg).template});
  GDISPLAY.selectedTemplate = EXPLORE_REGIONS(reg).template;
end

