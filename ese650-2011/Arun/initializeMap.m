function [] = initializeMap(las_ranges,las_angles,pitch,roll,yaw)
%initializeMap.m - initialize the map for the very first time and populate
%it with the points from the first laser scan
%INPUTS:
%   ANGL - a vector of 3 angles of the form [yaw;pitch;roll] which denotr
%          the robot's orientation wrt global frame
%
    global MAP

    MAP.res   = 0.05; %meters

    MAP.xmin  = -30;  %meters
    MAP.ymin  = -30;
    MAP.xmax  =  30;
    MAP.ymax  =  30;


    %dimensions of the map
    MAP.sizex  = ceil((MAP.xmax - MAP.xmin) / MAP.res + 1); %cells
    MAP.sizey  = ceil((MAP.ymax - MAP.ymin) / MAP.res + 1);

    MAP.map = zeros(MAP.sizex,MAP.sizey,'int8');
    
    % For computing correlation
    MAP.x_im = MAP.xmin:MAP.res:MAP.xmax; %x-positions of each pixel of the map
    MAP.y_im = MAP.ymin:MAP.res:MAP.ymax; %y-positions of each pixel of the map

    MAP.x_range_c = -0.1:MAP.res:0.1; % search space in x - coarse
    MAP.y_range_c = -0.1:MAP.res:0.1; % search space in y - coarse

    MAP.x_range_f = -0.05:MAP.res/2:0.05; % search space in x - fine
    MAP.y_range_f = -0.05:MAP.res/2:0.05; % search space in y - fine
    
    win_sz_c = numel(MAP.x_range_c);
    win_sz_f = numel(MAP.x_range_f);
    
    MAP.gaussian_c = fspecial('gaussian',win_sz_c,win_sz_c);
    MAP.gaussian_f = fspecial('gaussian',win_sz_f,win_sz_f);

    
    %assuming initial pose of x=0,y=0,yaw=0, put the first scan into the map
    %also, assume that roll and pitch are 0 (not true in general - use IMU!)


    %make the origin of the robot's frame at its geometrical center

    %sensor to body transform - distance of 514.35 mm along z-axis
    Tsensor = trans([0.13323 0 0.51435]);%*rotz(0)*roty(0)*rotx(0); % distance of 133.73 mm along the x-axis

    %transform for the imu reading (assuming zero for this example)
    Timu = rotz(yaw)*roty(pitch)*rotx(roll);

    %body to world transform (initially, one can assume it's zero)
    Tpose   = trans([0 0 0]);

    %full transform from lidar frame to world frame
    T = Tpose*Timu*Tsensor;
    
    %% Remove really small values and antennas from hokuyo scans
    las_ranges(975:1010) = 0;
    las_ranges(80:115) = 0;
    las_angles(975:1010) = 0;
    las_angles(80:115) = 0;
    las_angles = las_angles(las_ranges > 0.15);
    las_ranges = las_ranges(las_ranges > 0.15);
    
    %xy position in the sensor frame
    xs0 = (las_ranges.*cos(las_angles));
    ys0 = (las_ranges.*sin(las_angles));

    %convert to body frame using initial transformation
    X = [xs0;ys0;zeros(size(xs0)); ones(size(xs0))];
    Y=T*X;

    %transformed xs and ys
    xs1 = Y(1,:);
    ys1 = Y(2,:);

    %convert from meters to cells
    xis = ceil((xs1 - MAP.xmin) ./ MAP.res);
    yis = ceil((ys1 - MAP.ymin) ./ MAP.res);

    %check the indices and populate the map
    indGood = (xis > 1) & (yis > 1) & (xis < MAP.sizex) & (yis < MAP.sizey);
    inds = sub2ind(size(MAP.map),xis(indGood),yis(indGood));
    MAP.map(inds) = 100;

    %compute correlation
%     x_im = MAP.xmin:MAP.res:MAP.xmax; %x-positions of each pixel of the map
%     y_im = MAP.ymin:MAP.res:MAP.ymax; %y-positions of each pixel of the map
% 
%     x_range = -1:0.05:1;
%     y_range = -1:0.05:1;
% 
%     c = map_correlation(MAP.map,x_im,y_im,Y(1:3,:),x_range,y_range);

    %plot original lidar points
%     figure(10);
%     plot(xs1,ys1,'.')
% 
%     %plot map
%     figure(20);
%     imagesc(MAP.map);

%% antennae stuff in laser - 86:110, 983:999

end