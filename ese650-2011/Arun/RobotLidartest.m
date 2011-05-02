clear all;
close all;
SetMagicPaths;
%lidar0MsgName = GetMsgName('Lidar0');

robotId = '5';
LidarMsgName = ['Robot' robotId '/Lidar0'];    
imuMsgName = ['Robot' robotId '/ImuFiltered']; % IMU
ServoMsgName = ['Robot' robotId '/Servo1']; 
ipcAPIConnect('localhost');

% Servo stuff
servoMsgName = GetMsgName('Servo1Cmd');
ipcAPIDefine(servoMsgName,MagicServoControllerCmdSerializer('getFormat'));

% Firtst bring the servo to zero angle position
servoCmd.id           = 1;
servoCmd.mode         = 2;  %0: disabled; 1: feedback only: 2: point minAngle is the goal), 3: servo mode
servoCmd.minAngle     = 0;
servoCmd.maxAngle     = 0;
servoCmd.speed        = 15;
servoCmd.acceleration = 300;

content = MagicServoControllerCmdSerializer('serialize',servoCmd);
ipcAPIPublishVC(servoMsgName,content);

pause(2); % wait for servo to reach that position

% Then do automatic scanning 
servoCmd.id           = 1;
servoCmd.mode         = 3;  %0: disabled; 1: feedback only: 2: point minAngle is the goal), 3: servo mode
servoCmd.minAngle     = -20;
servoCmd.maxAngle     = 45;
servoCmd.speed        = 15;
servoCmd.acceleration = 300;

content = MagicServoControllerCmdSerializer('serialize',servoCmd);
ipcAPIPublishVC(servoMsgName,content);
Servo_flag = false;

% Subscribe to stuff
ipcAPISubscribe(LidarMsgName);
ipcAPISubscribe(ServoMsgName);
ipcAPISubscribe(imuMsgName);

Lidar ={}; 
Servo = {};
Imu = {};

timeout = 25;

% Initialize stuff
k_Imu = 1;
k_Lidar = 1;
k_Servo = 1;

pitch = 0;
roll = 0;
yaw = 0;
servo_angl = 0;

pts_3D = [];
las_angles = [];
T_servotobody = trans([145 0 506]); % 144.775 0 506
T_senstoservo = trans([56 0 28]); 

%% Initialize the cost map
%global MAP
MAP.res   = 0.05; %meters

MAP.xmin  = -15;  %meters
MAP.ymin  = -15;
MAP.xmax  =  15;
MAP.ymax  =  15;

%dimensions of the map
MAP.sizex  = ceil((MAP.xmax - MAP.xmin) / MAP.res + 1); %cells
MAP.sizey  = ceil((MAP.ymax - MAP.ymin) / MAP.res + 1);

MAP.map = zeros(MAP.sizex,MAP.sizey,'int8');

tic;

while(1)
    if(toc > timeout)
      break;
    end
    msgs = ipcAPIReceive(10);
    len = length(msgs);
    if len > 0
        %disp('receiving...');
        for i=1:len
            switch(msgs(i).name)
                case LidarMsgName
                    if(Servo_flag)
                        lidarScan =  MagicLidarScanSerializer('deserialize',msgs(i).data);
                        %angles = linspace(lidarScan.startAngle, lidarScan.stopAngle, length(lidarScan.ranges));
                        %polar(angles,lidarScan.ranges,'.');
                        Lidar{end+1} = lidarScan;

                        Rypr = rotz(yaw)*roty(pitch)*rotx(roll); 
                        Rservo = roty(servo_angl)'; % transpose is the inverse of the rotation

                        %[Lidar(k_Lidar).startAngle Lidar(k_Lidar).angleStep   Lidar(k_Lidar).stopAngle]
                        if(isempty(las_angles))
                            las_angles = Lidar{k_Lidar}.startAngle : Lidar{k_Lidar}.angleStep : Lidar{k_Lidar}.stopAngle;
                            zs = zeros(size(las_angles));
                            os = ones(size(las_angles));
                            coslas_ang = cos(las_angles);
                            sinlas_ang = sin(las_angles);
                        end
                        las_ranges = Lidar{k_Lidar}.ranges;
                        xs = (las_ranges.*coslas_ang);
                        ys = (las_ranges.*sinlas_ang);

                        valid = ((las_ranges > 0.15)&(las_ranges<40));

                        X = [xs;ys;zs;os]; %[x;y;0;1]
                        Yt = Rypr*T_servotobody*Rservo*T_senstoservo*X(:,valid);

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
                        %drawnow;
                        fprintf(1,'.');
                    end
                case imuMsgName
                    Imu{end+1} = MagicImuFilteredSerializer('deserialize',msgs(i).data);
                    pitch = Imu{k_Imu}.pitch;
                    roll = Imu{k_Imu}.roll;
                    yaw = 0;
                    k_Imu = k_Imu + 1;
                case ServoMsgName
                    Servo{end+1} = MagicServoStateSerializer('deserialize',msgs(i).data);
                    servo_angl = Servo{k_Servo}.position;
                    Servo_flag = true;
                    k_Servo = k_Servo + 1;
            end
        end
    end
end
b = datestr(clock());
savename = strcat('Lidardata_',b(1:11),'_',b(13:end),'.mat');
%procname = strcat('Processed_',b(1:11),'_',b(13:end),'.mat');
%save(savename,'Lidar','Servo','Imu','MAP','pts_3D');

% Bring the servo back to zero position
servoCmd.id           = 1;
servoCmd.mode         = 2;  %0: disabled; 1: feedback only: 2: point minAngle is the goal), 3: servo mode
servoCmd.minAngle     = 0;
servoCmd.maxAngle     = 0;
servoCmd.speed        = 15;
servoCmd.acceleration = 300;

content = MagicServoControllerCmdSerializer('serialize',servoCmd);
ipcAPIPublishVC(servoMsgName,content);

%close all
clear all
