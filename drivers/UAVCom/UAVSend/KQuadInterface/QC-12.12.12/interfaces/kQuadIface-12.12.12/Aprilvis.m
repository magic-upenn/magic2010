%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
function quadController()
clear all;

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


rotrad=2*0.0254;
quadwidth=5*sqrt(2)*0.0254;

% circle for the rotors
thetad=(0:0.1:2*pi)';
rotorx=rotrad*sin(thetad);
rotory=rotrad*cos(thetad);
rotorz=zeros(length(thetad),1);

% position of all the rotors
pa=[quadwidth/2+rotorx rotory rotorz];
pb=[-quadwidth/2+rotorx rotory rotorz];
pc=[rotorx quadwidth/2+rotory rotorz];
pd=[rotorx -quadwidth/2+rotory rotorz];

% body frame vals
shaft=[-quadwidth/2,quadwidth/2]';
shaft1=zeros(length(shaft),1);

% body frame points
shafta=[shaft shaft1 shaft1];
shaftb=[shaft1 shaft shaft1];

% orientation vector
orientation=[[0 0]' [0 0]' [0 .2]'];

figure(1)
cla
axis equal
xlim([-2 2]);
ylim([-2 2]);
zlim([-2 2]);
hold on

xlabel('x');
ylabel('y');
zlabel('z');

rotaplot=plot3(pa(:,1),pa(:,2),pa(:,3),'r');
rotbplot=plot3(pb(:,1),pb(:,2),pb(:,3),'b');
rotcplot=plot3(pc(:,1),pc(:,2),pc(:,3),'b');
rotdplot=plot3(pd(:,1),pd(:,2),pd(:,3),'b');
shaftaplot=plot3(shafta(:,1),shafta(:,2),shafta(:,3),'k-');
shaftbplot=plot3(shaftb(:,1),shaftb(:,2),shaftb(:,3),'k-');

while(1)
    msgs=ipcAPI('listenWait',0);
    nmsgs=length(msgs);
    for i=1:nmsgs
        
        name=msgs(i).name;
        data=msgs(i).data;
        id=data(1);
        t=double(typecast(data(2:9),'double'));
        rest=data(10:end);
        pos=typecast(rest(1:8*3),'double')*12*0.0254;
        
        ypr=typecast(rest(8*3+1:8*6),'double');
        dist=typecast(rest(8*6+1:8*7),'double');
        rot=typecast(rest(8*7+1:end),'double');
        rot=reshape(rot,3,3);%*[cos(pi/4) -sin(pi/4) 0; sin(pi/4) cos(pi/4) 0; 0 0 1];
        %vec=[1;0;0];
        
        trotaplot=rot*rotaplot';
        trotbplot=rot*rotbplot';
        trotcplot=rot*rotcplot';
        trotdplot=rot*rotdplot';
        tshafta=rot*shafta';
        tshaftb=rot*shaftb';
        
        tpa=rot*pa';
        tpb=rot*pb';
        tpc=rot*pc';
        tpd=rot*pd';
        %cla
        %axis equal
        set(rotaplot,'XData',tpa(1,:)+pos(1),'YData',tpa(2,:)+pos(2),'ZData',tpa(3,:)+pos(3))
        set(rotbplot,'XData',tpb(1,:)+pos(1),'YData',tpb(2,:)+pos(2),'ZData',tpb(3,:)+pos(3))
        set(rotcplot,'XData',tpc(1,:)+pos(1),'YData',tpc(2,:)+pos(2),'ZData',tpc(3,:)+pos(3))
        set(rotdplot,'XData',tpd(1,:)+pos(1),'YData',tpd(2,:)+pos(2),'ZData',tpd(3,:)+pos(3))
        set(shaftaplot,'XData',tshafta(1,:)+pos(1),'YData',tshafta(2,:)+pos(2),'ZData',tshafta(3,:)+pos(3))
        set(shaftbplot,'XData',tshaftb(1,:)+pos(1),'YData',tshaftb(2,:)+pos(2),'ZData',tshaftb(3,:)+pos(3))
        
        drawnow
    end
    
  trpy = [thrust roll pitch yaw];
  
  %KQUAD.driver('SendQuadCmd1',KQUAD.id, KQUAD.chan, KQUAD.type, trpy);
  %fprintf('Sending to channel %i, id %i, type %i\n',KQUAD.chan,KQUAD.id,KQUAD.type);
  pause(0.03);
end
