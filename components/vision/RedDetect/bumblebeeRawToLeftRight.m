function [xLeft, xRight] = bumblebeeRawToLeftRight(x)

global BUMBLEBEE; 
xRaw = reshape(memcpy(x,'uint8'),[2048 768]);

xLeft = zeros(512,384,3,'uint8');
xRight = zeros(512,384,3,'uint8');

if strcmp(BUMBLEBEE.bayer,'bggr') 
	xRight(:,:,3) = xRaw(1:4:end,1:2:end);
	xRight(:,:,2) = xRaw(3:4:end,1:2:end);
	xRight(:,:,1) = xRaw(3:4:end,2:2:end);

	xLeft(:,:,3) = xRaw(2:4:end,1:2:end);
	xLeft(:,:,2) = xRaw(4:4:end,1:2:end);
	xLeft(:,:,1) = xRaw(4:4:end,2:2:end);
	return
end
if strcmp(BUMBLEBEE.bayer,'grbg')
	xRight(:,:,2) = xRaw(1:4:end,1:2:end);
	xRight(:,:,3) = xRaw(1:4:end,2:2:end);
	xRight(:,:,1) = xRaw(3:4:end,1:2:end);

	xLeft(:,:,2) = xRaw(2:4:end,1:2:end);
	xLeft(:,:,3) = xRaw(2:4:end,2:2:end);
	xLeft(:,:,1) = xRaw(4:4:end,1:2:end);
	return
end
	'Unknown Bayer Method'
	assert(false)
%xRight = permute(xRight,[2 1 3]); % transpose image
%xLeft = permute(xLeft,[2 1 3]);
