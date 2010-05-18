function PublishMapsToMotionPlanner
global OMAP EMAP

%This next bit needs to be done every few seconds to get a new path
%from Jon's planner.  My map has positive values being obstacles,
%negative values being free space and 0 being unknown.

%make 3 maps for the exploration planner
costmap = cmap;
costmap(costmap>50)=250;
costmap(costmap<=50)=0;
elevmap = [];
covmap  = [];

%send full update
full_update.timestamp    = GetUnixTime();
full_update.sent_cost_x  = size(costmap,1);
full_update.sent_cost_y  = size(costmap,2);
full_update.sent_elev_x  = 0;
full_update.sent_elev_y  = 0;
full_update.sent_cover_x = 0;
full_update.sent_cover_y = 0;
full_update.cost_map     = uint8(costmap);
full_update.elev_map     = int16(elevmap);
full_update.coverage_map = uint8(covmap);
ipcAPIPublishVC('Motion Planner Full Update',MagicGP_FULL_UPDATESerializer('serialize',full_update));
