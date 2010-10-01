function globalMapGoToPoint()

global GDISPLAY ROBOTS GMAP GPOSE

[xp, yp] = ginput(1);

if ~isempty(xp),
  for id=1:length(GDISPLAY.robotRadioControl)
    if get(GDISPLAY.robotRadioControl{id},'Value')

      map_cell_size = resolution(GMAP);
      [map_size_x, map_size_y] = size(GMAP);
      xmap = x(GMAP);
      UTM_x = xmap(1);
      ymap = y(GMAP);
      UTM_y = ymap(1);

      costmap = double(getdata(GMAP, 'cost'));
      for i = 1:length(GDISPLAY.avoidRegions)
        costmap(sub2ind(size(costmap),round((GDISPLAY.avoidRegions(i).x-UTM_x)/map_cell_size), ...
                 round((GDISPLAY.avoidRegions(i).y-UTM_y)/map_cell_size))) = 100;
      end

      path = globalGoToPoint(costmap,[GPOSE{id}.x GPOSE{id}.y],[xp, yp],[UTM_x, UTM_y],sqrt(2)*0.25,map_cell_size)
      if(numel(path) == 0)
          disp('search failed\n');
          return
      end

      [xr yr] = gpos_to_rpos(id, path(1,:)', path(2,:)')

      %[xr yr] = gpos_to_rpos(id, xp(1), yp(1));
      PATH = [xr yr];
      msgName = ['Robot',num2str(id),'/Goal_Point'];
      ROBOTS(id).ipcAPI('publish', msgName, serialize(PATH));
    end
  end
end

