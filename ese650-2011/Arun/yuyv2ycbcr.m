function ycbcr=yuyv2ycbcr(yuyv);
siz = size(yuyv);
yuyv_u8 = reshape(typecast(yuyv(:), 'uint8'), [4 siz]);
ycbcr = yuyv_u8([1 2 4], :, 1:2:end);
ycbcr = permute(ycbcr, [3 2 1]);
