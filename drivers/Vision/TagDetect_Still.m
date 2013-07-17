clear all
close all

im=imread('test3_und.jpg');
if(size(im,3)>1)
    im=rgb2gray(im);
end

corners=corner(im,'Harris', ...
                'SensitivityFactor',0.04, ...
                'QualityLevel',0.15, ...
                'FilterCoefficients', ...
                fspecial('gaussian',[5 1],1.5))

figure(1)
cla
imshow(im)
hold on
plot(corners(:,1),corners(:,2),'rx')