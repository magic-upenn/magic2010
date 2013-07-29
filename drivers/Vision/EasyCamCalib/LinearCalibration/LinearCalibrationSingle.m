DEBUG=1;
% Preliminaries
load 'CalibData_8_refined.mat';
%load 'CalibData3.mat';
OldData=ImageData;
clear ImageData;
[dummy,N]=size(OldData);
for i=1:1:N
 ImageData(i).Info=OldData(i).Info;
 ImageData(i).Boundary=OldData(i).Conic;
 ImageData(i).ImageRGB=OldData(i).ImageRGB;
 ImageData(i).ImageGray=OldData(i).ImageGray;
end;
% Load opto-tracker and the initial points coming from auto corner detection
HandleFig=zeros(1,N);
for i=1:1:N
 ImageData(i).Hand2Opto=[OldData(i).OptoR transpose(OldData(i).OptoT);0 0 0 1];
 ImageData(i).PosPlaneAuto= [transpose(OldData(i).AutoCorner.Coordinates); ones(1,length(OldData(i).AutoCorner.Coordinates))];
 ImageData(i).PosImageAuto = [transpose(OldData(i).AutoCorner.Points);ones(1,length(OldData(i).AutoCorner.Points))];
 if DEBUG
  HandleFig(i)=figure;
  imshow(ImageData(i).ImageGray);
  hold on;
  plot(ImageData(i).PosImageAuto(1,:),ImageData(i).PosImageAuto(2,:),'r.'); 
 end;
end;

% We are ready to go
% First linear calibration with automatically detected points
METHOD=1;
for i=1:1:N
 ImageData(i).InitCalib=SingleImgCalibration(ImageData(i).PosPlaneAuto,ImageData(i).PosImageAuto,METHOD);
 ImageData(i).InitCalib.ReProjError=ReProjectionError(ImageData(i).InitCalib,ImageData(i).PosPlaneAuto,ImageData(i).PosImageAuto);
 if DEBUG
  figure(HandleFig(i));
  plot(ImageData(i).InitCalib.ReProjError.ReProjPts(1,:),ImageData(i).InitCalib.ReProjError.ReProjPts(2,:),'gx');
 end;
end;
if DEBUG
 pause;
end;


%-------------------------------------
% TO DO
% Check if putting non-linear optimization before looking for new points
% helps!
%------------------------------------


% Get additional points
for i=1:1:N
 %---------------
 % I will use the data coming from OldData (should be removed afterwards)
 %ImgStruct=struct('Info',ImageData(i).Info,'ImageGray',ImageData(i).ImageGray,'Conic',ImageData(i).Boundary);
 %[ImageData(i).PosPlane, ImageData(i).PosImage]=GetMorePoints(ImgStruct,ImageData(i).InitCalib,ImageData(i).PosPlaneAuto,ImageData(i).PosImageAuto);
 ImageData(i).PosPlane=OldData(i).PosPlane;
 ImageData(i).PosImage=OldData(i).PosImg;
 %----------------
 if DEBUG
   figure(HandleFig(i));
   plot(ImageData(i).PosImage(1,:),ImageData(i).PosImage(2,:),'mo');
 end;
end;

% Re-calibrate using the linear method
METHOD=1;
for i=1:1:N
 ImageData(i).FinalCalib=SingleImgCalibration(ImageData(i).PosPlane,ImageData(i).PosImage,METHOD);
 ImageData(i).FinalCalib.ReProjError=ReProjectionError(ImageData(i).FinalCalib,ImageData(i).PosPlane,ImageData(i).PosImage);
%-----------------------------
% IDEA: Discard points that have higher re-projection error and re-compute
%----------------------------- 
 if DEBUG
  figure(HandleFig(i));
  plot(ImageData(i).FinalCalib.ReProjError.ReProjPts(1,:),ImageData(i).FinalCalib.ReProjError.ReProjPts(2,:),'b+');
 end;
end;
if DEBUG
 pause;
end;

%----------------------------------------------------
%This should be the overall refinment (now I am copying)
for i=1:1:N
 ImageData(i).OptimCalib=struct('eta',OldData(i).OptimCalib.eta,'aratio',OldData(i).OptimCalib.aratio,'skew',OldData(i).OptimCalib.skew,'focal',OldData(i).OptimCalib.focal,'qsi',OldData(i).OptimCalib.qsi,'center',OldData(i).OptimCalib.center);
 ImageData(i).OptimCalib.Keta=[ImageData(i).OptimCalib.aratio*ImageData(i).OptimCalib.eta ImageData(i).OptimCalib.skew*ImageData(i).OptimCalib.eta ImageData(i).OptimCalib.center(1);0 ImageData(i).OptimCalib.aratio^-1*ImageData(i).OptimCalib.eta ImageData(i).OptimCalib.center(2); 0 0 1];
 ImageData(i).OptimCalib.K=[ImageData(i).OptimCalib.aratio*ImageData(i).OptimCalib.focal ImageData(i).OptimCalib.skew*ImageData(i).OptimCalib.focal ImageData(i).OptimCalib.center(1);0 ImageData(i).OptimCalib.aratio^-1*ImageData(i).OptimCalib.focal ImageData(i).OptimCalib.center(2); 0 0 1];
 ImageData(i).OptimCalib.T=[OldData(i).OptimCalib.R OldData(i).OptimCalib.T;0 0 0 1];
end;
 %----------------------------------------------------
for i=1:1:N
 ImageData(i).OptimCalib.ReProjError=ReProjectionError(ImageData(i).OptimCalib,ImageData(i).PosPlane,ImageData(i).PosImage);
  if DEBUG
  figure(HandleFig(i));
  plot(ImageData(i).OptimCalib.ReProjError.ReProjPts(1,:),ImageData(i).OptimCalib.ReProjError.ReProjPts(2,:),'co');
 end;
end;
if DEBUG
 pause;
end;
  
return
%HAND EYE ------------------------------------
%Input Roquette (DEBUG)
Tx=[-0.9968   -0.0702    0.0384    4.7738; 0.0467   -0.8997   -0.4339   -3.2716;0.0650   -0.4308    0.9001    1.8012;0 0 0 1.0000];
%Input Abed
Tx =[ -0.9929    0.0479    0.1085    0.3897;-0.0917   -0.8904   -0.4458   -0.4001; 0.0753   -0.4526    0.8885   -1.2160;0 0 0 1.0000];
%My estimation
Tx=[-0.9918   -0.0988    0.0808    0.9829;  0.0515   -0.8890   -0.4551   -2.2612; 0.1168   -0.4472    0.8868    0.8816;0         0         0    1.0000];

%MyStuff
[dummy,N]=size(ImageData);
Nm=N-1;

%number of motions
for i=1:1:Nm
  HandEye.CameraMotion(:,:,i)=[ImageData(i+1).OptimCalib.T*inv(ImageData(i).OptimCalib.T)];
  HandEye.HandMotion(:,:,i)=[inv(ImageData(i+1).Hand2Opto)*ImageData(i).Hand2Opto];
end;
[HandEye.InputRotInfo,HandEye.InputTransInfo]=CheckInputConsistency(HandEye,DEBUG);
%The system has the form HandMotion*X=X*CameraMotion with X transforming
%hand coordinates into eye coordinates.
[HandEye.Tx,HandEye.Info]=EstimateHEfromModifiedDQ(HandEye.HandMotion,HandEye.CameraMotion);

for i=1:1:N
 % ABED 
 %ImageData(i).Eye2Hand=[OldData(1).HE.OptimCalib(1:3,1:3) -inv(OldData(1).HE.OptimCalib(1:3,1:3))*OldData(1).HE.OptimCalib(1:3,4);0 0 0 1];
 % jpbar
 ImageData(i).Eye2Hand=HandEye.Tx;
 ImageData(i).Eye2Opto=ImageData(i).Hand2Opto*ImageData(i).Eye2Hand;
 ImageData(i).Plane2Opto=ImageData(1).Eye2Opto*ImageData(1).OptimCalib.T;  
 auxStruct=ImageData(i).OptimCalib;
 auxStruct.T=inv(ImageData(i).Eye2Opto)*ImageData(i).Plane2Opto;
 ImageData(i).HEReProjError=ReProjectionError(auxStruct,ImageData(i).PosPlane,ImageData(i).PosImage);
 if DEBUG
  figure(HandleFig(i));
  plot(ImageData(i).HEReProjError.ReProjPts(1,:),ImageData(i).HEReProjError.ReProjPts(2,:),'rs');
 end;
end;
    
