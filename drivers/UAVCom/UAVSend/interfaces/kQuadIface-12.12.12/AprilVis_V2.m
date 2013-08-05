function detection_points=AprilVis_V2()
clear all;

DEBUG_FLAG=1;

SetMagicPaths;
ipcAPI('connect');
ipcAPI('subscribe','Quad1/AprilInfo');
ipcAPI('set_msg_queue_length','Quad1/AprilInfo',1);

UdpSendAPI('connect','192.168.10.255',12345);

%% plotting params
rotrad=2*0.0254;
quadwidth=0.5;%5*sqrt(2)*0.0254;

% tag values
square=[quadwidth quadwidth 0; ...
        quadwidth -quadwidth 0; ...
        -quadwidth -quadwidth 0; ...
        -quadwidth quadwidth 0; ...
        quadwidth quadwidth 0];
s1=square(1:2,:);
s2=square(2:3,:);
s3=square(3:4,:);
s4=square(4:5,:);

%% initialize plotting
figure(10000)
cla
axis equal
grid on
xlim([-2 2]);
ylim([-2 2]);
zlim([0 5]);
hold on
box on

xlabel('x');
ylabel('y');
zlabel('z');

%% original basis plot
x=[1 0 0];
y=[0 1 0];
z=[0 0 1];
xplot=plot3([0 x(1)],[0 x(2)],[0 x(3)],'r');
yplot=plot3([0 y(1)],[0 y(2)],[0 y(3)],'g');
zplot=plot3([0 z(1)],[0 z(2)],[0 z(3)],'b');

detection_points=[];
hold on;

%% inifinite loop
while(1)
    msgs=ipcAPI('listenWait',0);
    nmsgs=length(msgs);
    for i=1:nmsgs
        %% parse quad data
        name=msgs(i).name;
        data=msgs(i).data;
        id=data(1);
        t=double(typecast(data(2:9),'double'));
        rest=data(10:end);
        pos1=typecast(rest(1:8*3),'double');
        ypr=typecast(rest(8*3+1:8*6),'double');
        dist=typecast(rest(8*6+1:8*7),'double');
 
        %% yaw, pitch, and roll with normal rhr values
        yaw=-ypr(1);
        pitch=-ypr(2)+pi;
        roll=-ypr(3);
        
        %% create rotation matrix (rhr orientation of april tag wrt camera)
        rot1=[cos(yaw) -sin(yaw) 0; sin(yaw) cos(yaw) 0; 0 0 1]*...
            [1 0 0; 0 cos(pitch) -sin(pitch); 0 sin(pitch) cos(pitch)]*...
            [cos(roll) 0 sin(roll); 0 1 0; -sin(roll) 0 cos(roll)];
        
        %% get position (rhr april tag wrt camera)
        pos2=[0 0 1; 0 -1 0; 1 0 0]*pos1';
        
        
        %% homogeneous transformation (camera wrt april tag)
        H=[rot1' -rot1'*pos2; 0 0 0 1];
        pos=H(1:3,4);
        detection_points(end+1,1:3) = pos';
        
        %% rotation of camera wrt to tag to get quadrotor wrt tag
        rot=H(1:3,1:3)*[1 0 0; 0 -1 0; 0 0 -1]*[cos(-pi/4) -sin(-pi/4) 0; sin(-pi/4) cos(-pi/4) 0; 0 0 1];

        %% serialize quadrotor data and publish via UDP
        quadData.pos=pos;
        quadData.rot=rot;
        quadData.t=GetUnixTime();
        payload=serialize(quadData);
        UdpSendAPI('send',payload);
        
        %% plot full pose of quadrotor wrt april tag
        x1=rot*x';
        y1=rot*y';
        z1=rot*z';

        set(xplot,'XData',[0 x1(1)]+pos(1),'YData',[0 x1(2)]+pos(2),'ZData',[0 x1(3)]+pos(3));
        set(yplot,'XData',[0 y1(1)]+pos(1),'YData',[0 y1(2)]+pos(2),'ZData',[0 y1(3)]+pos(3));
        set(zplot,'XData',[0 z1(1)]+pos(1),'YData',[0 z1(2)]+pos(2),'ZData',[0 z1(3)]+pos(3));

        switch id
            case 0
                plot3(detection_points(end,1), detection_points(end,2), detection_points(end,3), '*r');
            case 1
                plot3(detection_points(end,1), detection_points(end,2), detection_points(end,3), '*g');
            case 2
                plot3(detection_points(end,1), detection_points(end,2), detection_points(end,3), '*b');
        end
        drawnow
    end
end
