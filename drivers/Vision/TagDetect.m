clear all
close all

im = imread('test3_und.jpg');
if (size(im,3) > 1)
    im = rgb2gray(im);
end

corners = corner(im, 'Harris','SensitivityFactor',0.15,'QualityLevel',0.05,'FilterCoefficients',fspecial('gaussian',[5 1],1.5))

fig=figure(1);
imagedisplay=imshow(im);

hold on
cornerplot=plot(corners(:,1),corners(:,2),'rx');

%set(imagedisplay,'Parent',fig);
%hold on
%set(cornerplot,'Parent',fig);