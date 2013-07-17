function DrawTrans(hObject,handles,ind)
axes(handles.trans);
cla;
% axis equal
% axis off
% rotate3d on;
% set(h,'RotateStyle','box','Enable','on');
% zoom on;
GRID=handles.ImageData(1).Info.GridSize;
NUMBEROFSQUARES=10;
switch handles.showOPT
    case 0
    calibstruct='InitCalib';
    case 1
    calibstruct='FinalCalib';
    case 2
    calibstruct='OptimCalib';
end

%% Set the scales
acc=[];
for i=1:length(handles.ImageData)
   acc=[acc norm(eval(sprintf('handles.ImageData(i).%s.T(1:3,4)',calibstruct)))]; 
end
scale=mean(acc)*0.2;
scaleaxis=scale/5;
width=0.2*scale; %percentage over the length of the camera


%% Draw the calibration grid
% view(-37.5,15)
hold on
n=(GRID*NUMBEROFSQUARES)/2;
gridimage=checkerboard(NUMBEROFSQUARES,NUMBEROFSQUARES/2,NUMBEROFSQUARES/2)>0.5;
surface('XData',[-n n; -n n],'YData',[-n -n; n n],...
    'ZData',[0 0; 0 0],'CData',flipdim(im2double(gridimage),1),...
    'FaceColor','texturemap','EdgeColor','none');
colormap('Gray');
plot3([0 2.5*GRID], [0 0], [0 0],'Color',[255 200 0]./255,'LineWidth',2);
plot3([0 0], [0 2.5*GRID], [0 0],'Color',[0 200 127]./255,'LineWidth',2);
plot3([0 0], [0 0], [0 2.5*GRID],'b','LineWidth',2);
text(2*GRID,0,0,'X','FontSize',9,'FontWeight','bold','Color', [255 140 0]./255);
text(0,2*GRID,0,'Y','FontSize',9,'FontWeight','bold','Color', [255 140 0]./255);
text(0,0,2*GRID,'Z','FontSize',9,'FontWeight','bold','Color', [255 140 0]./255);

%% Draw the cameras
for i=1:length(handles.ImageData)
    T=inv(eval(sprintf('handles.ImageData(i).%s.T',calibstruct)));
    
    xAxis(:,1)=scaleaxis*T(1:3,1);
    yAxis(:,1)=scaleaxis*T(1:3,2);
    zAxis(:,1)=scale*T(1:3,3);
    
    v0=T*[0;0;0;1];
    v1=T*[width;width;scale;1];
    v2=T*[width;-width;scale;1];
    v3=T*[-width;width;scale;1];
    v4=T*[-width;-width;scale;1];
    
    Px=[v0(1) v0(1) v0(1) v0(1);v1(1) v1(1) v4(1) v4(1);v2(1) v3(1) v3(1) v2(1)];
    Py=[v0(2) v0(2) v0(2) v0(2);v1(2) v1(2) v4(2) v4(2);v2(2) v3(2) v3(2) v2(2)];
    Pz=[v0(3) v0(3) v0(3) v0(3);v1(3) v1(3) v4(3) v4(3);v2(3) v3(3) v3(3) v2(3)];
    
    if i==ind
        color=[1 0 0];
    else
        color=[0.1 0.1 0.7];
    end
    h = fill3(Px,Py,Pz,color);
    if i==ind
        set(h,'facealpha',1);
    else
        set(h,'facealpha',.2);
    end
    plot3(v0(1),v0(2),v0(3),'.','MarkerSize',18);
    plot3([v0(1) v0(1)+xAxis(1)],[v0(2) v0(2)+xAxis(2)],[v0(3) v0(3)+xAxis(3)],'r','LineWidth',2);
    plot3([v0(1) v0(1)+yAxis(1)],[v0(2) v0(2)+yAxis(2)],[v0(3) v0(3)+yAxis(3)],'g','LineWidth',2);
end
if handles.autotrans
    %NOTE: handle the case when the origin is not in the image (index_origin is empty)
    %find the origin
    temp = sum(round(handles.ImageData(ind).PosPlane)==([0;0;1]*ones(1,size(handles.ImageData(ind).PosPlane,2))));
    [a index_origin] = find(temp==3);
    %find the x direction
    temp = sum(round(handles.ImageData(ind).PosPlane)==([round(handles.ImageData(ind).Info.GridSize);0;1]*ones(1,size(handles.ImageData(ind).PosPlane,2))));
    [a index_direction_x] = find(temp==3);
    %X vector
    Xvec = handles.ImageData(ind).PosImage(1:2,index_direction_x)-handles.ImageData(ind).PosImage(1:2,index_origin);
    az = atan2(Xvec(2),Xvec(1))*180/pi;
    view(az,90);
end
drawnow
hold off
axis equal
axis off
if handles.rotate
    rotate3d on;
end
if handles.zoom
    zoom on;
end
guidata(hObject,handles);