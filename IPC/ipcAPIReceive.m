function result = ipcAPIReceive(timeout_ms)

if (nargin < 1)
  timeout_ms=0; %default timeout before returning if no messages arrive
end

result = ipcAPI('receive',timeout_ms);
