%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
function result = ipcAPIReceive(timeout_ms)

if (nargin < 1)
  timeout_ms=0; %default timeout before returning if no messages arrive
end

result = ipcAPI('receive',timeout_ms);
