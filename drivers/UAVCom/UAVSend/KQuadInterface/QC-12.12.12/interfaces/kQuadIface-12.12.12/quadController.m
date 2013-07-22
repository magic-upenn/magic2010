%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
function quadController()
SetMagicPaths;
ipcAPI('connect');
ipcAPI('subscribe','KeyPress');
ipcAPI('set_msg_queue_length','KeyPress',1);


ipcAPI('subscribe','Quad1/AprilInfo');
ipcAPI('set_msg_queue_length','Quad1/AprilInfo',1);

%open the interface
KQUAD.dev    = '/dev/ttyUSB0';
KQUAD.driver = @kQuadInterfaceAPI;
KQUAD.baud   = 921600;
KQUAD.id     = 0;
KQUAD.chan   = 0;
KQUAD.type   = 0; %0 for standard, 1 for nano

%KQUAD.driver('connect',KQUAD.dev,KQUAD.baud)
  
thrust = 1; %grams. 1 for idle
roll   = 0; %radians
pitch  = 0; %radians
yaw    = 0; %radians
  
while(1)
    msgs=ipcAPI('listenWait',0);
    nmsgs=length(msgs);
    for i=1:nmsgs
        name=msgs(i).name;
        data=msgs(i).data;
        id=data(1);
        t=double(typecast(data(2:9),'double'));
        rest=data(10:end);
        pos=typecast(rest(1:8*3),'double');
        ypr=typecast(rest(8*3+1:8*6),'double');
        dist=typecast(rest(8*6+1:8*7),'double');
        rot=typecast(rest(8*7+1:end),'double');
        rot=reshape(rot,3,3)';
        
    end
    
  trpy = [thrust roll pitch yaw];
  
  %KQUAD.driver('SendQuadCmd1',KQUAD.id, KQUAD.chan, KQUAD.type, trpy);
  %fprintf('Sending to channel %i, id %i, type %i\n',KQUAD.chan,KQUAD.id,KQUAD.type);
  pause(0.03);
end
    