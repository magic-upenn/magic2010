function nimg = null_image(width,height);
	nimg = fliplr(eye(max(width,height))); 
	nimg = double(imresize(nimg,[height,width]) > 0);
	nimg = double(conv2(nimg,ones(5),'same') > 0) * 255;
	nimg = cat(3,uint8(nimg),zeros(height,width),zeros(height,width)); 
