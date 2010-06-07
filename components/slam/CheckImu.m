function ret = CheckImu()
global IMU

ret = 0;
if isempty(IMU),return, end
if ~isfield(IMU,'data'), return, end
if ~isfield(IMU.data,'t'), return, end

%{
if (IMU.data.t - GetUnixTime() > IMU.timeout)
  ret=0;
  return;
end
%}
ret=1;
