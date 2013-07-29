function DrawAll(handles,i)
axes(handles.image_calib1);
image(handles.ImageData(i).ImageRGB);
axis image; axis off; hold on;
if(handles.switchCOORDINATES)
    if ~isempty(handles.ImageData(i).PosImage)
        for j=1:length(handles.ImageData(i).PosPlane)
            text(handles.ImageData(i).PosImage(1,j),handles.ImageData(i).PosImage(2,j),sprintf('(%g,%g)',...
                handles.ImageData(i).PosPlane(1,j),handles.ImageData(i).PosPlane(2,j)),...
                'FontSize',8,'Color',[233 138 62]./255);
        end
        %find the origin
        temp = sum(round(handles.ImageData(i).PosPlane)==([0;0;1]*ones(1,size(handles.ImageData(i).PosPlane,2))));
        [a index_origin] = find(temp==3);
        %find the x direction
        temp = sum(round(handles.ImageData(i).PosPlane)==([round(handles.ImageData(i).Info.GridSize);0;1]*ones(1,size(handles.ImageData(i).PosPlane,2))));
        [a index_direction_x] = find(temp==3);
        %find the y direction
        temp = sum(round(handles.ImageData(i).PosPlane)==([0;round(handles.ImageData(i).Info.GridSize);1]*ones(1,size(handles.ImageData(i).PosPlane,2))));
        [a index_direction_y] = find(temp==3);
        handles.FigH(i).Origin = [];
        %plot the points and the directional vectors
        plot(handles.ImageData(i).PosImage(1,:),handles.ImageData(i).PosImage(2,:),'r+');
        plot(handles.ImageData(i).PosImage(1,index_origin),handles.ImageData(i).PosImage(2,index_origin),'ys');
        text(handles.ImageData(i).PosImage(1,index_direction_x),handles.ImageData(i).PosImage(2,index_direction_x),'x','FontSize',14,'Color',[0 0.5 1],'FontWeight','bold');
        quiver(handles.ImageData(i).PosImage(1,index_origin),handles.ImageData(i).PosImage(2,index_origin),handles.ImageData(i).PosImage(1,index_direction_x)-handles.ImageData(i).PosImage(1,index_origin),handles.ImageData(i).PosImage(2,index_direction_x)-handles.ImageData(i).PosImage(2,index_origin),'LineWidth',2,'Color',[255 200 0]/255, 'MaxHeadSize', 8);
        text(handles.ImageData(i).PosImage(1,index_direction_y),handles.ImageData(i).PosImage(2,index_direction_y),'y','FontSize',14,'Color',[0 0.5 1],'FontWeight','bold');
        quiver(handles.ImageData(i).PosImage(1,index_origin),handles.ImageData(i).PosImage(2,index_origin),handles.ImageData(i).PosImage(1,index_direction_y)-handles.ImageData(i).PosImage(1,index_origin),handles.ImageData(i).PosImage(2,index_direction_y)-handles.ImageData(i).PosImage(2,index_origin),'LineWidth',2,'Color',[0 200 127]/255, 'MaxHeadSize', 8);
    end
end
if(handles.switchPOSIMAGEAUTO)
    if ~isempty(handles.ImageData(i).PosImageAuto)
        plot(handles.ImageData(i).PosImageAuto(1,:),handles.ImageData(i).PosImageAuto(2,:),'g*');
    end
end
if(handles.switchPOSIMAGE)
    if ~isempty(handles.ImageData(i).PosImage)
        plot(handles.ImageData(i).PosImage(1,:),handles.ImageData(i).PosImage(2,:),'r+');
    end
end
if(handles.switchBOUNDARY)
    [points,h]=CD_plot_conic_curve_handler(handles.ImageData(i).Boundary.Omega, handles.ImageData(i).ImageRGB, [255 0 0],handles);
    plot(handles.ImageData(i).Boundary.LensAngleImage(1),handles.ImageData(i).Boundary.LensAngleImage(2),'gd');
    text(10,15, sprintf('Lens angle: %d',handles.ImageData(i).Boundary.LensAngle), 'Color', [1 1 1])
end
if(handles.switchINITCALIB)
    plot(handles.ImageData(i).InitCalib.ReProjError.ReProjPts(1,:),handles.ImageData(i).InitCalib.ReProjError.ReProjPts(2,:),'yd');
end
if(handles.switchFINALCALIB)
    plot(handles.ImageData(i).FinalCalib.ReProjError.ReProjPts(1,:),handles.ImageData(i).FinalCalib.ReProjError.ReProjPts(2,:),'gp');
end
if(handles.switchOPTIMCALIB)
    plot(handles.ImageData(i).OptimCalib.ReProjError.ReProjPts(1,:),handles.ImageData(i).OptimCalib.ReProjError.ReProjPts(2,:),'cs');
end
if(handles.switchBLAMEPOINTS)
    n=10;
    [dummy,N]=size(handles.ImageData(i).PosPlane);
    %Project
    if(handles.showOPT==0)
        CalibStruct=handles.ImageData(i).InitCalib;
    end
    if(handles.showOPT==1)
        CalibStruct=handles.ImageData(i).FinalCalib;
    end
    if(handles.showOPT==2)
        CalibStruct=handles.ImageData(i).OptimCalib;
    end   
    Pts=CalibStruct.T(1:3,[1 2 4])*handles.ImageData(i).PosPlane;
    aux=Pts(3,:)+(Pts(3,:).^2-4*CalibStruct.qsi*(Pts(1,:).^2+Pts(2,:).^2)).^(1/2);
    ReProjPts=CalibStruct.K*[2*Pts(1,:)./aux;2*Pts(2,:)./aux;ones(1,N)];
    %Compute distance
    ds=sqrt(ones(1,3)*(handles.ImageData(i).PosImage-ReProjPts).^2);
    dsa=[ds;1:length(ds)];
    dsas=sortrows(transpose(dsa),1);
    plot(handles.ImageData(i).PosImage(1,dsas((end-n+1):end,2)), handles.ImageData(i).PosImage(2,dsas((end-n+1):end,2)),'yo','MarkerSize',8)
    for j=1:n
       text(handles.ImageData(i).PosImage(1,dsas(end+1-j,2)),handles.ImageData(i).PosImage(2,dsas(end+1-j,2)),...
           sprintf('%.2f',dsas(end+1-j,1)),'FontSize',8,'Color',[0 127 0]./255,'BackgroundColor',[.7 .9 .7]); 
    end
%     OutStruct.RMS=sqrt(mean(ds));
%     [ds,ind]=sort(ds,'descend');
%     OutStruct.Median=sqrt(ds(round(N/2)));
%     OutStruct.MaxError=sqrt(ds(1));
end
% if(handles.switchHANDEYE)
%     set(handles.FigH.HandEye,'visible','on');
% else
%     set(handles.FigH.HandEye,'visible','off');
% end
% if(handles.switchHANDEYEREFINED)
%     set(handles.FigH.HandEyeRefined,'visible','on');
% else
%     set(handles.FigH.HandEyeRefined,'visible','off');
% end
hold off
axis off
%display the calibration parameters
drawnow