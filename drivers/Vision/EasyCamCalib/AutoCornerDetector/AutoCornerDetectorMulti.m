clc 
close all
clear all
addpath('./BinAutoCorner/');

load ../../../temp/CalibBoundary.mat

%% Configurations
VISUALIZE = 0;

%% Find the corners for each image
j=1;
for i=1:length(ImageData)
    [PointsFinal, CoordinatesFinal, NumberOfBlackSquares] = DetectCorners(ImageData(i).ImageGray,ImageData(i).Boundary,...
        VISUALIZE, ImageData(i).Info.IsArthroscopic,ImageData(i).Info.GridSize);
    ImageData(j).PosImageAuto = [transpose(PointsFinal); ones(1,length(PointsFinal))];
    ImageData(j).PosPlaneAuto = [transpose(CoordinatesFinal); ones(1,length(PointsFinal))];
    j=j+1;
end

save ../../../temp/CalibAutoCorner.mat ImageData