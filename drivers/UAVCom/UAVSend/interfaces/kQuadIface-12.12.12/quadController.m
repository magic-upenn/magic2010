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
a_t = 0;
  
while(1)
    msgs=ipcAPI('listenWait',0);
    nmsgs=length(msgs);
    for i=1:nmsgs
        name=msgs(i).name;
        if(name == 'Quad1/AprilInfo')
            data=msgs(i).data;
            a_id=data(1)
            a_t=typecast(data(2:9),'double');
            rest=data(10:end);
            a_pos=typecast(rest(1:8*3),'double');
            a_ypr=typecast(rest(8*3+1:8*6),'double');
            a_dist=typecast(rest(8*6+1:8*7),'double');
            a_rot=typecast(rest(8*7+1:end),'double');
            a_rot=reshape(a_rot,3,3)';
        elseif(name == 'Quad1/QuadIMU')
            data=msgs(i).data;
            q_t=typecast(data(1:4), 'single')
            q_rpy=typecast(data(5:4*3), 'single');
            q_wrpy=typecast(data(4*3+1:4*6), 'single');
            q_arpy=typecast(data(4*6+1:4*9), 'single');
            q_p = typecast(data(4*9+1:4*10), 'single');
            q_h = press2alt(q_p);
        end
    end
    % values calculated soley from april data TODO: integrate IMU
    delT = a_t - quadPose(1); 
    vel = (a_pos-quadPose(2:5)')/delT;
    yaw_vel = (a_ypr(1)-quadPose(5))/delT;
    quadPose = [a_t, a_pos', a_ypr(1), vel', yaw_vel];
    
    
    
    
  
  trpy = [thrust roll pitch yaw];
  
  %KQUAD.driver('SendQuadCmd1',KQUAD.id, KQUAD.chan, KQUAD.type, trpy);
  %fprintf('Sending to channel %i, id %i, type %i\n',KQUAD.chan,KQUAD.id,KQUAD.type);
  pause(0.03);
end
    