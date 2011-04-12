function avoidRegionOverlay()
global GDISPLAY AVOID_REGIONS

GDISPLAY.lastRegionSelection = -1;

for i=1:length(GDISPLAY.visualAvoidText)
  delete(GDISPLAY.visualAvoidText(i));
  delete(GDISPLAY.visualAvoidOverlay(i));
end
GDISPLAY.visualAvoidText = [];
GDISPLAY.visualAvoidOverlay = [];

if get(GDISPLAY.avoidOverlay,'Value')
  set(0,'CurrentFigure',GDISPLAY.hFigure);
  for i=1:length(AVOID_REGIONS)
    temp_x = AVOID_REGIONS(i).corner_x;
    temp_y = AVOID_REGIONS(i).corner_y;
    GDISPLAY.visualAvoidOverlay(i) = patch(temp_x,temp_y,[1 0 0],'ButtonDownFcn',@regionSelect,'Tag',strcat('a',num2str(i)),'FaceAlpha',0.3);
    GDISPLAY.visualAvoidText(i) = text(temp_x(1)+1,temp_y(1)+1,num2str(i),'FontSize',30);
  end
end

