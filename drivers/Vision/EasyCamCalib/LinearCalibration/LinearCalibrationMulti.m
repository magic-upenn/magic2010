clc 
close all 
clear all

addpath ('./BinLinearCalib/')
return
load ../data

%% Configurations
DEBUG=1;
METHOD=2;
N = [1:length(ImageData)];

%% Start Calibration
for i=N
    if DEBUG
        HandleFig(i)=figure;
        imshow(ImageData(i).ImageGray);
        hold on;
        plot(ImageData(i).PosImageAuto(1,:),ImageData(i).PosImageAuto(2,:),'r.');
        title(sprintf('Image %d',i))
    end;
end

%% First linear calibration with automatically detected points
for i=N
 ImageData(i).InitCalib=SingleImgCalibration(ImageData(i).PosPlaneAuto,ImageData(i).PosImageAuto,METHOD);
 ImageData(i).InitCalib.ReProjError=ReProjectionError(ImageData(i).InitCalib,ImageData(i).PosPlaneAuto,ImageData(i).PosImageAuto);
 if DEBUG
  figure(HandleFig(i));
  plot(ImageData(i).InitCalib.ReProjError.ReProjPts(1,:),ImageData(i).InitCalib.ReProjError.ReProjPts(2,:),'gx');
 end;
 disp(sprintf('Inital calibration: qsi=%f, eta=%f, focal=%f, center=(%f,%f), skew=%f aratio=%f',...
     ImageData(i).InitCalib.qsi,ImageData(i).InitCalib.eta,ImageData(i).InitCalib.focal,ImageData(i).InitCalib.center(1),...
     ImageData(i).InitCalib.center(2), ImageData(i).InitCalib.skew,ImageData(i).InitCalib.aratio))
end;

%% Get additional points
for i=N
 ImgStruct=struct('Info',ImageData(i).Info,'ImageGray',ImageData(i).ImageGray,'Conic',ImageData(i).Boundary);
 [ImageData(i).PosPlane, ImageData(i).PosImage]=GetMorePoints(ImgStruct,ImageData(i).InitCalib,ImageData(i).PosPlaneAuto,ImageData(i).PosImageAuto);
 if DEBUG
   figure(HandleFig(i));
   plot(ImageData(i).PosImage(1,:),ImageData(i).PosImage(2,:),'mo');
 end;
 disp(sprintf('Image %d has generated %d more points',i,length(ImageData(i).PosPlane)-length(ImageData(i).PosPlaneAuto)))
end;

%% Re-calibrate using the linear method
METHOD=1;
for i=N
 ImageData(i).FinalCalib=SingleImgCalibration(ImageData(i).PosPlane,ImageData(i).PosImage,METHOD);
 ImageData(i).FinalCalib.ReProjError=ReProjectionError(ImageData(i).FinalCalib,ImageData(i).PosPlane,ImageData(i).PosImage);
 if DEBUG
  figure(HandleFig(i));
  plot(ImageData(i).FinalCalib.ReProjError.ReProjPts(1,:),ImageData(i).FinalCalib.ReProjError.ReProjPts(2,:),'b+');
 end;
 disp(sprintf('Final calibration: qsi=%f, eta=%f, focal=%f, center=(%f,%f), skew=%f aratio=%f',...
     ImageData(i).FinalCalib.qsi,ImageData(i).FinalCalib.eta,ImageData(i).FinalCalib.focal,ImageData(i).FinalCalib.center(1),...
     ImageData(i).FinalCalib.center(2), ImageData(i).FinalCalib.skew,ImageData(i).FinalCalib.aratio))
end;

%% Save only the computed calibrations
j = 1;
for i=N
    temp(j) = ImageData(i);
    j = j+1;
end
clear ImageData
ImageData = temp;
save ../../temp/CalibLinearCalibration.mat ImageData

    
