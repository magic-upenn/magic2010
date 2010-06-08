function PublishMapsToExplorationPlanner
global ROBOTS OMAP CMAP

if(isempty(ROBOTS(2).pose))
  return;
end

imagesc(CMAP.map.data);
temp = 100;
pos_y = (ROBOTS(2).pose.data.x-CMAP.xmin)/CMAP.res;
pos_x = (ROBOTS(2).pose.data.y-CMAP.xmin)/CMAP.res;
axis xy equal;
axis([pos_x-temp pos_x+temp pos_y-temp pos_y+temp]);


%make 3 maps for the exploration planner
costmap = CMAP.map.data;
obs_thresh = 50;
costmap(costmap>obs_thresh)=250;
costmap(costmap<=obs_thresh)=0;
elevmap = costmap*4;
covmap = CMAP.map.data;
covmap(covmap ~= 0)=249;
%covmap(covmap~=0) = 249;
%{
    imagesc(costmap');
    colormap gray;
    hold on;
    tempX = (SLAM.x-EMAP.xmin)*EMAP.invRes;
    tempY = (SLAM.y-EMAP.ymin)*EMAP.invRes;
    plot(tempX,tempY,'bx');
    temp = 20*EMAP.invRes;
    axis([tempX-temp tempX+temp tempY-temp tempY+temp]);
    axis xy;
    drawnow;
%}
%send full update
full_update.timestamp = GetUnixTime();
full_update.sent_cost_x = size(costmap,1);
full_update.sent_cost_y = size(costmap,2);
full_update.sent_elev_x = size(elevmap,1);
full_update.sent_elev_y = size(elevmap,2);
full_update.sent_cover_x = size(covmap,1);
full_update.sent_cover_y = size(covmap,2);
full_update.cost_map = uint8(costmap);
full_update.elev_map = int16(elevmap);
full_update.coverage_map = uint8(covmap);
full_update.UTM_x = OMAP.xmin;
full_update.UTM_y = OMAP.ymin;

%send pose
position_update.timestamp = GetUnixTime();
%position_update.x = ceil((SLAM.x-OMAP.xmin)*OMAP.invRes);
%position_update.y = ceil((SLAM.y-OMAP.ymin)*OMAP.invRes);
position_update.x = ROBOTS(2).pose.data.x;
position_update.y = ROBOTS(2).pose.data.y;
position_update.theta = ROBOTS(2).pose.data.yaw;
ipcAPI('publishVC','Global_Planner_Position_Update',MagicGP_POSITION_UPDATESerializer('serialize',position_update));
ipcAPI('publishVC','Global_Planner_Full_Update',MagicGP_FULL_UPDATESerializer('serialize',full_update));

