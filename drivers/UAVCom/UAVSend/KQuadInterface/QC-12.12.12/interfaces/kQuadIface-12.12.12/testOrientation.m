clear all
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

vec=[1;0;0]

R2=[cos(-pi/4) -sin(-pi/4) 0;sin(-pi/4) cos(-pi/4) 0; 0 0 1];
R1=[0 0 -1; 0 1 0; 1 0 0];
Rtot=R1*R2;
n1vec=R1*vec
n2vec=Rtot*vec
figure(1)
clf
grid on
xlabel('x');
ylabel('y');
zlabel('z');
hold on
plot3([0 vec(1)],[0 vec(2)],[0 vec(3)],'r-');
plot3([0 n1vec(1)],[0 n1vec(2)],[0 n1vec(3)],'b-');
plot3([0 n2vec(1)],[0 n2vec(2)],[0 n2vec(3)],'g-');