clc
% close all
clear ImageData
addpath('./Bin');
addpath('./BinBoundary')

load ../temp/CalibDataAir.mat

%% Configurations
VISUALIZE = 0;
ITERNUMBER = 5; %how many times we want to repeat the conic detection process
AngleStep=1*pi/180;
RansacThreshold=0.05;


%% Compute boundary for each image
for j=1:length(ImageData)
    % Hack (first conic initialization and gaussian window size)
%     if ImageData(1).Info.Resolution(1)*ImageData(1).Info.Resolution(2)>810000
%         C = [630 424];
%         MajorAxis=923/2;
%         MinorAxis=901/2;
%         N = 19*2;
%         RadiusRange=41;
%     else
%         C = [380 287];
%         MajorAxis=268;
%         MinorAxis=249;
%         N = 19;
%         RadiusRange=41;
%     end
    m=ImageData(j).Info.Resolution(1);
    n=ImageData(j).Info.Resolution(2);
    s=min([m n]);
    r=max([m n]);
    C = [n/2 m/2];
    MajorAxis=s/2.1;
    MinorAxis=s/2.1;
    N = 9;
    RadiusRange=round(n/15);
    if(~mod(RadiusRange,2))
       RadiusRange=RadiusRange+1; 
    end
    fprintf('Using radius range equal to %d \n',RadiusRange)
    phi=0;
    if VISUALIZE
        figure
        imshow(ImageData(j).ImageRGB)
        h = ellipse(MajorAxis,MinorAxis,phi,C(1),C(2),'r');
        title('First Conic estimation used')
    end;
    % Find the Conic
    for i=1:1:ITERNUMBER
        % Affine homography that maps the conic into a circle with radius MinorAxis
        H=[cos(-phi) sin(-phi) 0;-sin(-phi) cos(-phi) 0; 0 0 1]*diag([MinorAxis/MajorAxis 1 1])*[cos(phi) sin(phi) 0;-sin(phi) cos(phi) 0; 0 0 1]*[1 0 -C(1);0 1 -C(2); 0 0 1];

        % Generate interpolated image
        [imRadial,theta,rho]=CD_GenerateRadialImg(ImageData(j).ImageGray,H,MinorAxis,RadiusRange,AngleStep);
        Points=CD_DetectContourInRadialImg(imRadial,theta,rho,H,N,VISUALIZE);
        Pointstotal = Points;

        % Restimate the conic
        [omega, inliers] = CD_conic_ransac (Points(1:2,:), 5,RansacThreshold);
        Points=Pointstotal(:,inliers);
        
        % Compute Conic Parameters
        Omega=[omega(1) omega(2) omega(4);omega(2) omega(3) omega(5);omega(4) omega(5) omega(6)];
        [C,Vertex,MajorAxis,MinorAxis,phi]=CD_ComputeConicParameters(Omega);

        %Visualize
        if VISUALIZE
%             figure;
%             imshow(uint8(imRadial));
%             title(sprintf('Radial Image %d',i));
            figure
            [points,img]=CD_plot_conic_curve(Omega, ImageData(j).ImageRGB, [255 0 0]);
            imshow(img);
            title('Estimated Conic')
        end;
    end

    % Generate interpolated image for lent mark detection
    [imRadial2,theta,rho,X,Y]=CD_GenerateRadialImg(ImageData(j).ImageGray,H,MinorAxis,RadiusRange,AngleStep);

    % Find the lent mark position
    lensangleplot = CD_FindLentMark(imRadial2,8);
    lensangle = (360-lensangleplot)+180;
    if(lensangle<0 || lensangle>360)
        lensangle = -1*sign(lensangle)*360 + lensangle;
    end
    lensangleimage=inv(H)*[MinorAxis*cos((360-lensangle)*pi/180); MinorAxis*sin((360-lensangle)*pi/180);1];
    if(lensangleimage(1)>n), lensangleimage(1)=n; end 
    if(lensangleimage(1)<1), lensangleimage(1)=1; end 
    if(lensangleimage(2)>m), lensangleimage(2)=m; end 
    if(lensangleimage(2)<1), lensangleimage(2)=1; end 

    % Fill the ImageData Structure
    ImageData(j).Boundary.Points = Points;
    ImageData(j).Boundary.Omega = Omega;
    ImageData(j).Boundary.LensAngle = lensangle;
    ImageData(j).Boundary.LensAngleImage = lensangleimage;
    ImageData(j).Boundary.Parameters.A = MajorAxis;
    ImageData(j).Boundary.Parameters.B = MinorAxis;
    ImageData(j).Boundary.Parameters.Center = C;
    ImageData(j).Boundary.Parameters.Phi = phi;
    ImageData(j).Boundary.Parameters.Vertex = Vertex;

    
    figure;
    [m,n]=size(imRadial2);
    imshow(uint8(imRadial2));
    hold on;
    plot([n/2 n/2],[1 m],'m-');
    plot(n/2+8,lensangleplot,'g*');
    title('Final Radial Image');
    figure;
    [points,img]=CD_plot_conic_curve(Omega, ImageData(j).ImageRGB, [255 0 0]);
    imshow(img);
    hold on
    plot(lensangleimage(1),lensangleimage(2),'gs');
    title('Final Conic')

end

save ../temp/CalibBoundary.mat ImageData

