clc
close all
clear all

addpath('./BinAutoCorner/');

load CalibData_boundary.mat

%% Configurations
VISUALIZE = 1;

%% Find the corners for each image
[PointsFinal, CoordinatesFinal, NumberOfBlackSquares] = DetectCorners(ImageData(1).ImageGray,ImageData(1).Boundary,...
    VISUALIZE, ImageData(1).Info.IsArthroscopic,ImageData(1).Info.GridSize);
ImageData(1).PosImageAuto = [transpose(PointsFinal); ones(1,length(PointsFinal))];
ImageData(1).PosPlaneAuto = [transpose(CoordinatesFinal); ones(1,length(PointsFinal))];

save CalibData_autocorner.mat