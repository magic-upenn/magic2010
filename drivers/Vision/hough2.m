%% load a sample image; convert to grayscale; convert to binary

%create 'x' image (works well)
a = eye(255);
b = flipud(eye(255));
x = a + b;
x(128,128) = 1;

%image = rgb2gray(imread('up.png')) < 255;
%image = rgb2gray(imread('hexagon.png')) < 255;
%image = rgb2gray(imread('traingle.png')) < 255;
%%% these work
%image = x;
%image = a;
%image = b;

I = imread('test3_und.jpg');
if(size(I,3) > 1)
    I = rgb2gray(I);
end
C = corner(I, 'Harris', 'SensitivityFactor', 0.04, 'QualityLevel', 0.15, 'FilterCoefficients', fspecial('gaussian',[5 1],1.5));
%make binary image with only corners
BW = zeros(size(I,2), size(I,1));
for i=1:length(C)
    BW(C(i,2),C(i,1)) = 1;
end
image=BW;

%% set up variables for hough transform
theta_sample_frequency = 0.01;                                             
[x, y] = size(image);
rho_limit = norm([x y]);                                                
rho = (-rho_limit:1:rho_limit);
theta = (0:theta_sample_frequency:pi);
num_thetas = numel(theta);
num_rhos = numel(rho);
hough_space = zeros(num_rhos, num_thetas);

%% perform hough transform
for xi = 1:x
    for yj = 1:y
        if image(xi, yj) == 1 
            for theta_index = 1:num_thetas
                th = theta(theta_index);
                r  = xi * cos(th) + yj * sin(th);
                rho_index = round(r + num_rhos/2);                      
                hough_space(rho_index, theta_index) = ...
                     hough_space(rho_index, theta_index) + 1;
            end
        end
    end
end


%% show hough transform
figure %subplot(1,2,1);
imagesc(theta, rho, hough_space);
title('Hough Transform');
xlabel('Theta (radians)');
ylabel('Rho (pixels)');
colormap('gray');

%% detect peaks in hough transform
r = [];
c = [];
[max_in_col, row_number] = max(hough_space);
[rows, cols] = size(image);
difference = 25;
thresh = max(max(hough_space)) - difference;
for i = 1:size(max_in_col, 2)
   if max_in_col(i) > thresh
       c(end + 1) = i;
       r(end + 1) = row_number(i);
   end
end

%% plot all the detected peaks on hough transform image
hold on;
plot(theta(c), rho(r),'rx');
hold off;


%% plot the detected line superimposed on the original image
figure %subplot(1,2,2)
imagesc(image);
colormap(gray);
hold on;

for i = 1:size(c,2)
    th = theta(c(i));
    rh = rho(r(i));
    m = -(cos(th)/sin(th));
    b = rh/sin(th);
    x = 1:cols;
    plot(m*x+b, x);
    hold on;
end