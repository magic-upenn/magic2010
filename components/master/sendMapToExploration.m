function sendMapToExploration
global GPOSE GMAP gcs_machine GTRANSFORM GCS

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
data.region_map = uint8(zeros(size(GMAP)));

data.avail = int16(zeros(data.NR,1));
data.x =     zeros(data.NR,1);
data.y =     zeros(data.NR,1);
data.theta = zeros(data.NR,1);

for id = GCS.ids
  data.avail(id) = 1;
  if ~isempty(GPOSE{id})
    data.x(id) = GPOSE{id}.x;
    data.y(id) = GPOSE{id}.y;
    data.theta(id) = GPOSE{id}.yaw;
  end
end

gcs_machine.ipcAPI('publishVC','Global_Planner_DATA',MagicGP_DATASerializer('serialize',data));

%{
modpose.x1 = 0;
modpose.x2 = 0;
modpose.x3 = 0;

modpose.y1 = 0;
modpose.y2 = 0;
modpose.y3 = 0;

modpose.theta1 = 0;
modpose.theta2 = 0;
modpose.theta3 = 0;

if ~isempty(GPOSE{1})
        modpose.x1 = GPOSE{1}.x;
modpose.y1 = GPOSE{1}.y;
modpose.theta1 = GPOSE{1}.yaw;

    if (~isempty(GTRANSFORM) && GTRANSFORM{1}.init)
      GTRANSFORM{1}.dx
      GTRANSFORM{1}.dy
      GTRANSFORM{1}.dyaw
    end
end

if ~isempty(GPOSE{2})
        modpose.x2 = GPOSE{2}.x;
modpose.y2 = GPOSE{2}.y;
modpose.theta2 = GPOSE{2}.yaw;
end

if ~isempty(GPOSE{3})
        modpose.x3 = GPOSE{3}.x
modpose.y3 = GPOSE{3}.y
modpose.theta3 = GPOSE{3}.yaw
end


[planMap.size_x, planMap.size_y] = size(GMAP);
  planMap.resolution = resolution(GMAP);
  xmap = x(GMAP);
  planMap.UTM_x = xmap(1);
  ymap = y(GMAP);
  planMap.UTM_y = ymap(1);
  planMap.map = int16(getdata(GMAP, 'cost'));
  


gcs_machine.ipcAPI('publishVC','Global_Planner_Magic_Map',MagicGP_MAGIC_MAPSerializer('serialize',planMap));
gcs_machine.ipcAPI('publishVC','Global_Planner_All_Pose_Update',MagicGP_ALL_POSE_UPDATESerializer('serialize',modpose));
  %}
