%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
%initialize the experiment

global vicon_names sim_on qd use_linux

addpath('./init')

init_paths

init_flags

%set the ids of the vehicles to be controlled
usequad(1) =703;
usequad(2) = 0;
usequad(3) = 0;
usequad(4) = 0;

ipcid = [1:4]; %id numbers for ipc messages
nquad = sum(usequad>0); %number of quadrotors in flight
usequad = usequad(1:nquad);

for c=1:nquad;
    qd{c}.id = usequad(c);
end

init_variables
quadInfo

for qn=1:nquad;
    qd{qn}.dev = '/dev/ttyUSB0'; %set the device
end

if(use_ipc)
    ipcAPIConnect();
    
    msg_name = 'seqmsg';
    ipcAPIDefine(msg_name);
    ipcAPIDefine(msg_name); %re-definition does not hurt
    ipcAPISubscribe(msg_name);
    
    killmsg = 'KillSwitch';  
    ipcAPIDefine(killmsg);
    ipcAPIDefine(killmsg);
    ipcAPISubscribe(killmsg);
    
    startmsg = 'StartSwitch';
    ipcAPIDefine(startmsg);
    ipcAPIDefine(startmsg);
    ipcAPISubscribe(startmsg);
end


if(~sim_on)
    for qn=1:nquad
        baud = 1000000;
        
        qd{qn}.driver('connect',qd{qn}.dev,baud,1/100)
        
%         qd{qn}.driver('setCmdDt',0.001)
%         qd{qn}.driver('setKbeeMode',2,0); %0 for tx, 1 for rx
%         qd{qn}.driver('setKbeeMode',1,0); %0 for tx, 1 for rx

%         for ii=1:24
%             qd{qn}.driver('setQuadType',ii,1)
%         end
%         
%         qd{qn}.driver('setQuadType',qd{qn}.kbeeid,0);    
    end
end

if(get_feedback)
    dev  = '/dev/ttyUSB0';
    baud = 1000000;
    SerialDeviceAPI('connect',dev,baud);
    
%     kbeeId = 2;
%     SetKbeeMode(kbeeId,1); %receive mode
%     ch=45;
%     
%     packet=DynamixelPacketCreate(5,1,uint8([kbeeId,ch]));
%     SerialDeviceAPI('write',packet);
end

if(vicon_on)
    viconStartup4
end

%warmup the cache
init_cache

tic
time0 = GetUnixTime;