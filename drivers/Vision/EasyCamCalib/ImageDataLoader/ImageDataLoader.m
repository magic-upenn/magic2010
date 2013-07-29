clc 
clear all
close all
addpath('./BinLoader')


%% Configurations
GRIDSIZE = 3;               %Size of the calibration grid in mm
ISARTHROSCOPIC = 1;         %If the image is arthrocopic (==1) or not (==0)
OBJECTNUMBER = 2;           %Number of objects in the OptoTracker.txt file
WHEREISARTHROSCOPE = 1;     %Which one is the Arthroscope? (it doesnt matter if the transforms in the file are written in quaternions or [R t])


%% Give the paths of the images to calibrate (we expect that the OptoTracker.txt file is in the same directory)
imagepath = [];
j = 1;
for h=1:17
    imagepath(j).p = sprintf('/home/rmelo/m/CommonArchive/Archive/Datasets/LensRotation_2010_07_13/SceneImages/Arthro%.5d.tiff',h-1);
    j = j+1;
end


%% Fill the ImageData structure
for i=1:1:length(imagepath)
    ImageData(i).ImageRGB = imread(imagepath(i).p);
    ImageData(i).ImageGray = rgb2gray(ImageData(i).ImageRGB);
    ImageData(i).Info.GridSize = GRIDSIZE;
    ImageData(i).Info.IsArthroscopic = ISARTHROSCOPIC;
    ImageData(i).Info.Resolution = size(ImageData(i).ImageRGB);
    [OptoR OptoT] = LoadOptoInfoSingle(imagepath(i).p, OBJECTNUMBER, WHEREISARTHROSCOPE);
    ImageData(i).Hand2Opto = [OptoR OptoT';0 0 0 1];
    ImageData(i).Boundary = 1;
end

save ../temp/CalibImagesScene.mat ImageData