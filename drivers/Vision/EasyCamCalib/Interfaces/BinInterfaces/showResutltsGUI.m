function showResutltsGUI(hObject,handles,i,type)


if strcmp(type,'generatedpoints')
    axes(handles.image_calib1);
    image(handles.ImageData(i).ImageRGB);
    axis image; axis off; hold on;
    plot(handles.ImageData(i).PosImage(1,:),handles.ImageData(i).PosImage(2,:),'r+');
    hold off
    axis off
    drawnow
    disp(sprintf('Image %d has generated %d more points',i,length(handles.ImageData(i).PosPlane)-length(handles.ImageData(i).PosPlaneAuto)));
end

if strcmp(type,'secondcalib')
    set(handles.radiobutton_showfinal,'Value',1);
    DisplayResults(handles,i,1);
    DisplayRepError(handles,1,handles.dispVALUES);
end

if strcmp(type,'firstcalib')
    disp(sprintf('Inital calibration: qsi=%f, eta=%f, focal=%f, center=(%f,%f), skew=%f aratio=%f',...
        handles.ImageData(i).InitCalib.qsi,handles.ImageData(i).InitCalib.eta,handles.ImageData(i).InitCalib.focal,handles.ImageData(i).InitCalib.center(1),...
        handles.ImageData(i).InitCalib.center(2), handles.ImageData(i).InitCalib.skew,handles.ImageData(i).InitCalib.aratio))
    DisplayResults(handles,i,0);
    DisplayRepError(handles,0,handles.dispVALUES);
    set(handles.radiobutton_showinit,'Value',1);
end

if strcmp(type,'autocornerfinder')
    axes(handles.image_calib1);
    image(handles.ImageData(i).ImageRGB);
    axis image; axis off; hold on;
    plot(handles.ImageData(i).PosImageAuto(1,:),handles.ImageData(i).PosImageAuto(2,:),'g*');
    for j=1:length(handles.ImageData(i).PosPlaneAuto)
        text(handles.ImageData(i).PosImageAuto(1,j),handles.ImageData(i).PosImageAuto(2,j),sprintf('(%d,%d)',...
            handles.ImageData(i).PosPlaneAuto(1,j),handles.ImageData(i).PosPlaneAuto(2,j)),...
            'FontSize',7,'Color',[233 138 62]./255);
    end
    hold off
    axis off
    drawnow
end

if strcmp(type,'boundarydetection')
    if handles.ISARTHROSCOPIC
        set(handles.switch_boundary,'Enable','on');
    else
        set(handles.switch_boundary,'Enable','off');
    end
end


guidata(hObject,handles);