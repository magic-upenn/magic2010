%% Set some parameters & initialize stuff

close all;
SetMagicPaths;
%lidar0MsgName = GetMsgName('Lidar0');

robotId = '5';
EncMsgName = ['Robot' robotId '/Encoders'];    
ImuMsgName = ['Robot' robotId '/ImuFiltered']; % IMU 
ipcAPIConnect('localhost');

% Subscribe to stuff
ipcAPISubscribe(EncMsgName);
ipcAPISubscribe(ImuMsgName);

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

global MAP
res = 0.05;
xdev = 15;
ydev = 15;

init_map(res,xdev,ydev);

ct_Enc = 1;
ct_Imu = 1;

%% Encoder stuff
enc_cts = 360; % 360 counts/revolution
wheel_dia = 254;% 254 mm
circum = 2*pi*254/2; % circumference of the wheel in mm = 2*pi*radius of wheel
mpertic = (circum/360)/1000; % meters per encoder tic
robotRadius = (311.15 + 476.25)/(4*1000);%0.196875; %0.5842/2; % 584.2/2 mm
RadiusFudge = 1; %%%%%%%%%%%%%%% change this later
enc_rate = 40; % 40 Hz
dt_Enc = 1/enc_rate;
%% Imu Stuff
Imu_latest = struct('roll',0,'pitch',0,'yaw',0,'wroll',0,'wpitch',0,'wyaw',0,'t',0);
dt_Imu = 1/100;
prevImu = 1;

%% INitialize a figure;
temp = meters2cells([POSE.x POSE.y],[MAP.xmin,MAP.ymin],MAP.res);
fg = figure;
h = imagesc(MAP.map);
colormap gray
hold on
pl = plot(temp(1),temp(2),'r*');

%% Unscented Kalman Filter Stuff
state = [0;0;0];
state_covar = [1 0 0; 0 1 0; 0 0 deg2rad(5)];

%wts for the UKF
wt_sgmp = 1/(2*size(state_covar,1)); % weight factgor for each of sigma points - 1/2(n+k)
wt_chol = size(state_covar,1); %n+k in the UKF formalization

%Process noise
encx_noise = 0.01; % 0.2 m
ency_noise = 0.01; %0.2 m
yrt_noise = 0.01;%deg2rad(0.05); % 5 degrees
proc_noise_enc = [encx_noise 0 0; 0 ency_noise 0; 0 0 0];
proc_noise_gyro = [ 0 0 0; 0 0 0; 0 0 yrt_noise];


%% Movie stuff
%aviobj = avifile('apr20no1_all.avi');
%aviobj1 = avifile('testmedtraj_all.avi');

%% Initialize a structure for updating all the stuff
yaw_str = [];

while(1)
    msgs = ipcAPIReceive(10);
    len = length(msgs);
    if len > 0
        %disp('receiving...');
        for i=1:len
            switch(msgs(i).name)
                case ImuMsgName
                    Imu = MagicImuFilteredSerializer('deserialize',msgs(i).data);
                    yawrt = Imu.wyaw;
                    POSE.pitch = Imu.pitch;
                    POSE.roll = Imu.roll;
                    %% Do Unscented Kalman Filter Process Update for Yaw

                    %Get the Sigma points first        
                    %W_yaw = chol((wt_chol)*state_covar + proc_noise_gyro);
%                     W_yaw = chol(wt_chol*(state_covar + proc_noise_gyro));
%                     sigm_pt1 = bsxfun(@plus,state,W_yaw); % x+chol 
%                     sigm_pt2 = bsxfun(@plus,state,-W_yaw); % x-chol
%                     sigm_pts = cat(2,sigm_pt1,sigm_pt2);
% 
%                     % Do process update now
                    yaw_chng =  yawrt*dt_Imu;
                    yaw_str = [yaw_str yaw_chng]; 
                    state(3) = state(3) + yaw_chng;%Imu.yaw
%                     sigm_disp = bsxfun(@plus, sigm_pts,[0;0;yaw_chng]);
% 
%                     %Predicted state
%                     state = mean(sigm_disp,2);
% 
%             %         %Predicted state covariance
%             %         predcovar_yaw = zeros(size(state_covar));
%             %         for ct = 1:size(W_Yaw,1)
%             %            predcovar_yaw = predcovar_yaw +  wt_sgmp*((sigm_disp(:,ct) - state)*(sigm_disp(:,ct) - state).');
%             %         end
% 
%                     sigm_disp_ms = bsxfun(@minus,sigm_disp,state);
% 
%                     state_covar = wt_sgmp*(sigm_disp_ms*sigm_disp_ms');

                    ct_Imu = ct_Imu+1;

                case EncMsgName
                    Encoders = MagicEncoderCountsSerializer('deserialize',msgs(i).data);
                    
                    if(ct_Imu > 1)
                        wdt = mean(yaw_str);
                        if((isnan(wdt)) || isempty(wdt))
                            wdt = 0;
                        end
                        yaw_str = [];
                    else
                        wdt = 0;
                    end
                    prevImu = ct_Imu;
                    %LatestUp.Encoder= Encoders(ct_Enc);
                    rc = mean([Encoders.fr,Encoders.rr]) * mpertic; % rear right wheel distance = no of tics * m/tic
                    lc = mean([Encoders.fl,Encoders.rl]) * mpertic; % rear left wheel distance = no of tics * m/tic
                    vdt = mean([rc,lc]);

                    yawPrev = 0;
                    %calculate the change in position
                    if (abs(wdt) > 0.001)
                        dx = -vdt/wdt*sin(yawPrev) + vdt/wdt*sin(yawPrev+wdt);
                        dy = vdt/wdt*cos(yawPrev) - vdt/wdt*cos(yawPrev+wdt);
                        %dyaw = wdt;
                    else
                        dx = vdt*cos(yawPrev);
                        dy = vdt*sin(yawPrev);
                        %dyaw = wdt;
                    end

                    Tpr = roty(POSE.pitch)*rotx(POSE.roll);
                    Tyaw = rotz(state(3));
                    pos_chng = Tyaw*Tpr*[dx;dy;0;1];

                    LatestUp.dX = pos_chng(1);
                    LatestUp.dY = pos_chng(2);
                    LatestUp.Wdt = wdt;
                    state(1) = state(1) + pos_chng(1);
                    state(2) = state(2) + pos_chng(2);

%                     %% Unscented Kalman Filter Process update for X and Y
% 
%                     % Get the Sigma points first        
%                     W_enc = chol((wt_chol)*(state_covar + proc_noise_enc));
%                     sigm_pt1 = bsxfun(@plus,state,W_enc); % x+chol 
%                     sigm_pt2 = bsxfun(@plus,state,-W_enc); % x-chol
%                     sigm_pts = cat(2,sigm_pt1,sigm_pt2);
% 
%                     % Do process update now
%                     sigm_disp = bsxfun(@plus, sigm_pts,[pos_chng(1);pos_chng(2);0]);
% 
%                     %Predicted state
%                     state = mean(sigm_disp,2);
% 
%                     % Predicted state covariance
%                     sigm_disp_ms = bsxfun(@minus,sigm_disp,state);
% 
%                     %predcovar_enc = zeros(size(state_covar));
%                     %for ct = 1:size(W_Yaw,1)
%                     %    predcovar_enc = predcovar_enc +  wt_sgmp*((sigm_disp(:,ct) - state)*(sigm_disp(:,ct) - state).');
%                     %end
%                     state_covar = wt_sgmp*(sigm_disp_ms*sigm_disp_ms');

            %         if(ct_Enc == 1)
            %             %fenc = figure;
            %             %hold on
            %             %pl_Enc = plot(state(1),state(2));
            %             %pl_GPS = plot(0,0,'.'); % for GPS
            %             set(pl_Enc,'Xdata',state(1),'Ydata',state(1));
            %         else
            %             xd_en = get(pl_Enc,'Xdata');
            %             yd_en = get(pl_Enc,'Ydata');
            %             set(pl_Enc,'Xdata',[xd_en state(1)],'Ydata',[yd_en state(2)]);
            %         end
                    %xd_en = get(pl_Enc,'Xdata');
                    %yd_en = get(pl_Enc,'Ydata');
                    %set(pl_Enc,'Xdata',[xd_en state(1)],'Ydata',[yd_en state(2)]);

                    ct_Enc = ct_Enc+1;

            end
        end
    end
    temp = meters2cells([state(1) state(2)],[MAP.xmin,MAP.ymin],MAP.res);
    POSE.x = temp(1);
    POSE.y = temp(2);
    POSE.yaw = state(3);
    set(pl,'Xdata',POSE.x,'Ydata',POSE.y);
    content = serialize(POSE);
    ipcAPIPublishVC(PoseMsgName,content);
    drawnow;
end


            
        
