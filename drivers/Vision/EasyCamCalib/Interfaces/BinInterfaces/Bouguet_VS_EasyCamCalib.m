function Bouguet_VS_EasyCamCalib(ImageData)

VISUALIZE=0; %show visual output   
TEXT=0; %show text output


%% Bouguet Calibration
n_ima=length(ImageData);        %number of images
est_dist=[1; 1; 0; 0; 0];       %estimate distortion order
est_alpha=0;                    %estimate skew
est_fc=[1;1];                   %estimate focal distances
est_aspect_ratio=0;             %estimate aspect ratio
%Parse the data
for i=1:n_ima
    eval(sprintf('x_%d=ImageData(%d).PosImage(1:2,:)-1;',i,i));
    eval(sprintf('X_%d=ImageData(%d).PosPlane(1:3,:)-1;',i,i));
end
%Go Bouguet Calib!
ny=ImageData(1).Info.Resolution(1); nx=ImageData(1).Info.Resolution(2);
init_intrinsic_param;
go_calib_optim;
%Compute ReProjection Error
Bouguet=[]; npts=[];
for i=1:n_ima
    eval(sprintf('Bouguet(%d).T=[Rc_%d Tc_%d];',i,i,i));
    eval(sprintf('Bouguet(%d).K=KK;',i));
    ds=ones(1,3)*(ImageData(i).PosImage-eval(sprintf('[y_%d; ones(1,length(y_%d))]',i,i))).^2;
    Bouguet(i).ReProjError.RMS=sqrt(mean(ds));
    [ds,ind]=sort(ds,'descend');
    Bouguet(i).ReProjError.Median=sqrt(ds(round(eval(sprintf('length(y_%d)',i))/2)));
    Bouguet(i).ReProjError.MaxError=sqrt(ds(1));
    Bouguet(i).ReProjError.ReProjPts=eval(sprintf('[y_%d; ones(1,length(y_%d))]',i,i));
    npts=[npts eval(sprintf('length(y_%d)',i))];
end


%% Display ReProjError for both methods:
avgReSIC=[]; avgReBOU=[];
for i=1:length(ImageData)
    if TEXT
        fprintf('REPROJECTION ERRORS \n')
        fprintf('%d --- Bouguet RMS: %f \n',i,Bouguet(i).ReProjError.RMS),
        fprintf('%d --- SIC RMS: %f \n \n',i,ImageData(i).OptimCalib.ReProjError.RMS),
    end
    avgReSIC=[avgReSIC ImageData(i).OptimCalib.ReProjError.RMS];
    avgReBOU=[avgReBOU Bouguet(i).ReProjError.RMS];
end
fprintf('\n \n')
fprintf ('Bouguet RMS mean: %f   std: %f \n',mean(avgReBOU),std(avgReBOU));
fprintf ('SIC RMS mean: %f       std: %f \n',mean(avgReSIC),std(avgReSIC));
fprintf ('Each calibration image have an average of %d detected points.', round(mean(npts)))
fprintf('\n \n')

%% Convert division model params to bouguet
CutDir=[1;0];
PixelStep=1;
if isfield(ImageData(1).Boundary,'Parameters')
    PixelRadius=ImageData(1).Boundary.Parameters.A;
else
    PixelRadius=sqrt((ImageData(1).Info.Resolution(2)-ImageData(1).OptimCalib.center(1))^2 + ...
        (ImageData(1).Info.Resolution(1)-ImageData(1).OptimCalib.center(2))^2);
end
for i=1:length(ImageData)
    %Compute Profile two Parameter
    [Rmm_div_2,Rpixel_div_2]=BuildDivModelProfile(ImageData(i).OptimCalib.K,[ImageData(1).OptimCalib.qsi 0.05],CutDir,PixelRadius,PixelStep);
    %Convert to Bouguet one parameter
    [kconverted,errorconverted]=GetBouguetPar(2,Rmm_div_2);
    ImageData(i).OptimCalib.qsi_bouguet = kconverted;
end

%% Compare calibration parameters
avgSICfocal=[]; avgSICcx=[]; avgSICcy=[]; avgSICqsi1=[]; avgSICqsi2=[]; stackBouguetError=[]; stackSICError=[];
for i=1:length(ImageData)
    if TEXT
        fprintf('CALIBRATION PARAMETERS \n')
        fprintf('%d -- Distortion SIC: [%f %f]       Distortion Bouguet: [%f %f] \n', i, ImageData(i).OptimCalib.qsi_bouguet(1),ImageData(i).OptimCalib.qsi_bouguet(2), kc(1), kc(2));
        fprintf('%d -- Focal SIC: %f                      Focal Bouguet: %f \n', i, ImageData(i).OptimCalib.focal, fc(1));
        fprintf('%d -- Center SIC: (%f, %f)       Center Bouguet: (%f, %f) \n', i, ImageData(i).OptimCalib.center(1), ImageData(i).OptimCalib.center(2), cc(1), cc(2));
        fprintf('\n')
    end
    if VISUALIZE
       figure
       imshow (ImageData(i).ImageRGB),
       hold on
       plot (ImageData(i).PosImage(1,:), ImageData(i).PosImage(2,:),'g*')
       plot (ImageData(i).OptimCalib.ReProjError.ReProjPts(1,:), ImageData(i).OptimCalib.ReProjError.ReProjPts(2,:),'r+')
       plot (Bouguet(i).ReProjError.ReProjPts(1,:), Bouguet(i).ReProjError.ReProjPts(2,:),'cx')
       legend('Corner points (true corners)','Reprojected points using SIC calibration', 'Reprojected points using Bouguet calibration')
    end
    avgSICfocal=[avgSICfocal ImageData(i).OptimCalib.focal];
    avgSICcx=[avgSICcx ImageData(i).OptimCalib.center(1)];
    avgSICcy=[avgSICcy ImageData(i).OptimCalib.center(2)];
    avgSICqsi1=[avgSICqsi1 ImageData(i).OptimCalib.qsi_bouguet(1)];
    avgSICqsi2=[avgSICqsi2 ImageData(i).OptimCalib.qsi_bouguet(2)];
    stackSICError=[stackSICError ImageData(i).OptimCalib.ReProjError.RMS];
    stackBouguetError=[stackBouguetError Bouguet(i).ReProjError.RMS];
end

%% Plot the final result

N=length(ImageData);

figure
subplot(3,2,1)
hold on
plot (1:N,ones(1,N)*cc(1),'bs-','LineWidth',2)
plot (1:N,avgSICcx,'rd-','LineWidth',2)
title('Principal Point X')
legend('Bouguet', 'EasyCamCalib')
subplot(3,2,2)
hold on
plot (1:N,ones(1,N)*cc(2),'bs-','LineWidth',2)
plot (1:N,avgSICcy,'rd-','LineWidth',2)
title('Principal Point Y')
legend('Bouguet', 'EasyCamCalib')
subplot(3,2,3)
hold on
plot (1:N,ones(1,N)*kc(1),'bs-','LineWidth',2)
plot (1:N,avgSICqsi1,'rd-','LineWidth',2)
title('Distortion Parameter 1')
legend('Bouguet', 'EasyCamCalib')
subplot(3,2,4)
hold on
plot (1:N,ones(1,N)*kc(2),'bs-','LineWidth',2)
plot (1:N,avgSICqsi2,'rd-','LineWidth',2)
title('Distortion Parameter 2')
legend('Bouguet', 'EasyCamCalib')
subplot(3,2,[5 6])
hold on
plot (1:N,ones(1,N)*fc(1),'bs-','LineWidth',2)
plot (1:N,avgSICfocal,'rd-','LineWidth',2)
title('Focal Distance')
legend('Bouguet', 'EasyCamCalib')


figure
hold on
plot (1:N,stackBouguetError,'bs-','LineWidth',2)
plot (1:N,stackSICError,'rd-','LineWidth',2)
hold off
title('Reprojection Error Bouguet vs. EasyCamCalib')
legend('Bouguet RMS ReProjection Error', 'EasyCamCalib RMS ReProjection Error')
