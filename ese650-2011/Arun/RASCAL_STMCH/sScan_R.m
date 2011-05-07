function ret = sScan_R(event, varargin)

global POSE GOAL QUEUELASER LFLAG MAP
persistent DATA;
persistent fg fg_ori m pl mn pthh;

ret = [];
switch event
 case 'entry'
    disp('sScan');
    DATA.t0 = gettime;
    QUEUELASER = false;
    %GOAL_PREV = [];
    %tx = gettime;
 %{
 plannerState.shouldRun = 0;
 ipcAPIPublishVC(GetMsgName('Planner_State'), ...
                 MagicGP_SET_STATESerializer('serialize', plannerState));
 %}

 case 'exit'
    
 case 'update'
    if ~isempty(GOAL)
        %dx = GOAL(1) - POSE.x ;
        %dy = GOAL(2) - POSE.y;
%         goal_ang = atan2(dy,dx); % let us make this to be from 0 - 2*pi
%         if(goal_ang < 0)
%              goal_ang = goal_ang + 2*pi;
%         end
        yw = POSE.yaw;
        if(yw < 0)
            yw = yw+2*pi;
        end
        gl_yw = GOAL(3);
        if(gl_yw < 0)
            gl_yw = gl_yw + 2*pi;
        end
        % Wait till the robot reaches that angle
        if(yw-gl_yw>30*pi/180) % Make the robot turn to that particular angle
        %if(gettime - DATA.t0 < 1)
            SetVelocity(0, sign(gl_yw-yw)*0.5);
            %ret = [];
            return;
        else
            SetVelocity(0,0);
            QUEUELASER = true; %%FIXME: How to make sure that this does not get set again for the same goal?
            %ret = [];
        end
    end
    
    % Once scan is done, this flag will be set to true
    if(LFLAG)
        %MAP.map = zeros(MAP.sizex,MAP.sizey,'uint8')+127;
        ProcessLidarScans; % Create a costmap from the LIDAR scans
        LFLAG = false;
        %GOAL = [];
        if(isempty(fg_ori))
            fg_ori = figure;
            %set(gca,'xDir','normal','yDir','reverse');
            mn = imagesc(MAP.map);
            %colormap gray
            colorbar
            hold on;
            pthh = plot(POSE.x,POSE.y,'r*');
            title('Costmap from 3D points');
            
        else
            set(mn,'Cdata',MAP.map);
        end
        V = 5;
        MAP.map((POSE.y-V:POSE.y+V),(POSE.x-V:POSE.x+V)) = 75;
        % Inflate the costmap by the robot's footprint (assume square for
        % now)
        D = (MAP.map > 150);
        dil = imdilate(D,strel('square',5));
        inds = (dil > 0);
        MAP.map(inds) = 255; % set them all as obstacles
        
        % Publish the costmap
        mapMsgName = GetMsgName('CMap');
        ipcAPIDefine(mapMsgName);
        
        if(isempty(fg))
            fg = figure;
            set(gca,'xDir','normal','yDir','reverse');
            m = imagesc(MAP.map);
            %colormap gray
            colorbar
            hold on
            plot(POSE.x,POSE.y,'b*');
            title('Obstacles inflated and planner path in red');
            pl = plot(0,0,'r*');
        else
            set(m,'Cdata',MAP.map);
        end
        
        
        CMap.MAP = MAP; % costmap
        CMap.orx = POSE.x; % x is column
        CMap.ory = POSE.y; % y is row
        cMap.yaw = POSE.yaw;
        %CMap.glx = GOAL(1);
        %CMap.gly = GOAL(2);
        
        
        content = serialize(CMap);
        ipcAPIPublishVC(mapMsgName,content);
        
        % Plan on the costmap
        tic
        [Cells,ind] = plannerAstar(double(MAP.map),round([POSE.x POSE.y]),round([GOAL(1),GOAL(2)])); 
        toc
        set(pl,'Xdata',Cells(1,:),'Ydata',Cells(2,:));
        set(pthh,'Xdata',Cells(1,:),'Ydata',Cells(2,:));
        drawnow;
        % Publish the path
        pathMsgName = GetMsgName('Path');
        ipcAPIDefine(pathMsgName);

        traj.x = Cells(1,1:ind); % columns
        traj.y = Cells(2,1:ind); % rows
        
        content = serialize(traj);
        ipcAPIPublishVC(pathMsgName,content);
        
        QUEUELASER = false;
        %if(gettime - tx > 2)
        %disp('Exiting...');
        % Now scan the environment using the tilt lidar and make a costmap
        disp('Costmap generated');
        ret = 'Traj';
    end

end
