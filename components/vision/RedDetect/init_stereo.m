function init_stereo(maxdisp)
% Initialize stereo
    context_filename = sprintf('context%s.txt',getenv('ROBOT_ID'));
    triclopsAPI('loadContext', context_filename);
    triclopsAPI('setResolution', 192, 256);% 384,512
    triclopsAPI('setDisparity', 0, maxdisp);%40
    triclopsAPI('setSubpixelInterpolation', 0);%0
    triclopsAPI('setTextureValidation', 0);%0
    triclopsAPI('setTextureValidationThreshold', 2.0);%2
    triclopsAPI('setUniquenessValidation', 0);%0
    triclopsAPI('setUniquenessValidationThreshold', 3.0);%3
    triclopsAPI('setSurfaceValidation', 0);%1
    triclopsAPI('setSurfaceValidationDifference', 1.0);
    triclopsAPI('setSurfaceValidationSize', 200);%100
    triclopsAPI('setStereoMask', 15);%7

end