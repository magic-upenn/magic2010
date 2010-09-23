function avoidRegionOverlay()
global GDISPLAY

GDISPLAY.lastRegionSelection = -1;

for i=1:length(GDISPLAY.visualAvoidText)
  delete(GDISPLAY.visualAvoidText(i));
  delete(GDISPLAY.visualAvoidOverlay(i));
end
GDISPLAY.visualAvoidText = [];
GDISPLAY.visualAvoidOverlay = [];

if get(GDISPLAY.avoidOverlay,'Value')
  %max_corners = 0;
  %for i=1:length(GDISPLAY.exploreRegions)
    %max_corners = max(max_corners, length(GDISPLAY.exploreRegions(i).corner_x));
  %end
  %x_corners = [];
  %y_corners = [];
  set(0,'CurrentFigure',GDISPLAY.hFigure);
  for i=1:length(GDISPLAY.avoidRegions)
    %offset = max_corners - length(GDISPLAY.exploreRegions(i).corner_x);
    temp_x = GDISPLAY.avoidRegions(i).corner_x;%;[GDISPLAY.exploreRegions(i).corner_x; ones(offset,1)*GDISPLAY.exploreRegions(i).corner_x(end)];
    temp_y = GDISPLAY.avoidRegions(i).corner_y;%;[GDISPLAY.exploreRegions(i).corner_y; ones(offset,1)*GDISPLAY.exploreRegions(i).corner_y(end)];
    %x_corners = [x_corners temp_x];
    %y_corners = [y_corners temp_y];
    GDISPLAY.visualAvoidOverlay(i) = patch(temp_x,temp_y,[1 0 0],'ButtonDownFcn',@regionSelect,'Tag',strcat('a',num2str(i)));
    GDISPLAY.visualAvoidText(i) = text(mean(temp_x),mean(temp_y),num2str(i),'FontSize',30);
  end
  %set(GDISPLAY.visualExploreOverlay, 'XData', x_corners, 'YData', y_corners, 'Visible', 'on');
else
  %set(GDISPLAY.visualExploreOverlay, 'Visible', 'off');
end

