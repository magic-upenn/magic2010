function AprilVis_V2()
clear all;

SetMagicPaths;
ipcAPI('connect');
ipcAPI('subscribe','Quad1/AprilInfo');
ipcAPI('set_msg_queue_length','Quad1/AprilInfo',1);

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

orient=[0 0 0; ...
        0 0 .5];

%% initial plot
figure(1)
cla
axis equal
grid on
xlim([-2 5]);
ylim([-2 2]);
zlim([-2 5]);
hold on

xlabel('x');
ylabel('y');
zlabel('z');


%squareplot=plot3(square(:,1),square(:,2),square(:,3),'k');
s1plot=plot3(s1(:,1),s1(:,2),s1(:,3),'b');
s2plot=plot3(s2(:,1),s2(:,2),s2(:,3),'m');
s3plot=plot3(s3(:,1),s3(:,2),s3(:,3),'g');
s4plot=plot3(s4(:,1),s4(:,2),s4(:,3),'r');
orplot=plot3(orient(:,1),orient(:,2),orient(:,3),'k');


%% rotation matrix plot
x=[1 0 0];
y=[0 1 0];
z=[0 0 1];
xplot=plot3([0 x(1)],[0 x(2)],[0 x(3)],'r');
yplot=plot3([0 y(1)],[0 y(2)],[0 y(3)],'g');
zplot=plot3([0 z(1)],[0 z(2)],[0 z(3)],'b');

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
        
        
        rot=typecast(rest(8*7+1:end),'double');
        rot=reshape(rot,3,3);
        pos=[0 0 1; 0 -1 0; 1 0 0]*pos1';
        H=[rot pos; 0 0 0 1];
        cRa=inv(H);
        rot=cRa(1:3,1:3);
        pos=cRa(1:3,4);
        
        ts1=(rot*s1')';
        ts2=(rot*s2')';
        ts3=(rot*s3')';
        ts4=(rot*s4')';
        
        torient=(rot*orient')';
        x1=rot(:,1);
        y1=rot(:,2);
        z1=rot(:,3);
        set(xplot,'XData',[0 x1(1)],'YData',[0 x1(2)],'ZData',[0 x1(3)]);
        set(yplot,'XData',[0 y1(1)],'YData',[0 y1(2)],'ZData',[0 y1(3)]);
        set(zplot,'XData',[0 z1(1)],'YData',[0 z1(2)],'ZData',[0 z1(3)]);
        %{
        set(s1plot,'XData',ts1(:,1)+pos(1), ...
                'YData',ts1(:,2)+pos(2), ...
                'ZData',ts1(:,3)+pos(3));
        
        set(s2plot,'XData',ts2(:,1)+pos(1), ...
                'YData',ts2(:,2)+pos(2), ...
                'ZData',ts2(:,3)+pos(3));
            
        set(s3plot,'XData',ts3(:,1)+pos(1), ...
                'YData',ts3(:,2)+pos(2), ...
                'ZData',ts3(:,3)+pos(3));
            
        set(s4plot,'XData',ts4(:,1)+pos(1), ...
                'YData',ts4(:,2)+pos(2), ...
                'ZData',ts4(:,3)+pos(3));
            
        set(orplot,'XData',torient(:,1)+pos(1), ...
                    'YData',torient(:,2)+pos(2), ...
                    'ZData',torient(:,3)+pos(3));
        %}
        drawnow
    end
end
