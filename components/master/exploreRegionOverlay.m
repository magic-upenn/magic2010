function exploreRegionOverlay()
global GDISPLAY EXPLORE_REGIONS

GDISPLAY.lastRegionSelection = -1;

for i=1:length(GDISPLAY.visualExploreText)
  delete(GDISPLAY.visualExploreText(i));
  delete(GDISPLAY.visualExploreOverlay(i));
end
GDISPLAY.visualExploreText = [];
GDISPLAY.visualExploreOverlay = [];

if get(GDISPLAY.exploreOverlay,'Value')
  set(0,'CurrentFigure',GDISPLAY.hFigure);
  for i=1:length(EXPLORE_REGIONS)
    temp_x = EXPLORE_REGIONS(i).corner_x;
    temp_y = EXPLORE_REGIONS(i).corner_y;
    GDISPLAY.visualExploreOverlay(i) = patch(temp_x,temp_y,[0 0 1],'ButtonDownFcn',@regionSelect,'Tag',strcat('e',num2str(i)),'FaceAlpha',0.3);
    GDISPLAY.visualExploreText(i) = text(mean(temp_x),mean(temp_y),num2str(i),'FontSize',30);
  end
end

