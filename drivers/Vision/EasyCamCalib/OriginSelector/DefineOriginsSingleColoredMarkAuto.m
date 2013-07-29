clc
close all
clear all

addpath('./BinManualSelections')

load CalibLinearCalibrationManual.mat
[dummy,N]=size(ImageData);

%% Configurations
VISUALIZE = 1;


%% Change the origin and direction based on the colored squares
for i=1:N
    [Pimg_o Pimg_d Pplane_o Pplane_d] = ChangeOriginAuto(ImageData(i),VISUALIZE);    
    if ~isempty(Pimg_o) && ~isempty(Pimg_d) && ~isempty(Pplane_o) && ~isempty(Pplane_d)
        %compute the transform to the new grid frame
        I =  Pplane_d - Pplane_o ;
        I = I/norm(I);
        J = cross([0 0 1],I);
        T=[I(1:2) J(1:2)' Pplane_o(1:2);0 0 1] ;
        T = inv(T) ;
        origin = T * Pplane_o ;
        OX = T * Pplane_d ;

        T_old = ImageData(i).FinalCalib.T;
        T_old2new = [I J' [0;0;1] [Pplane_o(1:2);0] ; 0 0 0 1];
        T_new = T_old * T_old2new;

        ImageData(i).PosPlane(:,:) = T * ImageData(i).PosPlane(:,:);
        ImageData(i).FinalCalib.T = T_new;
    else
        display('WARNING!!! Calibration Grid marks not found...')
    end
end

save CalibLinearCalibrationManualOrigins.mat ImageData