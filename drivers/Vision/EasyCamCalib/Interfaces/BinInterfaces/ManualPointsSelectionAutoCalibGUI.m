function outstruct = ManualPointsSelectionAutoCalibGUI(ImageDataIn)

N=length(ImageDataIn);

%% Configurations
DEBUG = 0;
ImageData=ImageDataIn;

%% Select the points
cancel = 0;
for i=1:1:N
    [ImageData(i).PosImage ImageData(i).PosPlane cancel] = ManualPointSelection(ImageDataIn(i));
    if cancel
        break
    end
end

%% We have to recalibrate now
METHOD=1;
for i=1:1:N
 ImageData(i).FinalCalib=SingleImgCalibration(ImageData(i).PosPlane,ImageData(i).PosImage,METHOD);
 ImageData(i).FinalCalib.ReProjError=ReProjectionError(ImageData(i).FinalCalib,ImageData(i).PosPlane,ImageData(i).PosImage);
 if DEBUG
  figure;
  imshow(ImageData(i).ImageRGB)
  hold on
  plot(ImageData(i).PosImage(1,:),ImageData(i).PosImage(2,:),'rd');
  plot(ImageData(i).FinalCalib.ReProjError.ReProjPts(1,:),ImageData(i).FinalCalib.ReProjError.ReProjPts(2,:),'y+');
 end;
 disp(sprintf('Final calibration: qsi=%f, eta=%f, focal=%f, center=(%f,%f), skew=%f aratio=%f',...
     ImageData(i).FinalCalib.qsi,ImageData(i).FinalCalib.eta,ImageData(i).FinalCalib.focal,ImageData(i).FinalCalib.center(1),...
     ImageData(i).FinalCalib.center(2), ImageData(i).FinalCalib.skew,ImageData(i).FinalCalib.aratio))
end;

outstruct = ImageData;