close all;
%script to test out Harris

I = imread('test3_und.jpg');
if(size(I,3) > 1)
    I = rgb2gray(I);
end
C = corner(I, 'Harris', 'SensitivityFactor', 0.04, 'QualityLevel', 0.15, 'FilterCoefficients', fspecial('gaussian',[5 1],1.5));



%% process the list of conrners

%make binary image with only corners
BW = zeros(size(I,2), size(I,1));
for i=1:length(C)
    BW(C(i,2),C(i,1)) = 1;
end

%Hough Transform
[H T R] = hough(BW, 'RhoResolution', 3);
numpeaks = 100;
h_thres = 0.1*max(H(:));
P = houghpeaks(H, numpeaks, 'Threshold', h_thres); %returns (rho, theta)
L_orig = houghlines(BW, T, R, P, 'MinLength', 20);

%% look for lines with at least one other parallel buddy
% i think this block is only finding segments of the same line if thrs=0 

theta_thres = 2; %plus or minus

thetas = P(:,2);
[sortTheta, indeces] = sort(thetas);

paraP = [];
i=1;
while i < length(sortTheta)
    j=1;
    theta_cur = sortTheta(i);
    while (sortTheta(i+j) >= theta_cur-theta_thres) && (sortTheta(i+j) <= theta_cur+theta_thres) 
        if i+j < length(sortTheta)
            j = j+1;
        else
            break;
        end
    end
    
    if(j>1)
        if ~isempty(paraP)
            paraP(end+1:end+1+j-1,:) = P(indeces(i:i+j-1),:);
        else
            paraP = P(indeces(i:i+j-1),:);
        end
    end
    i = i+j;
end

L = houghlines(BW, T, R, paraP, 'MinLength', 20, 'FillGap', 20);



%% find groups of multiple parallel lines
theta_thres = 2; %plus or minus degrees to group lines
group_thetas = [];
for c=1:length(L)
    L(c).group = 0;
    L(c).avg = 0; 
end
group=1;
i=1;
while i<=length(L)
    cur_t = L(i).theta;
    sum = cur_t;
    j=1;
    while i+j <= length(L)
        if (cur_t-theta_thres <= L(i+j).theta) && ( L(i+j).theta <= cur_t + theta_thres)
            sum = sum + L(i+j).theta;
            j = j+1;
        else
            break;
        end
    end
    if(j >= 3)
        %fprintf('%d:%d+%d\n', i, i, j);
        gAvg = sum/j;
        for d=i:i+j-1
            L(d).group=group;
            group_thetas(group) = gAvg;
        end
        group = group+1;
    end
    i=i+j;
end

% %% look at slope relation between lines to determine checkboard pattern
% perp=0;
% diag=0;
% group_thres=3;
% 
% for i=1:length(group_thetas)
%     cur_theta = group_thetas(i);
%     for j=i:length(group_thetas)
%         if group_thetas(j)  == 
% 





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%   Display Figures and Plots
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%display corner detection
figure;
imshow(I)
hold on
for(i=1:length(C))
    plot(C(:,1), C(:,2), '*r');
end
hold off

% Display the binary image.
figure;
subplot(2,1,1);
imshow(BW);
title('Binary Image');

% Display the Hough matrix.
subplot(2,1,2);
imshow(imadjust(mat2gray(H)),'XData',T,'YData',R,...
      'InitialMagnification','fit');
title('Hough Transform of Image');
xlabel('\theta'), ylabel('\rho');
axis on;
axis normal
hold on;
colormap(hot);


% %show hough peaks
% imshow(H,[],'XData',T,'YData',R,'InitialMagnification','fit');
% xlabel('\theta'), ylabel('\rho');
% axis on, axis normal, hold on;
% plot(T(P(:,2)),R(P(:,1)),'s','color','white');

%plot lines returns by peaks
figure;
imshow(I);
hold on;
for i = 1:size(P,1)
    r = P(i,2);
    th = P(i,1);
    m = (cos(th)/sin(th));
    b = r/sin(th);
    
    %plot the lines
    x=1:size(I,2);
    plot(m*x+b, x);
    
end
    

%plot hough line segments
figure;
imshow(I);
hold on
max_len = 0;
for k = 1:length(L_orig)
   xy = [L_orig(k).point1; L_orig(k).point2];
   plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green');

   % Plot beginnings and ends of lines
   plot(xy(1,1),xy(1,2),'x','LineWidth',2,'Color','yellow');
   plot(xy(2,1),xy(2,2),'x','LineWidth',2,'Color','red');
end

figure;
imshow(I);
hold on
max_len = 0;
for k = 1:length(L)
    if L(k).group ~= 0
       xy = [L(k).point1; L(k).point2];
       plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green');

       % Plot beginnings and ends of lines
       plot(xy(1,1),xy(1,2),'x','LineWidth',2,'Color','yellow');
       plot(xy(2,1),xy(2,2),'x','LineWidth',2,'Color','red');
    end
end
