function ret = bumblebeeWriteContextToFile(filename);

global BUMBLEBEE

if isempty(BUMBLEBEE),
  bumblebeeInit;
end

len = libdc1394('getCameraControlRegister',hex2dec('1FFC'));
disp(sprintf('Context is %d bytes long.', len));

context = char(zeros(1,len));
pData = hex2dec('2000');

disp('Reading context...');
for i = 1:4:len,
  quadlet = libdc1394('getCameraControlRegister',pData+i-1);

  % Convert to uint8
  c = memcpy(quadlet,'uint8');
  
  % Reverse bytes: 
  context(i:i+3) = c(4:-1:1);
end
context = context(1:len);

disp('Writing file...');
fid = fopen(filename,'w');
ret = fwrite(fid, context, 'char');
fclose(fid);
