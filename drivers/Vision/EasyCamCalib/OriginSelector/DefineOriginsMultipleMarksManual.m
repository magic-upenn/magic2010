clc
close all
clear all

addpath('./BinManualSelections')

load ./CalibLinearCalibrationManual.mat
[dummy,N]=size(ImageData);

%% Configuration
RELATIVEPOSITIONS = [0 -17;
    0 -17;
    0 0;
    15 0;
    15 -17;
    15 -17;
    0 -17;
    0 0;
    15 -17;
    0 0;
    15 -17;
    0 -17;
    0 0;
    0 -17]; %Relative position of the marks (in squres)

%% Change the origins
cancel = 0;
for i=1:1:N
    [T_new PosPlaneNew cancel] = DefineOriginsMultipleMarks(ImageData(i), RELATIVEPOSITIONS(i,:));
    ImageData(i).FinalCalib.T = T_new;
    ImageData(i).PosPlane = PosPlaneNew;
    if cancel
       break
    end
end

save ./CalibLinearCalibrationManualOrigins.mat ImageData