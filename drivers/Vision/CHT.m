% this script performs a cascaded hough transform on an image to find the
% vanishing points in the image

%% load image and pre process 

I = imread('test3_und.jpg');
if(size(I,3) > 1)
    I = rgb2gray(I);
end

%get all corners in original image, these will make up the binary image
C = corner(I, 'Harris', 'SensitivityFactor', 0.04, 'QualityLevel', 0.15, 'FilterCoefficients', fspecial('gaussian',[5 1],1.5));

%make binary image with only corners
BW = zeros(size(I,2), size(I,1));
for i=1:length(C)
    BW(C(i,2),C(i,1)) = 1;
end

%% Hough #1: this will return points in line-parameter space representing lines int he image space.
[H T R] = hough(BW, 'RhoResolution', 3);
numpeaks = 100;
h_thres = 0.1*max(H(:));
P = houghpeaks(H, numpeaks, 'Threshold', h_thres); %returns (rho, theta)

%convert from rho theta parameterization to (m,b) parameterization (all
%still in Hough Space)
P_cart = zeros(size(P));
for i=1:size(P,1);
    th = P(i,2);
    rho = P(i,1);
    P_cart(i,1) = -(cos(th)/sin(th));
    P_cart(i,2) = rho/sin(th);
end



%divide these new points (in Hough Space) into three subspace to avoid the
%problem of having an unbounded parameter space
for i=1:3
    subspaces(i).m=[0];
    subspaces(i).b =[0];
    subspaces(i).BW = zeros(size(BW));
end

%make a new binary images from the points in hough space, in each of the
%three subspaces.
for s=1:length(subspaces)
    subspaces(i).BW = zeros(size(BW));
    for i=length(subspaces(i))
    end
end
        


%% Hough #2: this will return points in the image space representing lines found in the prarmeter space. Must be run on each of the subspace.

for s=1:length(subspaces)
    [H T R] = hough(BW2, 'RhoResolution', 3);
    numpeaks = 100;
    h_thres = 0.1*max(H(:));
    P = houghpeaks(H, numpeaks, 'Threshold', h_thres); %returns (rho, theta)
end