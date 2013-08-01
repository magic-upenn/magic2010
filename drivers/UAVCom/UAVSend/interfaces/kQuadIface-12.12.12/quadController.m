%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
function quadController()
    
    SetMagicPaths;
    
    %configure IPC
    ipcAPI('connect');
    ipcAPI('subscribe','Quad1/IMU');
    ipcAPI('set_msg_queue_length','Quad1/IMU',1);
    
    ipcAPI('subscribe','Quad1/AprilInfo');
    ipcAPI('set_msg_queue_length','Quad1/AprilInfo',1);
    
    %open the interface
    KQUAD.dev    = '/dev/ttyUSB0';
    KQUAD.driver = @kQuadInterfaceAPI;
    KQUAD.baud   = 921600;
    KQUAD.id     = 0;
    KQUAD.chan   = 0;
    KQUAD.type   = 0; %0 for standard, 1 for nano
    
    KQUAD.driver('connect',KQUAD.dev,KQUAD.baud) %connect to the quad
    
    thrust = 1; %grams. 1 for idle
    roll   = 0; %radians
    pitch  = 0; %radians
    yaw    = 0; %radians
    
    %set some inital conditions
    integrals = [0 0 0 0];
    
    while(1)
        msgs=ipcAPI('listenWait',0);
        nmsgs=length(msgs);
        for i=1:nmsgs
            name=msgs(i).name;
            if(isequal(name,'Quad1/AprilInfo'))
                data=msgs(i).data;
                a_id=data(1);
                a_t=typecast(data(2:9),'double');
                rest=data(10:end);
                a_pos=typecast(rest(1:8*3),'double')
                a_ypr=typecast(rest(8*3+1:8*6),'double');
                a_dist=typecast(rest(8*6+1:8*7),'double');
                a_rot=typecast(rest(8*7+1:end),'double');
                a_rot=reshape(a_rot,3,3)';
                
                % parse april info
                if(~exist('quadPose', 'var'))
                    delT = 0;
                    vel = [0 0 0];
                    yaw_vel = 0;
                else
                    delT = a_t - quadPose(1);
                    vel = (a_pos-quadPose(2:4))/delT;
                    yaw_vel = (a_ypr(1)-quadPose(5))/delT;
                end
                quadPose = [a_t, a_pos, a_ypr(1), vel, yaw_vel];
                
            elseif(isequal(name,'Quad1/IMU'))
                data=msgs(i).data;
                q_t=typecast(data(1:8), 'double');
                q_rpy=typecast(data(8*1+1:8*4), 'double');
                q_wrpy=typecast(data(8*4+1:8*7), 'double');
                q_arpy=typecast(data(8*6+1:8*8), 'double');
                q_p = typecast(data(8*8+1:8*9), 'double');
                q_h = press2alt(q_p);
            end
        end

        
        target = [0 0 1 0]; % [x y z yaw]
        
        %check for valid parameters
        control_params = {'delT', 'quadPose', 'target', 'integrals', 'q_rpy', 'q_wrpy'};
        exist_func = @(x) exist(x, 'var');
        valid_params = all(cellfun(exist_func, control_params));
        
        if(valid_params)
            %Calculate the quadrotor commands
            trpy = positionController(delT, quadPose, target, integrals, q_rpy, q_wrpy);      %Send the command to the kQuad
            KQUAD.driver('SendQuadCmd1',KQUAD.id, KQUAD.chan, KQUAD.type, trpy);
            %fprintf('Sending to channel %i, id %i, type %i\n',KQUAD.chan,KQUAD.id,KQUAD.type);
        end
        pause(0.03);
    end
    