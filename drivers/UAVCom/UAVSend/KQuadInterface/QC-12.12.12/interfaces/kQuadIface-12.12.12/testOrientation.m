clear all

SetMagicPaths;
ipcAPI('connect');
ipcAPI('subscribe','KeyPress');
ipcAPI('set_msg_queue_length','KeyPress',1);

ipcAPI('subscribe','Quad1/AprilInfo');
ipcAPI('set_msg_queue_length','Quad1/AprilInfo',1);
%{
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
%}
figure(1)
cla
axis equal
grid on
xlim([-2 2]);
ylim([-2 2]);
zlim([-2 2]);
hold on

xlabel('x');
ylabel('y');
zlabel('z');

square=[-.1 -.1; -.1 .1; .1 .1; .1 -.1];
orient1=[0 0 0; 0 0 1];
orient2=[0 0 0; 1 0 0];
%orplot=fill(square(:,1),square(:,2),'g');
ovplot1=plot3(orient1(:,1),orient1(:,2),orient1(:,3),'r-');
ovplot2=plot3(orient2(:,1),orient2(:,2),orient2(:,3),'k-');
while(1)
    msgs=ipcAPI('listenWait',0);
    nmsgs=length(msgs);
    for i=1:nmsgs
        name=msgs(i).name;
        data=msgs(i).data;
        id=data(1);
        t=double(typecast(data(2:9),'double'));
        rest=data(10:end);
        pos1=typecast(rest(1:8*3),'double')*12*0.0254;
        ypr=typecast(rest(8*3+1:8*6),'double');
        dist=typecast(rest(8*6+1:8*7),'double');
        rot=typecast(rest(8*7+1:end),'double');
        rot=reshape(rot,3,3);
        
        pos1=[0 0 0];
        %set(orplot,'XData',square(:,1)+pos1(1),'YData',square(:,1)+pos1(2))
        set(ovplot1,'XData',orient1(:,1)+pos1(1),'YData',orient1(:,2)+pos1(2),'ZData',orient1(:,3)+pos1(3))
        set(ovplot2,'XData',orient2(:,1)+pos1(1),'YData',orient2(:,2)+pos1(2),'ZData',orient2(:,3)+pos1(3))
        drawnow
    end
end