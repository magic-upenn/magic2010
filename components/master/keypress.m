function keypress(source,eventdata)

global GDISPLAY

switch(eventdata.Key)
case '1'
  set(GDISPLAY.robotRadioControl{1},'Value',~get(GDISPLAY.robotRadioControl{1},'Value'));
case '2'
  set(GDISPLAY.robotRadioControl{2},'Value',~get(GDISPLAY.robotRadioControl{2},'Value'));
case '3'
  set(GDISPLAY.robotRadioControl{3},'Value',~get(GDISPLAY.robotRadioControl{3},'Value'));
case '4'
  set(GDISPLAY.robotRadioControl{4},'Value',~get(GDISPLAY.robotRadioControl{4},'Value'));
case '5'
  set(GDISPLAY.robotRadioControl{5},'Value',~get(GDISPLAY.robotRadioControl{5},'Value'));
case '6'
  set(GDISPLAY.robotRadioControl{6},'Value',~get(GDISPLAY.robotRadioControl{6},'Value'));
case '7'
  set(GDISPLAY.robotRadioControl{7},'Value',~get(GDISPLAY.robotRadioControl{7},'Value'));
case '8'
  set(GDISPLAY.robotRadioControl{8},'Value',~get(GDISPLAY.robotRadioControl{8},'Value'));
case '9'
  set(GDISPLAY.robotRadioControl{9},'Value',~get(GDISPLAY.robotRadioControl{9},'Value'));
case 'hyphen'
  for i=1:length(GDISPLAY.robotRadioControl)
    set(GDISPLAY.robotRadioControl{i},'Value',0);
  end
case 'equal'
  for i=1:length(GDISPLAY.robotRadioControl)
    set(GDISPLAY.robotRadioControl{i},'Value',1);
  end
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

