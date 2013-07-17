clc
close all
clear ImageData
addpath('./Binboundary')

load ../temp/CalibImagesScene.mat

%% Configurations
VISUALIZE = 1;
ITERNUMBER = 2; %how many times we want to repeat the process (higher value=better accuracy)
Threshold=0.5;
RadiusRange=41;
AngleStep=1*pi/180;
RansacThreshold=0.05;

%% Hack (first conic initialization)
if ImageData(1).Info.Resolution(1)*ImageData(1).Info.Resolution(2)>810000
    C = [630 424];
    MajorAxis=923/2;
    MinorAxis=901/2;
else
    C = [380 287];
    MajorAxis=268;
    MinorAxis=249;
end
phi=-1.45;

%% Find the Conic
for i=1:1:ITERNUMBER

    %% Affine homography that maps the conic into a circle with radius MinorAxis
    H=diag([MinorAxis/MajorAxis 1 1])*[cos(phi) sin(phi) 0;-sin(phi) cos(phi) 0; 0 0 1]*[1 0 -C(1);0 1 -C(2); 0 0 1];

    %% Generate interpolated image
    [imRadial,theta,rho]=CD_GenerateRadialImg(ImageData(1).ImageGray,H,MinorAxis,RadiusRange,AngleStep);
    Points=CD_DetectContourInRadialImg(imRadial,theta,rho,H,VISUALIZE);
    Pointstotal = Points;

    %% Restimate the conic
    [omega, inliers] = CD_conic_ransac (Points(1:2,:), 5,RansacThreshold);
    Points=Pointstotal(:,inliers);

    %% Compute Conic Parameters
    Omega=[omega(1) omega(2) omega(4);omega(2) omega(3) omega(5);omega(4) omega(5) omega(6)];
    [C,Vertex,MajorAxis,MinorAxis,phi]=CD_ComputeConicParameters(Omega);

    %%Visualize
    if VISUALIZE
        figure;
        imshow(uint8(imRadial));
        title(sprintf('Radial Image %d',i));
    end;
end

%% Generate interpolated image for lent mark detection
[imRadial2,theta,rho,X,Y]=CD_GenerateRadialImg(ImageData(1).ImageGray,H,MinorAxis,RadiusRange,AngleStep);

%% Find the lent mark position 
lentangleplot = CD_FindLentMark(imRadial2,8);
lensangle = deg2rad(lentangleplot)-pi/2;

%% Fill the ImageData Structure
ImageData(1).Boundary.Points = Points;
ImageData(1).Boundary.Omega = Omega;
ImageData(1).Boundary.LensAngle = lensangle;
ImageData(1).Boundary.Parameters.A = MajorAxis;
ImageData(1).Boundary.Parameters.B = MinorAxis;
ImageData(1).Boundary.Parameters.Center = C;
ImageData(1).Boundary.Parameters.Phi = phi;
ImageData(1).Boundary.Parameters.Vertex = Vertex;


if VISUALIZE
    figure;
    [m,n]=size(imRadial2);
    imshow(uint8(imRadial2));
    hold on;
    plot([n/2 n/2],[1 m],'m-');
    plot(n/2+8,lentangleplot,'g*');
    title('Final Radial Image');
    figure
    [points,img]=CD_plot_conic_curve(Omega, ImageData(1).ImageRGB, [255 0 0]);
    imshow(img);
    title('Final Conic')
end;

save CalibData_boundary.mat ImageData
