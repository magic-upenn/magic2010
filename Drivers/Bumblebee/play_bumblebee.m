nFrames = size(L,4);

hIm = image(permute(reshape(L(:,:,:,1503),[512 384 3]),[2 1 3]));

for j=1:nFrames
  set(hIm,'cdata',permute(reshape(L(:,:,:,j),[512 384 3]),[2 1 3]));
  drawnow;
  pause(0.06);
end