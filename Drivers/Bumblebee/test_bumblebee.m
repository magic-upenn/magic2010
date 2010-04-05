bumblebeeInit;

bumblebeeStartTransmission;

tic
for i = 1:1000,
  tic
  [yRaw,info] = bumblebeeCapture;
  [yLeft, yRight] = bumblebeeRawToLeftRight(yRaw);
  
  subplot(1,2,1)
  image(permute(yLeft,[2 1 3]));
  %subplot(1,2,2)
  %image(permute(yRight,[2 1 3]));

  drawnow;
  toc
end


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
