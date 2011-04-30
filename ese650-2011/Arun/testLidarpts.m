clear all
close all
%strg = 'Lidardata_30-Apr-2011_18:48:59';
strg = 'Lidardata_30-Apr-2011_19:38:11';
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

for k = 1:numel(ts)
    if(ts(k) == 1)
        Typr = rotz(yaw)*roty(pitch)*rotx(roll); 
        Tsensor = roty(servo_angl)'; % transpose is the inverse of the rotation
        
        las_angles = Lidar(k_Lidar).startAngle : Lidar(k_Lidar).angleStep : Lidar(k_Lidar).stopAngle;
        xs = (Lidar(k_Lidar).ranges.*cos(las_angles));
        ys = (Lidar(k_Lidar).ranges.*sin(las_angles));
        X = [xs;ys;zs;os]; %[x;y;0;1]
        Yt = Typr*Tsensor*X;
        if(isempty(pts_3D))
            figure;
            A = plot3(Yt(1,:),Yt(2,:),Yt(3,:),'.');
            pts_3D = Yt(1:3,:);
        elseif(mod(k_Lidar,10) == 0)
            xd = get(A,'Xdata');
            yd = get(A,'Ydata');
            zd = get(A,'Zdata');
            set(A,'Xdata',[xd Yt(1,:)],'Ydata',[yd Yt(2,:)],'Zdata',[zd Yt(3,:)]);
            pts_3D = cat(2,pts_3D,Yt(1:3,:));
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

