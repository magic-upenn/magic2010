skip = 10;
cam = frames(:,:,:,1:skip:cntr);
ts  = ts(1:skip:cntr);

fname = 'cam13';
save(fname,'cam','ts');
