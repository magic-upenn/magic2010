close all;
SetMagicPaths;
%lidar0MsgName = GetMsgName('Lidar0');

robotId = '5';
EncMsgName = ['Robot' robotId '/Encoders'];    
ImuMsgName = ['Robot' robotId '/ImuFiltered']; % IMU 
LidarMsgName = ['Robot' robotId '/Lidar0'];   
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

% Subscribe to stuff
ipcAPISubscribe(EncMsgName);
ipcAPISubscribe(ImuMsgName);
ipcAPISubscribe(ServoMsgName);
ipcAPISubscribe(LidarMsgName);

% Pose stuff
PoseMsgName = GetMsgName('Pose');
ipcAPIDefine(PoseMsgName);

POSE.x = 0;
POSE.y = 0;
POSE.yaw = 0;
POSE.pitch = 0;
POSE.roll = 0;

content = serialize(POSE);
ipcAPIPublishVC(PoseMsgName,content);

%% Encoder stuff
enc_cts = 360; % 360 counts/revolution
wheel_dia = 254;% 254 mm
circum = 2*pi*254/2; % circumference of the wheel in mm = 2*pi*radius of wheel
mpertic = (circum/360)/1000; % meters per encoder tic
robotRadius = (311.15 + 476.25)/(4*1000);%0.196875; %0.5842/2; % 584.2/2 mm
RadiusFudge = 1; %%%%%%%%%%%%%%% change this later
enc_rate = 40; % 40 Hz
%% Initializations of map & robot's state
state = [0 0 0]; % Initially at x&y position of 0,0 and yaw angle of zero degrees
z_val = 0;
dz = 0;
dx = 0;
dy = 0;
dyaw = 0;
pitch = 0;
roll = 0;
%% Timestamp stuff

k_imu = 1;
k_enc = 1;
k_las = 1;
%xData = zeros(1,numel(enc.Encoders.ts));
%yData = zeros(1,numel(enc.Encoders.ts));
yaw_rt = [];
inl_pitch = 0;
inl_roll = 0;

global MAP

ct_Enc = 1;
ct_Imu = 1;

while(1)
    msgs = ipcAPIReceive(10);
    len = length(msgs);
    if len > 0

        for i=1:len
            switch(msgs(i).name)
                case ImuMsgName
                    Imu = MagicImuFilteredSerializer('deserialize',msgs(i).data);
                    yawrt = Imu.wyaw;
                    yaw_chng =  yawrt*dt_Imu;
                    yaw_str = [yaw_str yaw_chng]; 
                    POSE.pitch = Imu.pitch;
                    POSE.roll = Imu.roll;
                case EncMsgName
                    
                       Encoders = MagicEncoderCountsSerializer('deserialize',msgs(i).data);
                    %if(ct_Imu > 1)
                        wdt = mean(yaw_str);
                        if((isnan(wdt)) || isempty(wdt))
                            wdt = 0;
                        end
                        yaw_str = [];
                    %else
                    %    wdt = 0;
                    %end
                    %%LatestUp.Encoder= Encoders(ct_Enc);
                    rc = mean([Encoders.fr,Encoders.rr]) * mpertic; % rear right wheel distance = no of tics * m/tic
                    lc = mean([Encoders.fl,Encoders.rl]) * mpertic; % rear left wheel distance = no of tics * m/tic
                    vdt = mean([rc,lc])

                    yawPrev = 0;
                    %calculate the change in position
                    if (abs(wdt) > 0.001)
                        dx = -vdt/wdt*sin(yawPrev) + vdt/wdt*sin(yawPrev+wdt);
                        dy = vdt/wdt*cos(yawPrev) - vdt/wdt*cos(yawPrev+wdt);
                        dyaw = wdt;
                    else
                        dx = vdt*cos(yawPrev);
                        dy = vdt*sin(yawPrev);
                        dyaw = wdt;
                    end

                    Tpr = roty(POSE.pitch)*rotx(POSE.roll);
                    Tyaw = rotz(state(3));
                    pos_chng = Tyaw*Tpr*[dx;dy;0;1];
                    
%                     state(1) = state(1) + pos_chng(1);
%                     state(2) = state(2) + pos_chng(2);
%                     state(3) = state(3) + wdt;
                    
                case LidarMsgName
                    lidarScan =  MagicLidarScanSerializer('deserialize',msgs(i).data);
                    if(servo_angl>0.1 )
                        continue
                    end
                    if(isempty(las_angles))
                        las_angles = Lidar{k_Lidar}.startAngle : Lidar{k_Lidar}.angleStep : Lidar{k_Lidar}.stopAngle;
                        %zs = zeros(size(las_angles));
                        %os = ones(size(las_angles));
                        %coslas_ang = cos(las_angles);
                        %sinlas_ang = sin(las_angles);
                        initializeMap(lidarScan.ranges,las_angles,POSE.pitch,POSE.roll,0);

                        % INitialize figure for map,trajectory and robot
                        xcell = (state(1) - MAP.xmin) ./ MAP.res;
                        ycell = (state(2) - MAP.xmin) ./ MAP.res;
                        fig = figure;
                        hold on
                        colormap gray
                        h = imagesc(MAP.map);
                        ht = plot(ycell,xcell,'r.','MarkerSize',1);
                        hr = plot(ycell,xcell,'g*');
                        axis tight;
                        title(['MAP - Iterations:',num2str(k_enc)]);
                        inl_ptch = 0;%pitch;
                        inl_rll = 0;%roll;
                    else

                        [state,dz] = correlateMap_nedit(lidarScan.ranges,las_angles,POSE.pitch,POSE.roll,state,dyaw,dx,dy,servo_angl);
                        %dz;
                        %z_val = z_val + dz;
                        % update the figure
                        xcell = (state(2) - MAP.xmin) ./ MAP.res; % x and y values are flipped in MATLAB
                        ycell = (state(1) - MAP.xmin) ./ MAP.res;

                        if(mod(k_enc,10)==0)
                            %MAP.map = MAP.map*0.99; % decay the map
                            set(ht,'XData',[get(ht,'XData'),xcell]);
                            set(ht,'YData',[get(ht,'YData'),ycell]);
                            set(hr,'Xdata',xcell);
                            set(hr,'YData',ycell);
                            set(h,'CData',MAP.map);
                            title({['MAP - Iterations:',num2str(k_enc)];['Pitch:',num2str(pitch)]});
                            drawnow;
                            %F = getframe(fig);
                            %aviobj = addframe(aviobj,F);
                        end
                    end
                    %pose(:,k_enc) = state';
                    k_enc = k_enc + 1;
                case servoMsgName
                    Servo = MagicServoStateSerializer('deserialize',msgs(i).data);
                    servo_angl = Servo.position+0.05; % initial offset is 0.05 radians
            end
            POSE.x = xcell;
            POSE.y = ycell;
            POSE.yaw = state(3);
            content = serialize(POSE);
            ipcAPIPublishVC(PoseMsgName,content);
            drawnow;
    end
    %pose_6D(:,k) = [state(1);state(2);z_val;state(3);pitch;roll]; % x,y,z,yaw,pitch,roll
end
