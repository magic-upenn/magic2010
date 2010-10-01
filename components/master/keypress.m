function keypress(source,eventdata)

global GDISPLAY

switch(eventdata.Key)
case '1'
  if strcmp(get(GDISPLAY.robotRadioControl{1},'Enable'),'on')
    set(GDISPLAY.robotRadioControl{1},'Value',~get(GDISPLAY.robotRadioControl{1},'Value'));
  end
case '2'
  if strcmp(get(GDISPLAY.robotRadioControl{2},'Enable'),'on')
    set(GDISPLAY.robotRadioControl{2},'Value',~get(GDISPLAY.robotRadioControl{2},'Value'));
  end
case '3'
  if strcmp(get(GDISPLAY.robotRadioControl{3},'Enable'),'on')
    set(GDISPLAY.robotRadioControl{3},'Value',~get(GDISPLAY.robotRadioControl{3},'Value'));
  end
case '4'
  if strcmp(get(GDISPLAY.robotRadioControl{4},'Enable'),'on')
    set(GDISPLAY.robotRadioControl{4},'Value',~get(GDISPLAY.robotRadioControl{4},'Value'));
  end
case '5'
  if strcmp(get(GDISPLAY.robotRadioControl{5},'Enable'),'on')
    set(GDISPLAY.robotRadioControl{5},'Value',~get(GDISPLAY.robotRadioControl{5},'Value'));
  end
case '6'
  if strcmp(get(GDISPLAY.robotRadioControl{6},'Enable'),'on')
    set(GDISPLAY.robotRadioControl{6},'Value',~get(GDISPLAY.robotRadioControl{6},'Value'));
  end
case '7'
  if strcmp(get(GDISPLAY.robotRadioControl{7},'Enable'),'on')
    set(GDISPLAY.robotRadioControl{7},'Value',~get(GDISPLAY.robotRadioControl{7},'Value'));
  end
case '8'
  if strcmp(get(GDISPLAY.robotRadioControl{8},'Enable'),'on')
    set(GDISPLAY.robotRadioControl{8},'Value',~get(GDISPLAY.robotRadioControl{8},'Value'));
  end
case '9'
  if strcmp(get(GDISPLAY.robotRadioControl{9},'Enable'),'on')
    set(GDISPLAY.robotRadioControl{9},'Value',~get(GDISPLAY.robotRadioControl{9},'Value'));
  end
case 'hyphen'
  selectNone();
case 'equal'
  selectAll();
case 'q'
  globalMapStop();
case 'w'
  globalMapGoToPoint();
case 'e'
  globalMapExplore();
case 'r'
  globalMapExploreRegion();
case 't'
  globalMapAvoid();
case 'a'
  set(GDISPLAY.exploreOverlay,'Value',~get(GDISPLAY.exploreOverlay,'Value'));
  exploreRegionOverlay();
case 's'
  set(GDISPLAY.avoidOverlay,'Value',~get(GDISPLAY.avoidOverlay,'Value'));
  avoidRegionOverlay();
case 'd'
  set(GDISPLAY.UAVOverlay,'Value',~get(GDISPLAY.UAVOverlay,'Value'));
  UAVOverlay();
case 'f'
  set(GDISPLAY.gridOverlay,'Value',~get(GDISPLAY.gridOverlay,'Value'));
  gridOverlay();
case 'delete'
  if GDISPLAY.lastRegionSelection ~= -1
    tag = get(GDISPLAY.lastRegionSelection,'Tag');
    if tag(1)=='e'
      set(GDISPLAY.exploreRegionList,'Value',str2double(tag(2:end)));
      exploreRegionDelete();
    elseif tag(1)=='a'
      set(GDISPLAY.avoidRegionList,'Value',str2double(tag(2:end)));
      avoidRegionDelete();
    end
  end
end

