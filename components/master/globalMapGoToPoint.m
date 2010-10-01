function globalMapGoToPoint()

global GDISPLAY ROBOTS

[xp, yp] = ginput(1);

if ~isempty(xp),
%{
    map_cell_size = resolution(GMAP);
    [map_size_x, map_size_y] = size(GMAP);
    xmap = x(GMAP);
    UTM_x = xmap(1);
    ymap = y(GMAP);
    UTM_y = ymap(1);

    costmap = double(getdata(GMAP, 'cost'));
    for i = 1:length(GDISPLAY.avoidRegions)
      costmap(round((GDISPLAY.avoidRegions(i).x-UTM_x)/map_cell_size), ...
              round((GDISPLAY.avoidRegions(i).y-UTM_y)/map_cell_size)) = 100;
    end

    path = a_star(costmap,[GPOSE{id}.x GPOSE{id}.y],[xp, yp]);
    if(numel(path) == 0)
        fprintf('search failed\n');
        return
    end

    [xr yr] = gpos_to_rpos(GDISPLAY.selectedRobot, path(:,1), path(:,2));
%}
  for i=1:length(GDISPLAY.robotRadioControl)
    if get(GDISPLAY.robotRadioControl{i},'Value')
      [xr yr] = gpos_to_rpos(i, xp(1), yp(1));
      PATH = [xr yr];
      msgName = ['Robot',num2str(i),'/Goal_Point'];
      ROBOTS(i).ipcAPI('publish', msgName, serialize(PATH));
    end
  end
end

