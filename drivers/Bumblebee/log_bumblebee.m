addpath ~/svn/drivers/CircularBuffer/

bumblebeeInit;

bumblebeeStartTransmission;

nFrames = 15*120;
L = zeros(512,384,3,nFrames,'uint8');
R = zeros(512,384,3,nFrames,'uint8');

ts = zeros(nFrames,1);

tic
for i = 1:nFrames,
  tic
  [yRaw,info] = bumblebeeCapture;
  [yLeft, yRight] = bumblebeeRawToLeftRight(yRaw);
  
  L(:,:,:,i) = yLeft;
  R(:,:,:,i) = yRight;
  
  t = GetUnixTime();
  ts(i) = t;
  
  %subplot(1,2,1)
  %image(permute(yLeft,[2 1 3]));
  %subplot(1,2,2)
  %image(permute(yRight,[2 1 3]));

  %drawnow;
  %toc
end

save frames L R ts

bumblebeeStopTransmission;
return;


if ~exist('context.txt','file'),
  bumblebeeWriteContextToFile('context.txt');
end

triclopsAPI('loadContext', ['context.txt']);
triclopsAPI('setResolution', 384, 512);
triclopsAPI('setDisparity', 0, 60);
%triclopsAPI('setDisparity', 0, 40);
triclopsAPI('setSubpixelInterpolation', 0);
triclopsAPI('setTextureValidation', 0);
triclopsAPI('setTextureValidationThreshold', 2.0);
triclopsAPI('setUniquenessValidation', 0);
triclopsAPI('setUniquenessValidationThreshold', 3.0);
triclopsAPI('setSurfaceValidation', 1);
triclopsAPI('setSurfaceValidationSize', 100);
triclopsAPI('setStereoMask', 7);


for iframe = 1:100,
  [yRaw,info] = bumblebeeCapture;
  [yLeft, yRight] = bumblebeeRawToLeftRight(yRaw);
  
  triclopsAPI('setInputLeft', yLeft);
  triclopsAPI('setInputRight', yRight);

  yrgb = triclopsAPI('imageRGB');
  xrgb = permute(yrgb,[2 1 3]);
%  xrgb = xrgb(end:-1:1,end:-1:1,:);
  
  ydisparity = triclopsAPI('imageDisparity');
  xdisparity = ydisparity';
  xdisparity = xdisparity(end:-1:1,end:-1:1);
  xdisparity(xdisparity > 250) = 0;
  xdisparity(xdisparity > 15) = 15;
 %{ 
  subplot(1,2,1);
  image(xrgb);
  axis image;
  title(sprintf('Image: %d',iframe));
  
  subplot(1,2,2);
  imagesc(xdisparity);
  colormap gray
  axis image;
  drawnow
  %}
end
