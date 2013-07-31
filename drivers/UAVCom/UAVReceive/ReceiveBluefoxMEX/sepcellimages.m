%Separate images out of a cell array
%useful for the result of receiveBluefox
images = load('images.mat');

numimg = size(images.dat,2);

for k=1:1:numimg
	filename = sprintf('%s-%02d.jpg','image',k);
	imwrite(images.dat{k},filename,'JPG');
end
