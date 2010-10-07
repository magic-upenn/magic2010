function [Left,Right,Br,Ex,Sh,G] = bumblebeeSetParamAndCapture(Br_Ex_Sh_G)
% Function that sets the camera parameters, displays 7 frames (to allow
% for parameter stabilize) and returns
% the last (left and right) image and current parameters.

% Input
% Br_Ex_Sh_G: vector which contains the following:
%       Br_in: brightness input, [0..255]. If 0, then set auto
%       Ex_in: exposure input, [0..1023]. If 0, then set auto
%       Sh_in: shutter input, [0..800]. If 0, then set auto
%       G_in: gain input, [0..1023]. If 0, then set auto
%
% Output
% Left: left image raw
% Right: right image raw
% Br,Ex,Sh,G: current values of brightness, exposure, shutter, gain
%
% Jason Liu, [jasonliu@seas.upenn.edu] March 2010

Br_in = Br_Ex_Sh_G(1);
Ex_in = Br_Ex_Sh_G(2);
Sh_in = Br_Ex_Sh_G(3);
G_in = Br_Ex_Sh_G(4);

libdc1394('featureSetModeManual','Brightness'); 
libdc1394('featureSetValue','Brightness', Br_in);
libdc1394('featureSetModeManual','Exposure'); 
libdc1394('featureSetValue','Exposure', Ex_in);
libdc1394('featureSetModeManual','Shutter'); 
libdc1394('featureSetValue','Shutter', Sh_in);
libdc1394('featureSetModeManual','Gain'); 
libdc1394('featureSetValue','Gain', G_in);

% if parameters == 0, set to auto
if Br_in == 0
    libdc1394('featureSetModeAuto','Brightness'); % auto 1-1023
end
if Ex_in == 0
    libdc1394('featureSetModeAuto','Exposure'); % auto 1-1023
end
if Sh_in == 0
    libdc1394('featureSetModeAuto','Shutter'); % auto 2-800
end
if G_in == 0
    libdc1394('featureSetModeAuto','Gain'); % auto 264-1023
end

if Br_Ex_Sh_G == [0,0,0,0]
    numframes = 15; % if fully auto, then let images settle longer
else
    numframes = 3;
end

for i = 1:numframes
    [Br,Ex,Sh,G] = bumblebeeGetFeatures;
    fprintf(1,'Br %d, Ex %d, Sh %d, G %d\n',Br,Ex,Sh,G);

    [yRaw, info] = libdc1394('capture');
    [Left, Right] = bumblebeeRawToLeftRight(yRaw);
    Right = permute(Right,[2 1 3]); % transpose image
    Left = permute(Left,[2 1 3]);
    figure(1);
    subplot(1,2,1); imshow(Left);
    subplot(1,2,2); imshow(Right);
    drawnow;
end


