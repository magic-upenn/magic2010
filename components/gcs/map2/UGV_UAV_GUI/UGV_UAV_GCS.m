SetMagicPaths;
more off;

IDS=[8];

%% GUI globals
global GUI_CONTAINER G_MAP_PLOT R1_MAP_PLOT R2_MAP_PLOT R3_MAP_PLOT
UGV_UAV_GUI_INIT; % gui initialization
drawnow;

%% Global planner data initialization and subscription
ipcAPI('connect')
ipcAPI('define','Global_Planner_DATA',MagicGP_DATASerializer('getFormat'))

%% Doesn't seem to be used
%{
ipcAPI('subscribe','Global_Planner_TRAJ')
ipcAPI('set_msg_queue_length','Global_Planner_TRAJ',1)

ipcAPI('subscribe','OOI_Msg')
ipcAPI('set_msg_queue_length','OOI_Msg',1)

ipcAPI('subscribe','OOI_Done_Msg')
ipcAPI('set_msg_queue_length','OOI_Done_Msg',1)

ipcAPI('subscribe','UAV_Feed')
ipcAPI('set_msg_queue_length','UAV_Feed',1)
%}

%% Global and local map data initialization and subscription
ipcAPI('subscribe','Global_Map')
ipcAPI('set_msg_queue_length','Global_Map',1)

ipcAPI('subscribe','RPose')
ipcAPI('set_msg_queue_length','RPose',30)

ipcAPI('subscribe','IncH')
ipcAPI('set_msg_queue_length','IncH',30)

ipcAPI('subscribe','IncV')
ipcAPI('set_msg_queue_length','IncV',30)

%% Robot IPC Initialization and Subscription (also not used...?)
ipcWrapperAPI8('connect','192.168.10.108',8)

ipcWrapperAPI8('subscribe','Robot8/Planner_Path')
ipcWrapperAPI8('set_msg_queue_length','Robot8/Planner_Path',1)

ipcWrapperAPI8('subscribe','Robot8/FSM_Status')
ipcWrapperAPI8('set_msg_queue_length','Robot8/FSM_Status',1)

while(1)
    drawnow;
    %% get Robot messages
    %rmsgs=ipcWrapperAPI8('listen',10)
    msgs=ipcAPI('listenWait',100);
    nmsg=length(msgs);
    for i=1:nmsg
        name=msgs(i).name;
        switch name
            case 'RPose'
                robotdat=deserialize(msgs(i).data);
                robotdat.update;
            case 'IncH'
                inchdat=deserialize(msgs(i).data);
                %hold off
                set(R1_MAP_PLOT.plot,'XData',inchdat.update.xs,'YData',inchdat.update.ys)
                %hold on
                %surf(inchdat.update.xs,inchdat.update.ys,inchdat.update.cs)
            case 'IncV'
                incvdat=deserialize(msgs(i).data);
            case 'Global_Map'
                globaldat=deserialize(msgs(i).data);
                %G_MAP_PLOT.plot=imagesc(globaldat.mapData);
                set(G_MAP_PLOT.plot,'CData',globaldat.mapData)
                
            otherwise
        end
    end
end
    
%gcsParams;

%last_explore_update=gettime;

%world_gui.ipcAPI=str2func('ipcAPI');

%world_gui.ipcAPI('connect');
