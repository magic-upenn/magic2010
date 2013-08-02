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
                pos1=typecast(rest(1:8*3),'double');
                a_ypr=typecast(rest(8*3+1:8*6),'double');
                a_dist=typecast(rest(8*6+1:8*7),'double');
                a_rot=typecast(rest(8*7+1:end),'double');
                a_rot=reshape(a_rot,3,3)';
                %% transform april info
                
                % yaw, pitch, and roll with normal rhr values
                yaw=-a_ypr(1);
                pitch=-a_ypr(2)+pi;
                roll=-a_ypr(3);
                a_ypr = [roll pitch yaw];

                % create rotation matrix (rhr orientation of april tag wrt camera)
                rot1=[cos(yaw) -sin(yaw) 0; sin(yaw) cos(yaw) 0; 0 0 1]*...
                    [1 0 0; 0 cos(pitch) -sin(pitch); 0 sin(pitch) cos(pitch)]*...
                    [cos(roll) 0 sin(roll); 0 1 0; -sin(roll) 0 cos(roll)];

                % get position (rhr april tag wrt camera)
                pos2=[0 0 1; 0 -1 0; 1 0 0]*pos1';

                % homogeneous transformation (camera wrt april tag)
                H=[rot1' -rot1'*pos2; 0 0 0 1];
                a_pos=H(1:3,4)';

                % rotation of camera wrt to tag to get quadrotor wrt tag
                rot=H(1:3,1:3)*[1 0 0; 0 -1 0; 0 0 -1]*[cos(-pi/4) -sin(-pi/4) 0; sin(-pi/4) cos(-pi/4) 0; 0 0 1];
                
                % find euler angle from new rotation matrix
                if abs(rot(3,1))~=1
                    pitch = -asin(rot(3,1));
                    pitch2 = pi - pitch;
                    roll = atan2(rot(3,2)/cos(pitch) , rot(3,3)/cos(pitch));
                    roll2 = atan2(rot(3,2)/cos(pitch2), rot(3,3)/cos(pitch2));
                    yaw = atan2(rot(2,1)/cos(pitch), rot(1,1)/cos(pitch));
                    yaw2 = atan2(rot(2,1)/cos(pitch2), rot(1,1)/cos(pitch2));
                else
                    yaw =0;
                    if rot(3,3)==-1
                        pitch = pi/2;
                        roll = yaw + atan2(-rot(1,2),-rot(1,3));
                    else
                        pitch = -pi/2
                        roll = -yaw+atan2(-rot(1,2), -rot(1,3));
                    end
                end
                a_ypr = [yaw pitch roll];
                fprintf('yaw=%f pitch=%f roll=%f\n', yaw, pitch, roll);
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
            trpy = positionController(delT, quadPose, target, integrals, q_rpy, q_wrpy);
            %fprintf('trpy = %f, %f, %f. %f\n',trpy(1),trpy(2),trpy(3),trpy(4));
            %Send the command to the kQuad
            KQUAD.driver('SendQuadCmd1',KQUAD.id, KQUAD.chan, KQUAD.type, trpy);
            %fprintf('Sending to channel %i, id %i, type %i\n',KQUAD.chan,KQUAD.id,KQUAD.type);
        end
        pause(0.03);
    end
    