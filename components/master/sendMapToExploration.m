function sendMapToExploration
global GPOSE GMAP gcs_machine

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