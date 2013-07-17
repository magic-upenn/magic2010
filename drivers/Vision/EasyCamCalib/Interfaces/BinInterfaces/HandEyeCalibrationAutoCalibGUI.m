function outstruct = HandEyeCalibrationAutoCalibGUI (ImageData,METHOD,FILTER)

DEBUG=0;
[dummy,N]=size(ImageData);
for i=1:1:N
 [theta,w]=R2Euler(ImageData(i).Hand2Opto(1:3,1:3));
 ImageData(i).Hand2Opto(1:3,1:3)=Euler2R(theta,w);
end;

HandEye=GenerateHandEyeStruct(ImageData,FILTER);

if DEBUG
 figure;
 Ns=max(size(HandEye.Select));
 subplot(211);
 plot(1:HandEye.N,HandEye.InfoInput.CameraMotionAngle,'r-o',1:HandEye.N,HandEye.InfoInput.HandMotionAngle,'b-s',1:HandEye.N,HandEye.InfoInput.AngleRotAxis,'g-x');
 legend('Rot Angle Camera Motion','Rot Angle Hand Motion','Angle between Rot Axis','Location','Best');
 hold on;
 plot(HandEye.Select,zeros(1,max(size(HandEye.Select))),'bo');
 grid MINOR;
 subplot(212)
 plot(1:HandEye.N,HandEye.InfoInput.CameraMotionTrans,'r-o',1:HandEye.N,HandEye.InfoInput.HandMotionTrans,'b-s');
 legend('Amplitude Camera Motion (mm)','Amplitude Hand Motion (mm)','Location','Best');
 hold on;
 plot(HandEye.Select,zeros(1,max(size(HandEye.Select))),'bo');
 grid MINOR;
end;

%The system has the form HandMotion*X=X*CameraMotion with X transforming
%hand coordinates into eye coordinates.

 if METHOD==1
  [Tx,Info]=EstimateHEfromModifiedDQ(HandEye.HandMotion(:,:,HandEye.Select),HandEye.CameraMotion(:,:,HandEye.Select));
 end;
 if METHOD==2
  %[Tx,lambda,Info]=EstimateHEVariableScale(HandEye.HandMotion,HandEye.CameraMotion);
  [Tx,Info]=EstimateHEClassic(HandEye.HandMotion(:,:,HandEye.Select),HandEye.CameraMotion(:,:,HandEye.Select));
 end;
 if METHOD==3
  MINSAMPLES=2;
  THRESHOLD=2.5;
  [Tx,Info,Inliers]=RansacEstimationHEModifiedDQ(HandEye.HandMotion(:,:,HandEye.Select),...
      HandEye.CameraMotion(:,:,HandEye.Select),[MINSAMPLES THRESHOLD]);
  HandEye.Select=HandEye.Select(1,Inliers);
 end;
 if METHOD==4
  %[Tx,lambda,Info]=EstimateHEVariableScale(HandEye.HandMotion,HandEye.CameraMotion);
  [Tx,Info]=NewNewEstimateHEClassic(HandEye.HandMotion(:,:,HandEye.Select),HandEye.CameraMotion(:,:,HandEye.Select),01);
  HandEye.Select=HandEye.Select(Info.Select);
 end;
 
 HandEye=EvaluateEstimation(HandEye,Tx);
 
 [dummy,N]=size(ImageData);
 % Initiate
 for i=1:1:N
 ImageData(i).Eye2Hand=Tx;
 ImageData(i).Eye2Opto=ImageData(i).Hand2Opto*ImageData(i).Eye2Hand;
 end
% Compute Plane2Opto transformation
aux=HandEye.Motions(HandEye.Select,:);
auxStruct=[];
for i=1:1:N
 if find(i==aux)
  ImageData(i).Valid=1;
  auxStruct=[auxStruct reshape(ImageData(i).Eye2Opto*ImageData(i).OptimCalib.T,16,1)];
 else
  ImageData(i).Valid=0;
 end;
end;
[dummy,n]=size(auxStruct);
auxStruct=reshape(auxStruct,4,4,n);
MeanPlane2Opto= eucRigidTransformationMean(auxStruct);
ComparisonTable=[];
% Put Everything in order
for i=1:1:N
 ImageData(i).Plane2Opto=MeanPlane2Opto;  
 auxStruct=ImageData(i).OptimCalib;
 auxStruct.T=inv(ImageData(i).Eye2Opto)*ImageData(i).Plane2Opto;
 ImageData(i).HEReProjError=ReProjectionError(auxStruct,ImageData(i).PosPlane,ImageData(i).PosImage);
 aux=inv(auxStruct.T)*ImageData(i).OptimCalib.T;
 [theta w]=R2Euler(aux(1:3,1:3));
 aux=[ImageData(i).OptimCalib.ReProjError.RMS; ImageData(i).HEReProjError.RMS; theta*180/pi;norm(aux(1:3,4))];
 ComparisonTable=[ComparisonTable aux];
 if DEBUG
  figure;
  imshow(ImageData(i).ImageGray);
  hold on;
  plot(ImageData(i).HEReProjError.ReProjPts(1,:),ImageData(i).HEReProjError.ReProjPts(2,:),'rs');
  plot(ImageData(i).PosImage(1,:),ImageData(i).PosImage(2,:),'g+');
 end;
end;

outstruct = ImageData;
