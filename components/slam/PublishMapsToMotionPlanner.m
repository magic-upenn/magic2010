function PublishMapsToMotionPlanner
global SLAM OMAP

%make 3 maps for the exploration planner
costmap = OMAP.map.data;
costmap(costmap>50)=250;
costmap(costmap<=50)=0;
%{
    imagesc(costmap');
    colormap gray;
    hold on;
    tempX = (SLAM.x-OMAP.xmin)*OMAP.invRes;
    tempY = (SLAM.y-OMAP.ymin)*OMAP.invRes;
    plot(tempX,tempY,'bx');
    temp = 20*OMAP.invRes;
    axis([tempX-temp tempX+temp tempY-temp tempY+temp]);
    axis xy;
    drawnow;
%}

%send full update
full_update.timestamp = GetUnixTime();
full_update.sent_cost_x = size(costmap,1);
full_update.sent_cost_y = size(costmap,2);
full_update.sent_elev_x = 1;
full_update.sent_elev_y = 1;
full_update.sent_cover_x = 1;
full_update.sent_cover_y = 1;
full_update.cost_map = uint8(costmap);
full_update.elev_map = int16(0);
full_update.coverage_map = uint8(0);
full_update.UTM_x = OMAP.xmin;
full_update.UTM_y = OMAP.ymin;
ipcAPIPublishVC('Lattice Planner Full Update',MagicGP_FULL_UPDATESerializer('serialize',full_update));

%send pose
position_update.timestamp = GetUnixTime();
%position_update.x = ceil((SLAM.x-OMAP.xmin)*OMAP.invRes);
%position_update.y = ceil((SLAM.y-OMAP.ymin)*OMAP.invRes);
position_update.x = SLAM.x;
position_update.y = SLAM.y;
position_update.theta = SLAM.yaw;
ipcAPIPublishVC('Lattice Planner Position Update',MagicGP_POSITION_UPDATESerializer('serialize',position_update));
