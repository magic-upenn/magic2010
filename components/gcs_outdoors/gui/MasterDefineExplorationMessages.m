function MasterDefineExplorationMessages
SetMagicPaths;

global OMAP EMAP

ipcAPI('define','Global_Planner_Map_Initialization',MagicGP_MAP_DATASerializer('getFormat'));
ipcAPI('define','Global_Planner_Robot_Parameters',  MagicGP_ROBOT_PARAMETERSerializer('getFormat'));
ipcAPI('define','Global_Planner_Full_Update',       MagicGP_FULL_UPDATESerializer('getFormat'));
ipcAPI('define','Global_Planner_Position_Update',   MagicGP_POSITION_UPDATESerializer('getFormat'));

%initialze map over IPC
map_init.timestamp = GetUnixTime();
map_init.cost_size_x = size(OMAP.map.data,1);
map_init.cost_size_y = size(OMAP.map.data,2);
map_init.elev_size_x = size(OMAP.map.data,1);
map_init.elev_size_y = size(OMAP.map.data,2);
map_init.coverage_size_x = size(EMAP.map.data,1);
map_init.coverage_size_y = size(EMAP.map.data,2);
map_init.cost_cell_size = OMAP.res;
map_init.elev_cell_size = OMAP.res;
map_init.coverage_cell_size = EMAP.res;
ipcAPI('publishVC','Global_Planner_Map_Initialization',MagicGP_MAP_DATASerializer('serialize',map_init));

%send robot parameters over IPC
robot_params.MAX_VELOCITY = 1.0;
robot_params.MAX_TURN_RATE = pi;
robot_params.I_DIMENSION = 4;
robot_params.J_DIMENSION = 2;
robot_params.sensor_radius = 30;
robot_params.sensor_height = 62.8;
robot_params.PerimeterArray = [1;1;1;-1;-1;-1;-1;1]*0.25;
ipcAPI('publishVC','Global_Planner_Robot_Parameters',MagicGP_ROBOT_PARAMETERSerializer('serialize',robot_params));
