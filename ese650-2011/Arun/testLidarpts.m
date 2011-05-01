clear all
close all
%strg = 'Lidardata_30-Apr-2011_18:48:59';
strg = 'Lidardata_30-Apr-2011_19_38_11';
data = load(strcat(strg,'.mat'));
Lidar = cell2mat(data.Lidar);
Servo = cell2mat(data.Servo);
Imu = cell2mat(data.Imu);
ts_Lidar = [Lidar(1:end).startTime];
ts_Imu = [Imu(1:end).t];
ts_Servo = [Servo(1:end).t];

ts = sort([ts_Lidar ts_Imu ts_Servo],'ascend');
ts(ismember(ts,ts_Lidar)) = 1;% 1 for lidar, 2 for servo, 3 for IMU
ts(ismember(ts,ts_Imu)) = 2;
ts(ismember(ts,ts_Servo)) = 3;

k_Imu = 1;
k_Lidar = 1;
k_Servo = 1;

pitch = 0;
roll = 0;

figure;
plot(1:numel(ts_Servo),rad2deg([Servo(1:end).position]));
title('Plot of the servo angles over time');

zs = zeros(size(Lidar(1).ranges));
os = ones(size(Lidar(1).ranges));
pts_3D = [];
las_angles = [];
T_servotobody = trans([0 0 0]);
T_senstoservo = trans([0 0 0]);

%% Initialize the cost map
global MAP

MAP.res   = 0.05; %meters

MAP.xmin  = -5;  %meters
MAP.ymin  = -5;
MAP.xmax  =  5;
MAP.ymax  =  5;


%dimensions of the map
MAP.sizex  = ceil((MAP.xmax - MAP.xmin) / MAP.res + 1); %cells
MAP.sizey  = ceil((MAP.ymax - MAP.ymin) / MAP.res + 1);

MAP.map = zeros(MAP.sizex,MAP.sizey,'int8');


for k = 1:numel(ts)
    if(ts(k) == 1)
        Rypr = rotz(yaw)*roty(pitch)*rotx(roll); 
        Rsensor = roty(servo_angl)'; % transpose is the inverse of the rotation
        %[Lidar(k_Lidar).startAngle Lidar(k_Lidar).angleStep   Lidar(k_Lidar).stopAngle]
        if(isempty(las_angles))
            las_angles = Lidar(k_Lidar).startAngle : Lidar(k_Lidar).angleStep : Lidar(k_Lidar).stopAngle;
            coslas_ang = cos(las_angles);
            sinlas_ang = sin(las_angles);
        end
        las_ranges = Lidar(k_Lidar).ranges;
        xs = (las_ranges.*coslas_ang);
        ys = (las_ranges.*sinlas_ang);
        
        valid = ((las_ranges > 0.15)&(las_ranges<40));
        
        X = [xs;ys;zs;os]; %[x;y;0;1]
        Yt = Rypr*Rsensor*X(:,valid);
        
        xs1 = Yt(1,:);
        ys1 = Yt(2,:);

        %convert from meters to cells
        xis = ceil((xs1 - MAP.xmin) ./ MAP.res);
        yis = ceil((ys1 - MAP.ymin) ./ MAP.res);

        %check the indices and populate the map
        indGood = (xis > 1) & (yis > 1) & (xis < MAP.sizex) & (yis < MAP.sizey);
        inds = sub2ind(size(MAP.map),xis(indGood),yis(indGood));
        MAP.map(inds) = min(MAP.map(inds)+1,100);
    
        
        if(isempty(pts_3D))
            % 3D points
            figure;
            A = plot3(Yt(1,:),Yt(2,:),Yt(3,:),'.');
            pts_3D = Yt(1:3,:);

            % Cost map
            figure;
            hold on
            colormap gray
            h = imagesc(MAP.map);
            axis tight;
            title({['MAP - Iterations:',num2str(k_Lidar)];['Pitch:',num2str(pitch)]});

        elseif(mod(k_Lidar,10) == 0)
            % 3D points
            xd = get(A,'Xdata');
            yd = get(A,'Ydata');
            zd = get(A,'Zdata');
            set(A,'Xdata',[xd Yt(1,:)],'Ydata',[yd Yt(2,:)],'Zdata',[zd Yt(3,:)]);
            pts_3D = cat(2,pts_3D,Yt(1:3,:));
            
            % Cost map
            set(h,'CData',MAP.map);
            title({['MAP - Iterations:',num2str(k_Lidar)];['Pitch:',num2str(pitch)]});

            drawnow;
        end
        k_Lidar = k_Lidar+1;
        
    elseif(ts(k) == 2)
        pitch = Imu(k_Imu).pitch;
        roll = Imu(k_Imu).roll;
        yaw = 0;
        k_Imu = k_Imu + 1;
    elseif(ts(k) == 3)
        servo_angl = Servo(k_Servo).position;
        k_Servo = k_Servo + 1;
    end
end

save(strcat('3Dpts_',strg(11:end),'.mat'),'pts_3D');

