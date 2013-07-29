function [] = Paths(p)


%% PATH VARIABLES DEFINITION
%Global paths
PROJECTPATH = p;
fprintf('Project path is: %s\n',PROJECTPATH)


%% PROJECT ADDPATHS
pathname1=strcat(PROJECTPATH,'/ImageDataLoader/BinLoader');
pathname2=strcat(PROJECTPATH,'/BoundaryDetector/BinBoundary');
pathname3=strcat(PROJECTPATH,'/AutoCornerDetector/BinAutoCorner');
pathname4=strcat(PROJECTPATH,'/LinearCalibration/BinLinearCalib');
pathname5=strcat(PROJECTPATH,'/OriginSelector/BinManualSelections');
pathname6=strcat(PROJECTPATH,'/CalibrationRefinement/BinRefine');
pathname7=strcat(PROJECTPATH,'/HandEyeCalibration/BinHandEye');
pathname8=strcat(PROJECTPATH,'/HandEyeRefinement/BinHandEyeRefinement');
pathname9=strcat(PROJECTPATH,'/Interfaces/BinInterfaces');
pathname10=strcat(PROJECTPATH,'/Interfaces/BinInterfaces/gui_data');
pathname11=strcat(PROJECTPATH,'/Misc');


addpath (pathname1);
addpath (pathname2);
addpath (pathname3);
addpath (pathname4);
addpath (pathname5);
addpath (pathname6);
addpath (pathname7);
addpath (pathname8);
addpath (pathname9);
addpath (pathname10);
addpath (pathname11);

