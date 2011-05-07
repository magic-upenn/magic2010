function [state,dz] = correlateMap_nedit(las_ranges,las_angles,pitch,roll,state,dyaw,dx,dy,servo_angl)

%initializeMap.m - initialize the map for the very first time and populate
%it with the points from the first laser scan
%INPUTS:
%   ANGL - a vector of 3 angles of the form [yaw;pitch;roll] which denotr
%          the robot's orientation wrt global frame
%
    global MAP
    T_servotobody = trans([0.145 0 0.506]); % 144.775 0 506
    T_senstoservo = trans([0.056 0 0.028]); 
    
    Rservo = roty(servo_angl);

    Tpr = roty(pitch)*rotx(roll);
    Tyaw = rotz(state(3)+dyaw);
    A = Tyaw*Tpr*[dx;dy;0;1];
    dz = A(3);
    %% x,y and yaw values
    x_new = state(1) + A(1);
    y_new = state(2) + A(2);
    yaw_new = state(3) + dyaw;
    
%     x_new = state(1) + dx;
%     y_new = state(2) + dy;
%     yaw_new = state(3) + dyaw;
    %assuming initial pose of x=0,y=0,yaw=0, put the first scan into the map
    %also, assume that roll and pitch are 0 (not true in general - use
    %IMU!)
    %% Prop to yaw rate
%     ang_r = 0.5*dyaw; % +- 5 degrees search space for yaw angles
%     ang_step = deg2rad(0.1);
%     yaw_v = yaw_new-ang_r:ang_step:yaw_new+ang_r; % step of 1 degree
%     if(10*abs(ang_r) < ang_step)
%         yaw_v = yaw_new;
%     end
%% Based on yaw rate - do two different searches - one coarse and the next
%% finer
    if(abs(dyaw) > 0)%5e-4)
        %yaw_v_c = yaw_new-deg2rad(3):deg2rad(0.5):yaw_new+deg2rad(3); % coarse yaw ranges
        yaw_v_c = yaw_new-deg2rad(3):deg2rad(1):yaw_new+deg2rad(3); % coarse yaw ranges

    else
        yaw_v_c = yaw_new-deg2rad(1):deg2rad(0.5):yaw_new+deg2rad(1); % coarse yaw ranges
    end
    %sensor to body transform - distance of 514.35 mm along z-axis -
    %remains constant
    %Tsensor = trans([0.13323 0 0.51435]);%*rotz(0)*roty(0)*rotx(0); % distance of 133.23 mm along the x-axis
    
    %body to world transform (initially, one can assume it's zero)
    Tpose   = trans([x_new y_new 0]);
    
    %Orientation change due to pitch and roll 
    %Tpr = roty(pitch)*rotx(roll);
    
    %% Removing the ranges for the antennaes that obstruct the LIDAR
    %% Also, laser's minimum range is 0.1 m and if laser does not find
    %% object, it sets value to less than that... remove these as well
%     las_ranges(975:1010) = 0; % left antenna
%     las_ranges(80:115) = 0;% right antenna
%     las_angles(975:1010) = 0;
%     las_angles(80:115) = 0;
    las_angles = las_angles((las_ranges > 0.15)&(las_ranges<40));
    las_ranges = las_ranges((las_ranges > 0.15)&(las_ranges<40));
    
    %xy position in the sensor frame
    xs0 = (las_ranges.*cos(las_angles));
    ys0 = (las_ranges.*sin(las_angles));

    %convert to body frame using initial transformation
    X = [xs0;ys0;zeros(size(xs0)); ones(size(xs0))];
    
    %% Remove floors and ceilings
    %max(Yt(3,:))
    %X(4,:) = X(4,:).*((Yt(3,:) > -1.1));% & (Yt(3,:) < 2.5)); % values less than the base of robot & greater than the robot's height
    %    X(4,:) = X(4,:).*((Yt(3,:) > -0.13) & (Yt(3,:) < 0.53)); - works really good for 20. % values less than the base of robot & greater than the robot's height
%     X = X(repmat(X(4,:),4,1) ~=0);
%     X = reshape(X,4,numel(X)/4);
    Yt = Tpr*T_servotobody*Rservo*T_senstoservo*X;

    %pitch
    
%     if(abs(pitch) > 0.15)
%         %[min(Yt(3,:)) max(Yt(3,:))]
%         % 1.5 & -0.35
%         a = ((Yt(3,:) < 0.55) & (Yt(3,:) > 0) & (las_ranges' < 1.5)); %1.15 is best for dataset 22
%         Yt = Yt(:,a);
%     end
%     if(d_no == 21)
%         pt_lt = 0.15;
%     else
%         pt_lt = 0.2;
%     end
%     if(abs(pitch) > pt_lt)
%         %[min(Yt(3,:)) max(Yt(3,:))]
%         % 1.0 & 0 -ranges<=2 good for 22 - 0.2 pitch
%         % 1.0 & 0 -ranges<=2 good for 21 - 0.15 pitch
%         % 1.0 & 0 -ranges<=2 good for 20 - 0.2 pitch - wdt the other way works best
%         % 0.75 & 0 -ranges<=2 good for 23 - 0.15 pitch
%         
%         a = ((Yt(3,:) < 1) & (Yt(3,:) > 0) & (las_ranges' <= 2)); %1.15 is best for dataset 22
%         Yt = Yt(:,a);
%         X = X(:,a);
%     end
    c = zeros(numel(MAP.x_range_c),numel(MAP.y_range_c),numel(yaw_v_c));

    %% FInd the best pose that matches the current LIDAR scan - first do a
    %% coarse match
    for k = 1:numel(yaw_v_c)
        %make the origin of the robot's frame at its geometrical center

        %transform for the imu reading (assuming zero for this example)
        %Timu = rotz(yaw_v_c(k))*Tpr; % yaw*pitch*roll - orientation of the body frame w.r.t the world frame
        Tyaw = rotz(yaw_v_c(k));
        %full transform from lidar frame to world frame 
        % Tpose - just the translation from the body frame to the world frame
        %T = [ Timu(1:3,1:3) [x_new;y_new;0]; 0 0 0 1] *Tsensor; % first part is Tpose*Timu - which can be written as [R T; 0 1] - a homogeneous matrix
        %T = Tpose*Timu*Tsensor;
        Y=Tpose*Tyaw*Yt;

        c(:,:,k) = map_correlation(MAP.map,MAP.x_im,MAP.y_im,Y(1:3,:),MAP.x_range_c,MAP.y_range_c);
        %max(max(c(:,:,k)))
        %c(3,3,k) = c(3,3,k) + max(max(c(:,:,k)))/1000; 
        %c(:,:,k) = c(:,:,k).*MAP.gaussian_c;%*(max(max(c(:,:,k)))/100);
        
    end
    
    [a,ind] = max(c(:));
    [xv_c,yv_c,thv] = ind2sub(size(c),ind);
    x_new = x_new + MAP.x_range_c(xv_c);
    y_new = y_new + MAP.y_range_c(yv_c);
%     
%     %% DO a finer search for angles and poses
%     if(abs(dyaw)>0)%5e-4)
%         %yaw_v_f = yaw_v_c(thv)-deg2rad(1):deg2rad(0.1):yaw_v_c(thv)+deg2rad(1); % fine search for yaw values
%         yaw_v_f = yaw_v_c(thv)-deg2rad(1):deg2rad(0.25):yaw_v_c(thv)+deg2rad(1); % fine search for yaw values
% 
%     else
%         yaw_v_f = yaw_v_c(thv)-deg2rad(0.5):deg2rad(0.25):yaw_v_c(thv)+deg2rad(0.5);
%     end
%     
%     c = zeros(numel(MAP.x_range_f),numel(MAP.y_range_f),numel(yaw_v_f));
% 
%     for k = 1:numel(yaw_v_f)
%         %make the origin of the robot's frame at its geometrical center
% 
%         %transform for the imu reading (assuming zero for this example)
%         %Timu = rotz(yaw_v_f(k))*Tpr; % yaw*pitch*roll - orientation of the body frame w.r.t the world frame
%                 
%         %full transform from lidar frame to world frame 
%         % Tpose - just the translation from the body frame to the world frame
%         %T = [ Timu(1:3,1:3) [x_new;y_new;0]; 0 0 0 1] *Tsensor; % first part is Tpose*Timu - which can be written as [R T; 0 1] - a homogeneous matrix
%         %T = Tpose*Timu*Tsensor;
%         Tyaw = rotz(yaw_v_f(k)); 
% 
%         Y=Tpose*Tyaw*Yt;
% 
%         c(:,:,k) = map_correlation(MAP.map,MAP.x_im,MAP.y_im,Y(1:3,:),MAP.x_range_f,MAP.y_range_f);
%         %max(max(c(:,:,k)))
%         %c(3,3,k) = c(3,3,k) + max(max(c(:,:,k)))/1000;
%         %c(:,:,k) = c(:,:,k).*MAP.gaussian_f;%*(max(max(c(:,:,k)))/100);
%         
%     end
%     %% Update the state
%     [a,ind] = max(c(:));
%     [xv_f,yv_f,thv] = ind2sub(size(c),ind);
%     state(3) = yaw_v_f(thv);
%     state(1) = x_new + MAP.x_range_f(xv_f);
%     state(2) = y_new + MAP.y_range_f(yv_f);
    
    state(1) = x_new;
    state(2) = y_new;
    state(3) = yaw_v_c(thv);
    %% update the map
    %transform for the imu reading (assuming zero for this example)
    Timu = rotz(state(3))*Tpr;%roty(pitch)*rotx(roll);
    Tpose   = trans([state(1) state(2) 0]);
    %full transform from lidar frame to world frame
    %T = Tpose*Timu*Tsensor;

    %Y=T*X;
    Y = Tpose*Timu*T_servotobody*Rservo*T_senstoservo*X;

    %transformed xs and ys
    xs1 = Y(1,:);
    ys1 = Y(2,:);

    %convert from meters to cells
    xis = ceil((xs1 - MAP.xmin) ./ MAP.res);
    yis = ceil((ys1 - MAP.ymin) ./ MAP.res);

    %check the indices and populate the map
    indGood = (xis > 1) & (yis > 1) & (xis < MAP.sizex) & (yis < MAP.sizey);
    inds = sub2ind(size(MAP.map),xis(indGood),yis(indGood));
    MAP.map(inds) = min(MAP.map(inds)+1,100);
       
    % see the changes in the map
        %plot original lidar points
%         figure(2);
%         plot(xs1,ys1,'.')
    
end