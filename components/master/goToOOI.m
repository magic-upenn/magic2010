function goToOOI(xg,yg,r,avoid_mask,ids,serial)

global GDISPLAY ROBOTS GMAP GPOSE AVOID_REGIONS

map_cell_size = resolution(GMAP);
[map_size_x, map_size_y] = size(GMAP);
xmap = x(GMAP);
UTM_x = xmap(1);
ymap = y(GMAP);
UTM_y = ymap(1);

th = 0:0.1:2*pi;
x_corners = (r*cos(th))+xg;
y_corners = (r*sin(th))+yg;

%{
x_min = round((xg-UTM_x-r)/map_cell_size);
x_max = round((xg-UTM_x+r)/map_cell_size);
y_min = round((yg-UTM_y-r)/map_cell_size);
y_max = round((yg-UTM_y+r)/map_cell_size);

temp_x = x_min:x_max;
temp_y = y_min:y_max;

xs = repmat(temp_x,length(temp_y),1);
xs = xs(:);

ys = repmat(temp_y,1,length(temp_x))';
%}

%use the mask to get the cells in the avoid region and remove any that are off the map
x_cells = (xg-UTM_x)/map_cell_size + avoid_mask.x;
y_cells = (yg-UTM_y)/map_cell_size + avoid_mask.y;
onMap = (x_cells>0)&(x_cells<=map_size_x)&(y_cells>0)&(y_cells<=map_size_y);
x_cells = x_cells(onMap);
y_cells = y_cells(onMap);

globalMapAvoid(x_cells,y_cells,x_corners,y_corners,serial);

costmap = double(getdata(GMAP, 'cost'));
for i = 1:length(AVOID_REGIONS)
  costmap(sub2ind(size(costmap),round((AVOID_REGIONS(i).x-UTM_x)/map_cell_size), ...
           round((AVOID_REGIONS(i).y-UTM_y)/map_cell_size))) = 100;
end

best_path = [];
best_id = -1;
for id = ids
  path = globalGoToPoint(costmap,[GPOSE{id}.x GPOSE{id}.y],[xg, yg],[UTM_x, UTM_y],sqrt(2)*0.25,map_cell_size);
  if(numel(path) > 0 && (isempty(best_path) || size(path,2)<size(best_path,2)))
    best_path = path;
    best_id = id;
  end
end

if isempty(best_path)
  disp('Could not dispatch robot to OOI!');
  return;
end

%prune path to not get too close!
prune_amount = round(r/map_cell_size);
if(size(best_path,2)<=prune_amount)
  %the robot is already close enough, so just send a stop command
  sendStateEvent(best_id,'stop');
else
  best_path = best_path(:,1:end-prune_amount);
  [xr yr] = gpos_to_rpos(best_id, best_path(1,:)', best_path(2,:)')
  PATH = [xr yr];
  msgName = ['Robot',num2str(best_id),'/Goal_Point'];
  ROBOTS(best_id).ipcAPI('publish', msgName, serialize(PATH));
end

