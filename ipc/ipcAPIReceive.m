function result = ipcAPIReceive(timeout_ms)
global IPC

result = 0;
if isempty(IPC) || ~isfield(IPC,'connected') || ~IPC.connected
  disp('not connected to ipc');
  return;
end

if (nargin < 1)
  timeout_ms=0; %default timeout before returning if no messages arrive
end

result = ipcAPI('receive',timeout_ms);
