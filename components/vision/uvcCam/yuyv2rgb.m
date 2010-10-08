function [rgb] =yuyv2rgb(yuyv);

siz = size(yuyv);
newsiz = siz * diag([2,1]); 
yuyv_u8 = reshape(typecast(yuyv(:), 'uint8'), [4 siz]);
y1 = permute(yuyv_u8(1,:,:),[2,3,1]);; 
y2 = permute(yuyv_u8(3,:,:),[2,3,1]);
cb = imresize(permute(yuyv_u8(2,:,:),[2,3,1]),newsiz,'nearest');
cr = imresize(permute(yuyv_u8(4,:,:),[2,3,1]),newsiz,'nearest');
y = zeros(newsiz); 
y(1:2:end,:) = y1;
y(2:2:end,:) = y2;
%ycbcr = yuyv_u8([1 2 4], :, 1:2:end);
%ycbcr = permute(ycbcr, [3 2 1]);
ycbcr = cat(3,y',cb',cr'); 
rgb = ycbcr2rgb(ycbcr);
