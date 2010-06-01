function Cr = Get_Cr_only(Image)
% only do Cr channel in YCbCr colorspace

   DestT = [65.481,128.553,24.966,16;-37.797,-74.203,112.0,128;112.0,-93.786,-18.214,128];
    Image = double(Image)/255;
   Cr = DestT(3)*Image(:,:,1) + DestT(6)*Image(:,:,2) + DestT(9)*Image(:,:,3) + DestT(12);

end