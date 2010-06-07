function pose = spreadSendDrive(cmd, arg)

if nargin > 1,
  cmd = [cmd ' ' num2str(arg)];
end

spreadAPIMulticastReliable('DRIVE',uint8(cmd));
