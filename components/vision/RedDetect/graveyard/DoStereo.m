function [xrgb,xdisparity] = DoStereo(yLeft,yRight,maxdisp,mode)
% if mode set to 1, don't calculate disparity map

       triclopsAPI('setInputLeft', yLeft);
       triclopsAPI('setInputRight', yRight);
 
       yrgb = triclopsAPI('imageRGBl');
       xrgb = permute(yrgb,[2 1 3]); % rectified right image
 
        if mode == 1
            xdisparity = [];
        else
            ydisparity = triclopsAPI('imageDisparity');
            xdisparity = permute(ydisparity,[2 1]);
            xdisparity(xdisparity > 250) = 0;
        end
       
%       xdisparity(xdisparity > maxdisp/2) = maxdisp/2;
%      figure(2);
%        image(xdisparity);
%        axis image;
%  
%    drawnow;
 
 end
