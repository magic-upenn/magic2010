function sendMapToExploration
global GPOSE GMAP gcs_machine GTRANSFORM GCS GDISPLAY EXPLORE_TEMPLATES EXPLORE_REGIONS AVOID_REGIONS

data.NR = max(GCS.ids);
data.GP_PLAN_TIME = 0.5;
data.DIST_GAIN = 0.5;
data.MIN_RANGE = 15;
data.MAX_RANGE = 50;
data.DIST_PENALTY = 1;
data.REGION_PENALTY = 0.0001;
data.map_cell_size = resolution(GMAP);
[data.map_size_x, data.map_size_y] = size(GMAP);
xmap = x(GMAP);
data.UTM_x = xmap(1);
ymap = y(GMAP);
data.UTM_y = ymap(1);

data.map = double(getdata(GMAP, 'cost'));
for i = 1:length(AVOID_REGIONS)
  data.map(sub2ind(size(data.map),round((AVOID_REGIONS(i).x-data.UTM_x)/data.map_cell_size), ...
           round((AVOID_REGIONS(i).y-data.UTM_y)/data.map_cell_size))) = 100;
end

data.region_map = uint8(zeros(size(GMAP)));
data.bias_table = zeros(data.NR+2,length(EXPLORE_REGIONS)+1);
data.num_states = data.NR+2;
data.num_regions = length(EXPLORE_REGIONS)+1;
data.bias_table(1:end-2,1) = 1;
for i = 1:length(EXPLORE_REGIONS)
  region_x = round((EXPLORE_REGIONS(i).x-data.UTM_x)/data.map_cell_size);
  region_y = round((EXPLORE_REGIONS(i).y-data.UTM_y)/data.map_cell_size);
  region_idx = sub2ind(size(data.region_map),region_x,region_y);
  data.region_map(region_idx) = i;

  if isempty(EXPLORE_REGIONS(i).id)
    data.bias_table(end-1,i+1) = EXPLORE_TEMPLATES(EXPLORE_REGIONS(i).template).in_robots;
    data.bias_table(end,i+1) = EXPLORE_TEMPLATES(EXPLORE_REGIONS(i).template).out_robots;
  else
    data.bias_table(1:data.NR,i+1) = EXPLORE_TEMPLATES(EXPLORE_REGIONS(i).template).out_robots;
    data.bias_table(EXPLORE_REGIONS(i).id,i+1) = EXPLORE_TEMPLATES(EXPLORE_REGIONS(i).template).in_robots;
  end
end

data.avail = int16(zeros(data.NR,1));
data.x =     zeros(data.NR,1);
data.y =     zeros(data.NR,1);
data.theta = zeros(data.NR,1);

for id = GCS.sensor_ids
  %if strcmp(get(GDISPLAY.robotStatusText{id},'String'),'sExplore')
  data.avail(id) = 1;
  %end
end
for id = GCS.ids
  if ~isempty(GPOSE{id})
    data.x(id) = GPOSE{id}.x;
    data.y(id) = GPOSE{id}.y;
    data.theta(id) = GPOSE{id}.yaw;
  end
end

gcs_machine.ipcAPI('publishVC','Global_Planner_DATA',MagicGP_DATASerializer('serialize',data));

