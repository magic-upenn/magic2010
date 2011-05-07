function [] = ProcessLidarScans()
    global LIDAR MAP POSE
    las_angles = [];
    T_servotobody = trans([0.145 0 0.506]); % 144.775 0 506
    T_senstoservo = trans([0.056 0 0.028]); 
    data = cells2meters([POSE.x POSE.y],[MAP.xmin,MAP.ymin],MAP.res);
    T_bodytoworld = trans([data(1) data(2) 0]);
    %Tpose = trans([POSE.x POSE.y 0]);
    %MAP.map = zeros(MAP.sizex,MAP.sizey,'uint8')+127;
    %numel(LIDAR)
    for k = 1:numel(LIDAR)
        
        Rypr = rotz(LIDAR{k}.yaw)*roty(LIDAR{k}.pitch)*rotx(LIDAR{k}.roll);
        Rservo = roty(LIDAR{k}.servoangle); % transpose is the inverse of the rotation
        %fprintf('%f \n',LIDAR{k}.servoangle);
        %[Lidar(k_Lidar).startAngle Lidar(k_Lidar).angleStep   Lidar(k_Lidar).stopAngle]
        if(isempty(las_angles))
            las_angles = LIDAR{k}.startAngle : LIDAR{k}.angleStep : LIDAR{k}.stopAngle;
            zs = zeros(size(las_angles));
            os = ones(size(las_angles));
            coslas_ang = cos(las_angles);
            sinlas_ang = sin(las_angles);
        end
        las_ranges = LIDAR{k}.ranges;
        xs = (las_ranges.*coslas_ang);
        ys = (las_ranges.*sinlas_ang);

        valid = ((las_ranges > 0.15)&(las_ranges<40));

        X = [xs;ys;zs;os]; %[x;y;0;1]
        Yt = T_bodytoworld*Rypr*T_servotobody*Rservo*T_senstoservo*X(:,valid);
        %Yt = Rservo*T_senstoservo*X(:,valid);
        %Yt = [Rypr(1:3,1:3) T_servotobody(1:3,4); 0 0 0 1]*[Rservo(1:3,1:3) T_senstoservo(1:3,4); 0 0 0 1]*X(:,valid);
        not_floor = (Yt(3,:) > 0.15);

        %% Add value for objects that are not the floor - obstacles
        xs1 = Yt(1,not_floor);
        ys1 = Yt(2,not_floor);

        %convert from meters to cells
        xis = ceil((xs1 - MAP.xmin) ./ MAP.res);
        yis = ceil((ys1 - MAP.ymin) ./ MAP.res);

        %check the indices and populate the map
        indGood = (xis > 1) & (yis > 1) & (xis < MAP.sizex) & (yis < MAP.sizey);
        inds = sub2ind(size(MAP.map),xis(indGood),yis(indGood));
        MAP.map(inds) = min(MAP.map(inds)+5,255);
        
        %% Clear value for objects that correspond to the floor
        xs1 = Yt(1,~not_floor);
        ys1 = Yt(2,~not_floor);

        %convert from meters to cells
        xis = ceil((xs1 - MAP.xmin) ./ MAP.res);
        yis = ceil((ys1 - MAP.ymin) ./ MAP.res);

        %check the indices and populate the map
        indGood = (xis > 1) & (yis > 1) & (xis < MAP.sizex) & (yis < MAP.sizey);
        inds = sub2ind(size(MAP.map),xis(indGood),yis(indGood));
        MAP.map(inds) = max(MAP.map(inds)-5,1);
        %imagesc(MAP.map);
        %drawnow
%         if(k==1)
%             figure;
%             hold on
%             %p = plot(xs,ys,'b.');
%             plot3(Yt(1,:),Yt(2,:),Yt(3,:),'b.');
%         elseif(mod(k,1) == 0)
%             pause(0.03)
%             %set(p,'Xdata',xs,'Ydata',ys);
%             plot3(Yt(1,:),Yt(2,:),Yt(3,:),'b.');
%         end   
    end
end
