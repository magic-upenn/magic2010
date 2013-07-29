% Test the Hough Transformation for edge detection
% Patrick Husson
% phusson1@umbc.edu
% 6/26/13

%G = fspecial('gaussian',[3 3], 0.8);
%filterI = imfilter(I,G,'same');
%gI = rgb2gray(filterI);
%[bwc threshold] = edge(gI, 'canny');

%I = imread('image.png');
hold on;
[cim r c] = harris(I, 1, 50, 2, 1);
crn = horzcat(c, r);
newI = markpoints(I, crn);
[H theta rho] = hough(newI, 'RhoResolution', 1);
%plothough(newI, H, theta, rho);
%[H theta rho] = hough(bwc);

%figure, imshow(imadjust(mat2gray(H)),[],'XData',theta,'YData',rho,...
%        'InitialMagnification','fit');
%xlabel('\theta (degrees)'), ylabel('\rho');
%axis on, axis normal, hold on;
%colormap(hot);

%If not enough lines, alter the threshold to get more peaks
peaks = houghpeaks(H, 50, 'Threshold', 0.5*max(H(:)), 'NHoodSize', [3 51]);
lines = houghlines(I, theta, rho, peaks, 'MinLength', 5);

figure;
imshow(I);
hold on;
% From the houghlines() help
max_len = 0;
   for k = 1:length(lines)
	 xy = [lines(k).point1; lines(k).point2];
	 plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green');

	 % plot beginnings and ends of lines
	 plot(xy(1,1),xy(1,2),'o','LineWidth',2,'Color','yellow');
	 plot(xy(2,1),xy(2,2),'o','LineWidth',2,'Color','red');

	 % determine the endpoints of the longest line segment 
	 len = norm(lines(k).point1 - lines(k).point2);
	 if ( len > max_len)
	   max_len = len;
	   xy_long = xy;
	 end
   end

   % highlight the longest line segment
   plot(xy_long(:,1),xy_long(:,2),'LineWidth',2,'Color','cyan');

%hold off
