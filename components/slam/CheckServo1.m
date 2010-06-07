function ret = CheckServo1()
global SERVO1

ret=0;
if isempty(SERVO1), return, end
if ~isfield(SERVO1,'data'), return, end
if ~isfield(SERVO1.data,'t'), return, end

%{
if (SERVO1.data.t - GetUnixTime() > SERVO1.Timeout)
  ret=0;
  return;
end
%}

ret=1;
